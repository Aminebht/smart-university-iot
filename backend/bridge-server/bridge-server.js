const mqtt = require("mqtt");
const { createClient } = require("@supabase/supabase-js");
require("dotenv").config();

const MQTT_BROKER = process.env.MQTT_BROKER;
const MQTT_USER = process.env.MQTT_USER;
const MQTT_PASS = process.env.MQTT_PASS;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY;
const ROOM_ID = process.env.ROOM_ID || "salle1";
const OP_START = process.env.OPERATIONAL_START || "07:00";
const OP_END = process.env.OPERATIONAL_END || "22:00";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// Vérifier connexion Supabase
supabase.from('sensor_data').select('id', { count: 'exact', head: true }).then(({ error }) => {
  if (error) {
    console.error("[SUPABASE] ❌ Connection test failed:", error.message);
  } else {
    console.log("[SUPABASE] ✅ Database connection OK");
  }
});

const stats = {
  mqttConnected: false,
  messagesReceived: 0,
  messagesInserted: 0,
  commandsSent: 0,
  startTime: Date.now()
};

const recentRFIDs = new Map();
const RFID_COOLDOWN_MS = 5000;

// ===== MQTT CLIENT =====
const mqttClient = mqtt.connect(MQTT_BROKER, {
  username: MQTT_USER,
  password: MQTT_PASS,
  clientId: `bridge_${ROOM_ID}_${Date.now()}`,
  clean: true,
  connectTimeout: 4000,
  reconnectPeriod: 1000,
  keepalive: 60
});

mqttClient.on("connect", () => {
  console.log("[MQTT] ✅ Connected to broker");
  stats.mqttConnected = true;

  const topics = [
    `university/${ROOM_ID}/sensors/+`,
    `university/${ROOM_ID}/rfid/presence`,
    `university/${ROOM_ID}/status/heartbeat`
  ];

  topics.forEach(topic => {
    mqttClient.subscribe(topic, (err) => {
      if (err) console.error(`[MQTT] Subscribe error ${topic}:`, err);
      else console.log(`[MQTT] 📡 Subscribed: ${topic}`);
    });
  });
});

mqttClient.on("error", (err) => {
  console.error("[MQTT] Error:", err.message);
  stats.mqttConnected = false;
});

// ===== HANDLE INCOMING MESSAGES =====
mqttClient.on("message", async (topic, message) => {
  stats.messagesReceived++;
  const payload = message.toString();
  
  try {
    const data = JSON.parse(payload);
    const now = new Date().toISOString();

    // FR-13: Sensor telemetry
    if (topic.includes("/sensors/")) {
      const sensorType = topic.split("/").pop();
      let deviceId = "unknown";
      if (["temperature", "humidity", "light"].includes(sensorType)) {
        deviceId = "esp8266_salle1";
      } else if (["gas", "distance", "motion"].includes(sensorType)) {
        deviceId = "esp32_salle1";
      }

      const { error } = await supabase.from("sensor_data").insert({
        room_id: ROOM_ID,
        device_id: deviceId,
        sensor_type: sensorType,
        value: data.value,
        unit: data.unit,
        timestamp: data.timestamp || now,
        received_at: now
      });

      if (!error) {
        stats.messagesInserted++;
      } else {
        console.error("[DB] Sensor insert error:", error.message);
      }
    }

    // FR-14: RFID attendance
    else if (topic.includes("/rfid/presence")) {
      const { tag_id } = data;
      const lastSeen = recentRFIDs.get(tag_id);
      if (lastSeen && (Date.now() - lastSeen) < RFID_COOLDOWN_MS) {
        return;
      }
      recentRFIDs.set(tag_id, Date.now());

      const { data: cardData } = await supabase
        .from("rfid_cards")
        .select("student_id")
        .eq("rfid_uid", tag_id)
        .single();

      const { error } = await supabase.from("attendance").insert({
        room_id: ROOM_ID,
        tag_id: tag_id,
        student_id: cardData?.student_id || null,
        timestamp: data.timestamp || now,
        status: cardData ? "present" : "unknown"
      });

      if (!error) {
        stats.messagesInserted++;
        console.log(`[RFID] ✅ Attendance: ${tag_id}`);
      }
    }

    // FR-04: Heartbeat
    else if (topic.includes("/status/heartbeat")) {
      await supabase.from("device_status").upsert({
        device_id: data.device_id,
        room_id: ROOM_ID,
        last_seen: now,
        status: "online",
        ip_address: data.ip,
        rssi: data.rssi
      }, { onConflict: "device_id" });
    }

  } catch (err) {
    console.error("[MQTT] Processing error:", err.message);
  }
});

// ===== SUPABASE REALTIME → MQTT (FR-12) =====
const realtimeChannel = supabase
  .channel(`actuators_${ROOM_ID}`)
  .on("postgres_changes", {
    event: "*",
    schema: "public",
    table: "actuators",
    filter: `room_id=eq.${ROOM_ID}`
  }, (payload) => {
    const { actuator_type, command } = payload.new;
    const topic = `university/${ROOM_ID}/actuators/${actuator_type}`;
    
    mqttClient.publish(topic, JSON.stringify({
      command: command,
      timestamp: new Date().toISOString()
    }), { qos: 1 }, (err) => {
      if (!err) {
        stats.commandsSent++;
        console.log(`[CMD] ⚡️ ${topic} -> ${command}`);
      }
    });
  })
  .subscribe((status, err) => {
    if (err) {
      console.error("[SUPABASE] ❌ Realtime ERROR:", err.message || err);
    } else {
      console.log(`[SUPABASE] 👂 Realtime status: ${status}`);
    }
  });

// ===== DEVICE OFFLINE DETECTION =====
setInterval(async () => {
  const ninetySecondsAgo = new Date(Date.now() - 90000).toISOString();
  
  const { data: deadDevices } = await supabase
    .from("device_status")
    .select("*")
    .lt("last_seen", ninetySecondsAgo)
    .eq("status", "online");

  for (const device of deadDevices || []) {
    await supabase
      .from("device_status")
      .update({ status: "offline" })
      .eq("device_id", device.device_id);
    
    console.log(`🚨 ${device.device_id} OFFLINE`);
  }
}, 30000);

// ===== STATS =====
setInterval(() => {
  const uptime = Math.floor((Date.now() - stats.startTime) / 1000);
  console.log(`[STATS] ⏱️ ${uptime}s | MQTT: ${stats.mqttConnected ? "OK" : "OFF"} | Rx: ${stats.messagesReceived} | DB: ${stats.messagesInserted} | Cmd: ${stats.commandsSent}`);
}, 30000);

process.on("SIGINT", () => {
  console.log("\n[BRIDGE] Stopping...");
  mqttClient.end(true, () => process.exit(0));
});

console.log("[BRIDGE] 🚀 Starting MQTT-Supabase bridge...");