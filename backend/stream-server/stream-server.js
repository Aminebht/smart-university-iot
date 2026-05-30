const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const { createClient } = require("@supabase/supabase-js");
require("dotenv").config();

const STREAM_PORT = process.env.STREAM_PORT || 3000;
const INGEST_PORT = process.env.INGEST_PORT || 8080;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const stats = {
  esp32Connected: false,
  viewersCount: 0,
  totalFrames: 0,
  fps: 0,
  startTime: Date.now()
};

let lastFrame = null;
let lastFrameTime = 0;
let camOnline = false;

// ===== INGEST (ESP32-CAM → Serveur) =====
const ingestWss = new WebSocket.Server({
  port: INGEST_PORT,
  path: "/esp32",
  perMessageDeflate: false,
  maxPayload: 512 * 1024
});

ingestWss.on("connection", (ws, req) => {
  const clientIp = req.socket.remoteAddress;
  console.log(`[INGEST] 📸 ESP32-CAM connected from ${clientIp}`);
  stats.esp32Connected = true;
  camOnline = true;

  ws.on("message", (data) => {
    if (!Buffer.isBuffer(data) || data.length < 2 || data[0] !== 0xFF || data[1] !== 0xD8) {
      return;
    }

    lastFrame = data;
    lastFrameTime = Date.now();
    stats.totalFrames++;
    
    const elapsed = (Date.now() - stats.startTime) / 1000;
    stats.fps = (stats.totalFrames / elapsed).toFixed(1);

    let sentCount = 0;
    viewerWss.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN && client.authenticated) {
        client.send(data, { binary: true });
        sentCount++;
      }
    });

    if (stats.totalFrames % 300 === 0) {
      console.log(`[INGEST] 📊 Frame #${stats.totalFrames} | ${data.length} bytes | ${sentCount} viewers | ${stats.fps} FPS`);
    }
  });

  ws.on("close", () => {
    console.log("[INGEST] ❌ ESP32-CAM disconnected");
    stats.esp32Connected = false;
    camOnline = false;
  });

  ws.on("error", (err) => console.error("[INGEST] Error:", err.message));
});

console.log(`[INGEST] 🚀 WebSocket ingest on ws://0.0.0.0:${INGEST_PORT}/esp32`);

// ===== VIEWER (Clients authentifiés) =====
const app = express();
const server = http.createServer(app);

app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    esp32Connected: stats.esp32Connected,
    viewersCount: stats.viewersCount,
    fps: stats.fps,
    uptime: Math.floor((Date.now() - stats.startTime) / 1000)
  });
});

app.get("/", (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head><title>Smart University - Stream Test</title></head>
    <body>
      <h1>Test Stream ESP32-CAM</h1>
      <img id="stream" style="max-width:100%;border:2px solid #333;" />
      <div id="status">Connexion...</div>
      <script>
        const ws = new WebSocket('ws://'+location.host+'/stream?token=test');
        const img = document.getElementById('stream');
        const status = document.getElementById('status');
        ws.binaryType = 'arraybuffer';
        
        ws.onopen = () => { status.textContent = 'Connecté'; };
        ws.onmessage = (e) => {
          const blob = new Blob([e.data], {type: 'image/jpeg'});
          img.src = URL.createObjectURL(blob);
        };
        ws.onclose = () => { status.textContent = 'Déconnecté'; };
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

  stats.viewersCount++;
  console.log(`[VIEWER] 🖥️ Connected | Viewers: ${stats.viewersCount}`);

  if (lastFrame) {
    ws.send(lastFrame, { binary: true });
  }

  ws.isAlive = true;
  ws.on("pong", () => { ws.isAlive = true; });

  ws.on("close", () => {
    stats.viewersCount--;
    console.log(`[VIEWER] 👋 Disconnected | Viewers: ${stats.viewersCount}`);
  });
});

const heartbeatInterval = setInterval(() => {
  viewerWss.clients.forEach((ws) => {
    if (!ws.isAlive) {
      ws.terminate();
      return;
    }
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);

// CAM status detection (pas de heartbeat MQTT pour le CAM)
setInterval(() => {
  const age = Date.now() - lastFrameTime;
  const wasOnline = camOnline;
  
  if (age > 30000) {
    camOnline = false;
  }
  
  if (wasOnline && !camOnline) {
    console.log("🚨 ESP32-CAM OFFLINE (no frame for 30s)");
  }
  if (!wasOnline && camOnline) {
    console.log("✅ ESP32-CAM ONLINE");
  }
}, 15000);

server.listen(STREAM_PORT, () => {
  console.log(`[STREAM] 🌐 HTTP + WS on http://0.0.0.0:${STREAM_PORT}`);
});