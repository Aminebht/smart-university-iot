#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <Servo.h>
#include "DHT.h"
#include <ArduinoJson.h>

const char* ssid = "";
const char* password = "";

const char* mqtt_server = "192.168.1.101";
const int mqtt_port = 1883;
const char* mqtt_user = "esp8266_salle1";
const char* mqtt_pass = "esp8266_pwd_123";
const char* device_id = "esp8266_salle1";
const char* room_id = "salle1";

#define TOPIC_TEMP      "university/salle1/sensors/temperature"
#define TOPIC_HUMIDITY  "university/salle1/sensors/humidity"
#define TOPIC_LIGHT     "university/salle1/sensors/light"
#define TOPIC_HEARTBEAT "university/salle1/status/heartbeat"

#define DHTPIN D1
#define DHTTYPE DHT11
#define RELAY_PIN D2
#define LED_PIN D3
#define SERVO_PIN D4
#define LDR_PIN A0

DHT dht(DHTPIN, DHTTYPE);
Servo windowServo;
WiFiClient wifiClient;
PubSubClient mqttClient(wifiClient);

unsigned long lastSensorSend = 0;
const unsigned long sensorInterval = 10000;
unsigned long lastHeartbeat = 0;
const unsigned long heartbeatInterval = 60000;

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n🔧 [ESP8266] Starting");

  dht.begin();
  pinMode(RELAY_PIN, OUTPUT); pinMode(LED_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); digitalWrite(LED_PIN, LOW);
  windowServo.attach(SERVO_PIN); windowServo.write(0);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
  Serial.println("\n✅ WiFi connected");

  mqttClient.setServer(mqtt_server, mqtt_port);
  mqttClient.setCallback(mqttCallback);
  mqttClient.setBufferSize(1024);

  configTime(0, 0, "pool.ntp.org");
  delay(2000);

  reconnectMQTT();
}

void loop() {
  if (!mqttClient.connected()) reconnectMQTT();
  mqttClient.loop();

  if (WiFi.status() != WL_CONNECTED) {
    WiFi.begin(ssid, password);
    delay(2000);
    return;
  }

  unsigned long now = millis();

  if (now - lastSensorSend > sensorInterval) {
    publishSensors();
    lastSensorSend = now;
  }

  if (now - lastHeartbeat > heartbeatInterval) {
    publishHeartbeat();
    lastHeartbeat = now;
  }
}

void reconnectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("⏳ MQTT...");
    String clientId = String(device_id) + "_" + String(random(0xffff), HEX);
    if (mqttClient.connect(clientId.c_str(), mqtt_user, mqtt_pass)) {
      Serial.println("✅ Connected");
      mqttClient.subscribe("university/salle1/actuators/fan");
      mqttClient.subscribe("university/salle1/actuators/led");
      mqttClient.subscribe("university/salle1/actuators/window");
    } else {
      Serial.print("❌ rc="); Serial.print(mqttClient.state());
      Serial.println(" retry 5s");
      delay(5000);
    }
  }
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (unsigned int i = 0; i < length; i++) message += (char)payload[i];

  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, message);
  String command = error ? message : doc["command"] | message;

  if (String(topic).endsWith("/actuators/fan")) {
    digitalWrite(RELAY_PIN, (command == "on") ? HIGH : LOW);
  }
  else if (String(topic).endsWith("/actuators/led")) {
    digitalWrite(LED_PIN, (command == "on") ? HIGH : LOW);
  }
  else if (String(topic).endsWith("/actuators/window")) {
    windowServo.write((command == "open" || command == "on") ? 90 : 0);
  }
}

void publishSensors() {
  float temp = dht.readTemperature();
  if (!isnan(temp)) {
    StaticJsonDocument<256> doc;
    doc["value"] = temp;
    doc["timestamp"] = getISO8601Time();
    doc["device_id"] = device_id;
    doc["unit"] = "°C";
    char buffer[256];
    serializeJson(doc, buffer);
    mqttClient.publish(TOPIC_TEMP, buffer);
  }

  float hum = dht.readHumidity();
  if (!isnan(hum)) {
    StaticJsonDocument<256> doc;
    doc["value"] = hum;
    doc["timestamp"] = getISO8601Time();
    doc["device_id"] = device_id;
    doc["unit"] = "%";
    char buffer[256];
    serializeJson(doc, buffer);
    mqttClient.publish(TOPIC_HUMIDITY, buffer);
  }

  int light = analogRead(LDR_PIN);
  StaticJsonDocument<256> doc;
  doc["value"] = light;
  doc["timestamp"] = getISO8601Time();
  doc["device_id"] = device_id;
  doc["unit"] = "raw";
  char buffer[256];
  serializeJson(doc, buffer);
  mqttClient.publish(TOPIC_LIGHT, buffer);
}

void publishHeartbeat() {
  StaticJsonDocument<512> doc;
  doc["device_id"] = device_id;
  doc["room_id"] = room_id;
  doc["status"] = "online";
  doc["timestamp"] = getISO8601Time();
  doc["ip"] = WiFi.localIP().toString();
  doc["rssi"] = WiFi.RSSI();
  doc["uptime_ms"] = millis();
  char buffer[512];
  serializeJson(doc, buffer);
  mqttClient.publish(TOPIC_HEARTBEAT, buffer);
}

String getISO8601Time() {
  time_t now = time(nullptr);
  struct tm* timeinfo = gmtime(&now);
  char buf[30];
  strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", timeinfo);
  return String(buf);
}