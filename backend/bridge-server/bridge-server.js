const mqtt = require("mqtt");
const { createClient } = require("@supabase/supabase-js");
require("dotenv").config();

const MQTT_BROKER = process.env.MQTT_BROKER;
const MQTT_USER = process.env.MQTT_USER;
const MQTT_PASS = process.env.MQTT_PASS;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY;
const OP_START = process.env.OPERATIONAL_START || "07:00";
const OP_END = process.env.OPERATIONAL_END || "22:00";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// In-memory threshold cache (refreshed every 60s)
let thresholds = {};

async function loadThresholds() {
  const { data, error } = await supabase.from("thresholds").select("*");
  if (error) {
    console.error("[THRESH] Failed to load thresholds:", error.message);
    return;
  }
  thresholds = {};
  for (const row of data) {
    thresholds[row.sensor_type] = { max: row.max_value, min: row.min_value, unit: row.unit };
  }
  console.log("[THRESH] Loaded thresholds:", Object.keys(thresholds));
}

// Verify Supabase connection
supabase.from("sensor_data").select("id", { count: "exact", head: true }).then(({ error }) => {
  if (error) {
    console.error("[SUPABASE] ❌ Connection test failed:", error.message);
  } else {
    console.log("[SUPABASE] ✅ Database connection OK");
    loadThresholds();
  }
});

const stats = {
  mqttConnected: false,
  messagesReceived: 0,
  messagesInserted: 0,
  commandsSent: 0,
  alertsInserted: 0,
  startTime: Date.now()
};

const recentRFIDs = new Map();
const RFID_COOLDOWN_MS = 5000;

// ===== HELPER: extract room_id from MQTT topic =====
function extractRoomId(topic) {
  // topics: university/<room_id>/sensors/<type>
  const parts = topic.split("/");
  return parts[1] || "unknown";
}

// ===== HELPER: check thresholds and insert alert =====
async function checkThresholdAlert(roomId, sensorType, value, unit, timestamp) {
  const cfg = thresholds[sensorType];
  if (!cfg) return;
  const numValue = Number(value);
  if (Number.isNaN(numValue)) return;

  let breached = false;
  let severity = "medium";
  let message = "";

  if (cfg.max != null && numValue > cfg.max) {
    breached = true;
    severity = numValue > cfg.max * 1.5 ? "critical" : "high";
    message = `${sensorType} exceeded max threshold (${numValue}${unit || ""} > ${cfg.max}${cfg.unit || ""}) in ${roomId}`;
  } else if (cfg.min != null && numValue < cfg.min) {
    breached = true;
    severity = "high";
    message = `${sensorType} below min threshold (${numValue}${unit || ""} < ${cfg.min}${cfg.unit || ""}) in ${roomId}`;
  }

  if (!breached) return;

  const { error } = await supabase.from("alerts").insert({
    room_id: roomId,
    alert_type: `threshold_${sensorType}`,
    severity: severity,
    message: message,
    timestamp: timestamp || new Date().toISOString(),
    acknowledged: false
  });

  if (!error) {
    stats.alertsInserted++;
    console.log(`[ALERT] 🔥 Threshold alert: ${message}`);
  } else {
    console.error("[ALERT] Insert error:", error.message);
  }
}

// ===== MQTT CLIENT =====
const mqttClient = mqtt.connect(MQTT_BROKER, {
  username: MQTT_USER,
  password: MQTT_PASS,
  clientId: `bridge_multiroom_${Date.now()}`,
  clean: true,
  connectTimeout: 4000,
  reconnectPeriod: 1000,
  keepalive: 60
});

mqttClient.on("connect", () => {
  console.log("[MQTT] ✅ Connected to broker (multi-room mode)");
  stats.mqttConnected = true;

  const topics = [
    "university/+/sensors/+",
    "university/+/rfid/presence",
    "university/+/status/heartbeat"
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
  const roomId = extractRoomId(topic);

  try {
    const data = JSON.parse(payload);
    const now = new Date().toISOString();

    // FR-13: Sensor telemetry
    if (topic.includes("/sensors/")) {
      const sensorType = topic.split("/").pop();
      let deviceId = data.device_id || "unknown";
      if (deviceId === "unknown") {
        if (["temperature", "humidity", "light"].includes(sensorType)) {
          deviceId = `esp8266_${roomId}`;
        } else if (["gas", "distance", "motion"].includes(sensorType)) {
          deviceId = `esp32_${roomId}`;
        }
      }

      const { error } = await supabase.from("sensor_data").insert({
        room_id: roomId,
        device_id: deviceId,
        sensor_type: sensorType,
        value: data.value,
        unit: data.unit,
        timestamp: data.timestamp || now,
        received_at: now
      });

      if (!error) {
        stats.messagesInserted++;
        // Check thresholds after successful insert
        await checkThresholdAlert(roomId, sensorType, data.value, data.unit, data.timestamp || now);
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

      // Silently drop unknown scans to respect attendance_tag_id_fkey
      if (!cardData) {
        console.log(`[RFID] ⚠️ Unknown card ${tag_id} in ${roomId} — skipped`);
        return;
      }

      const { error } = await supabase.from("attendance").insert({
        room_id: roomId,
        tag_id: tag_id,
        student_id: cardData.student_id || null,
        timestamp: data.timestamp || now,
        status: "present"
      });

      if (!error) {
        stats.messagesInserted++;
        console.log(`[RFID] ✅ Attendance: ${tag_id} in ${roomId}`);
      }
    }

    // FR-04: Heartbeat — UPDATE only (rows pre-provisioned in schema)
    else if (topic.includes("/status/heartbeat")) {
      await supabase.from("device_status").update({
        room_id: roomId,
        last_seen: now,
        status: "online",
        ip_address: data.ip,
        rssi: data.rssi,
        uptime_ms: data.uptime_ms,
        updated_at: now
      }).eq("device_id", data.device_id);
    }

  } catch (err) {
    console.error("[MQTT] Processing error:", err.message);
  }
});

// ===== SUPABASE REALTIME → MQTT (FR-12) =====
// Listen to ALL actuator changes across all rooms
const realtimeChannel = supabase
  .channel("actuators_all_rooms")
  .on("postgres_changes", {
    event: "*",
    schema: "public",
    table: "actuators"
  }, (payload) => {
    const { room_id, actuator_type, command } = payload.new;
    if (!room_id || !actuator_type) return;

    const topic = `university/${room_id}/actuators/${actuator_type}`;
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

// ===== REFRESH THRESHOLDS =====
setInterval(() => {
  loadThresholds();
}, 60000);

// ===== STATS =====
setInterval(() => {
  const uptime = Math.floor((Date.now() - stats.startTime) / 1000);
  console.log(`[STATS] ⏱️ ${uptime}s | MQTT: ${stats.mqttConnected ? "OK" : "OFF"} | Rx: ${stats.messagesReceived} | DB: ${stats.messagesInserted} | Cmd: ${stats.commandsSent} | Alerts: ${stats.alertsInserted}`);
}, 30000);

process.on("SIGINT", () => {
  console.log("\n[BRIDGE] Stopping...");
  mqttClient.end(true, () => process.exit(0));
});

console.log("[BRIDGE] 🚀 Starting MQTT-Supabase bridge (multi-room)...");