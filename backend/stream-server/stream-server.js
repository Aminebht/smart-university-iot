const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const { createClient } = require("@supabase/supabase-js");
require("dotenv").config();

const STREAM_PORT = process.env.STREAM_PORT || 3000;
const INGEST_PORT = process.env.INGEST_PORT || 8080;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// Per-room frame store: roomId -> { lastFrame, lastFrameTime, camWs, online }
const rooms = new Map();

function getRoom(roomId) {
  if (!rooms.has(roomId)) {
    rooms.set(roomId, {
      roomId,
      lastFrame: null,
      lastFrameTime: 0,
      camWs: null,
      online: false,
      totalFrames: 0,
      viewers: 0,
      startTime: Date.now()
    });
  }
  return rooms.get(roomId);
}

function setRoomOnline(roomId, online) {
  const room = getRoom(roomId);
  const wasOnline = room.online;
  room.online = online;

  if (wasOnline && !online) {
    console.log(`🚨 [${roomId}] CAM OFFLINE (no frame for 30s)`);
    updateDeviceStatus(roomId, 'offline');
  }
  if (!wasOnline && online) {
    console.log(`✅ [${roomId}] CAM ONLINE`);
    updateDeviceStatus(roomId, 'online');
  }
}

async function updateDeviceStatus(roomId, status) {
  try {
    await supabase.from('device_status').update({
      room_id: roomId,
      status,
      last_seen: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }).eq('device_id', `cam_${roomId}`);
  } catch (e) {
    // silently ignore Supabase errors
  }
}

// ===== INGEST (ESP32-CAM → Server) =====
const ingestWss = new WebSocket.Server({
  port: INGEST_PORT,
  path: "/esp32",
  perMessageDeflate: false,
  maxPayload: 512 * 1024
});

ingestWss.on("connection", (ws, req) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const roomId = url.searchParams.get("room_id") || 'salle1';
  const clientIp = req.socket.remoteAddress;

  console.log(`[INGEST] 📸 [${roomId}] ESP32-CAM connected from ${clientIp}`);

  const room = getRoom(roomId);
  room.camWs = ws;
  setRoomOnline(roomId, true);

  ws.on("message", (data) => {
    if (!Buffer.isBuffer(data) || data.length < 2 || data[0] !== 0xFF || data[1] !== 0xD8) {
      return;
    }

    room.lastFrame = data;
    room.lastFrameTime = Date.now();
    room.totalFrames++;

    const elapsed = (Date.now() - room.startTime) / 1000;
    const fps = (room.totalFrames / elapsed).toFixed(1);

    // Broadcast to authenticated viewers for this room
    let sentCount = 0;
    viewerWss.clients.forEach((client) => {
      if (
        client.readyState === WebSocket.OPEN &&
        client.authenticated &&
        client.roomId === roomId
      ) {
        client.send(data, { binary: true });
        sentCount++;
      }
    });

    if (room.totalFrames % 300 === 0) {
      console.log(`[INGEST] [${roomId}] Frame #${room.totalFrames} | ${data.length} bytes | ${sentCount} viewers | ${fps} FPS`);
    }
  });

  ws.on("close", () => {
    console.log(`[INGEST] ❌ [${roomId}] ESP32-CAM disconnected`);
    room.camWs = null;
    setRoomOnline(roomId, false);
  });

  ws.on("error", (err) => console.error(`[INGEST] [${roomId}] Error:`, err.message));
});

console.log(`[INGEST] 🚀 WebSocket ingest on ws://0.0.0.0:${INGEST_PORT}/esp32?room_id=<room_id>`);

// ===== VIEWER (Authenticated clients) =====
const app = express();
const server = http.createServer(app);

app.get("/health", (req, res) => {
  const roomStats = {};
  rooms.forEach((r, id) => {
    roomStats[id] = {
      online: r.online,
      viewers: r.viewers,
      totalFrames: r.totalFrames
    };
  });
  res.json({ status: "ok", rooms: roomStats, uptime: Math.floor((Date.now() - Date.now()) / 1000) });
});

app.get("/", (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head><title>Smart University - Stream Test</title></head>
    <body>
      <h1>Test Stream ESP32-CAM</h1>
      <label>Room ID: <input id="roomId" value="salle1" /></label>
      <button onclick="connect()">Connect</button>
      <img id="stream" style="max-width:100%;border:2px solid #333;" />
      <div id="status">Waiting...</div>
      <script>
        let ws;
        function connect() {
          const roomId = document.getElementById('roomId').value;
          ws = new WebSocket('ws://'+location.host+'/stream?token=test&room_id='+roomId);
          const img = document.getElementById('stream');
          const status = document.getElementById('status');
          ws.binaryType = 'arraybuffer';
          ws.onopen = () => { status.textContent = 'Connected to '+roomId; };
          ws.onmessage = (e) => {
            const blob = new Blob([e.data], {type: 'image/jpeg'});
            img.src = URL.createObjectURL(blob);
          };
          ws.onclose = () => { status.textContent = 'Disconnected'; };
        }
      </script>
    </body>
    </html>
  `);
});

const viewerWss = new WebSocket.Server({
  server,
  path: "/stream",
  perMessageDeflate: false
});

viewerWss.on("connection", async (ws, req) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const token = url.searchParams.get("token");
  const roomId = url.searchParams.get("room_id") || 'salle1';

  if (!token) {
    ws.close(1008, "Missing token");
    return;
  }

  if (token === "test") {
    ws.authenticated = true;
  } else {
    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) {
      ws.close(1008, "Invalid token");
      return;
    }
    ws.userId = user.id;
    ws.authenticated = true;
  }

  ws.roomId = roomId;
  const room = getRoom(roomId);
  room.viewers++;
  console.log(`[VIEWER] 🖥️ [${roomId}] Connected | Viewers: ${room.viewers}`);

  // Send last frame immediately if available
  if (room.lastFrame) {
    ws.send(room.lastFrame, { binary: true });
  }

  ws.isAlive = true;
  ws.on("pong", () => { ws.isAlive = true; });

  ws.on("close", () => {
    room.viewers--;
    console.log(`[VIEWER] 👋 [${roomId}] Disconnected | Viewers: ${room.viewers}`);
  });
});

// Heartbeat for viewers
setInterval(() => {
  viewerWss.clients.forEach((ws) => {
    if (!ws.isAlive) {
      ws.terminate();
      return;
    }
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);

// Camera offline detection per room
setInterval(() => {
  rooms.forEach((room, roomId) => {
    const age = Date.now() - room.lastFrameTime;
    if (room.online && age > 30000) {
      setRoomOnline(roomId, false);
    }
  });
}, 15000);

server.listen(STREAM_PORT, () => {
  console.log(`[STREAM] 🌐 HTTP + WS on http://0.0.0.0:${STREAM_PORT}`);
});