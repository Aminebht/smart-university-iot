#include <WiFi.h>
#include <PubSubClient.h>
#include <ESP32Servo.h>
#include <Wire.h>
#include <LiquidCrystal_PCF8574.h>
#include <ArduinoJson.h>
#include <SPI.h>
#include <MFRC522.h>
#include <time.h>

// Wi-Fi
const char* ssid = "";
const char* password = "";

// MQTT - IP de ton PC Windows (pas WSL!)
const char* mqtt_server = "192.168.1.101";
const int mqtt_port = 1883;
const char* mqtt_user = "esp32_salle1";
const char* mqtt_pass = "esp32_pwd_123";
const char* device_id = "esp32_salle1";
const char* room_id = "salle1";

// Topics
#define TOPIC_SENSORS_GAS      "university/salle1/sensors/gas"
#define TOPIC_SENSORS_DISTANCE "university/salle1/sensors/distance"
#define TOPIC_SENSORS_MOTION   "university/salle1/sensors/motion"
#define TOPIC_RFID_PRESENCE    "university/salle1/rfid/presence"
#define TOPIC_HEARTBEAT        "university/salle1/status/heartbeat"

// Hardware
const int mq2Pin = 34;
const int trigPin = 2;
const int echoPin = 15;
const int pirPin = 33;
const int buzzerPin = 17;
const int redPin = 14;
const int greenPin = 27;
const int bluePin = 26;
Servo doorServo;
const int servoPin = 12;
Servo motionServo;
const int servo2Pin = 25;
LiquidCrystal_PCF8574 lcd(0x27);
#define SS_PIN 5
#define RST_PIN 4
MFRC522 mfrc522(SS_PIN, RST_PIN);

// State
WiFiClient wifiClient;
PubSubClient mqttClient(wifiClient);
bool motionActive = false;
unsigned long lastMotionTime = 0;
const unsigned long motionDelay = 5000;
unsigned long lastSensorSend = 0;
const unsigned long sensorInterval = 10000;
unsigned long lastHeartbeat = 0;
const unsigned long heartbeatInterval = 60000;

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n🔧 [ESP32] Starting Smart University");

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500); Serial.print(".");
  }
  Serial.println("\n✅ WiFi connected");
  Serial.print("📶 IP: "); Serial.println(WiFi.localIP());

  mqttClient.setServer(mqtt_server, mqtt_port);
  mqttClient.setCallback(mqttCallback);
  mqttClient.setBufferSize(2048);

  pinMode(trigPin, OUTPUT); pinMode(echoPin, INPUT);
  pinMode(buzzerPin, OUTPUT);
  pinMode(redPin, OUTPUT); pinMode(greenPin, OUTPUT); pinMode(bluePin, OUTPUT);
  pinMode(mq2Pin, INPUT); pinMode(pirPin, INPUT);

  doorServo.attach(servoPin); doorServo.write(0);
  motionServo.attach(servo2Pin); motionServo.write(0);

  Wire.begin(21, 22);
  lcd.begin(16, 2); lcd.clear(); lcd.setBacklight(1);
  lcd.setCursor(0, 0); lcd.print("Smart University");

  SPI.begin();
  mfrc522.PCD_Init();

  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  struct tm timeinfo;
  int retry = 0;
  while (!getLocalTime(&timeinfo) && retry < 10) { delay(500); retry++; }

  reconnectMQTT();
  lcd.clear(); lcd.setCursor(0, 0); lcd.print("System ready");
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
    publishGas();
    publishDistance();
    publishMotion();
    lastSensorSend = now;
  }

  if (now - lastHeartbeat > heartbeatInterval) {
    publishHeartbeat();
    lastHeartbeat = now;
  }

  handleRFID();
  handleLocalMotion();
}

void reconnectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("⏳ MQTT...");
    String clientId = String(device_id) + "_" + String(random(0xffff), HEX);
    
    if (mqttClient.connect(clientId.c_str(), mqtt_user, mqtt_pass)) {
      Serial.println("✅ Connected");
      mqttClient.subscribe("university/salle1/actuators/servo");
      mqttClient.subscribe("university/salle1/actuators/buzzer");
      mqttClient.subscribe("university/salle1/actuators/led");
      mqttClient.subscribe("university/salle1/actuators/lcd");
      mqttClient.subscribe("university/salle1/alerts/intrusion");
      setRGB(false, true, false); delay(200); setRGB(false, false, false);
    } else {
      Serial.print("❌ rc="); Serial.print(mqttClient.state());
      Serial.println(" retry 5s");
      delay(5000);
    }
  }
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  unsigned long startTime = millis();
  String message = "";
  for (unsigned int i = 0; i < length; i++) message += (char)payload[i];

  StaticJsonDocument<512> doc;
  DeserializationError error = deserializeJson(doc, message);
  String command = error ? message : doc["command"] | message;

  if (String(topic).endsWith("/actuators/servo")) {
    doorServo.write((command == "open" || command == "on") ? 90 : 0);
  }
  else if (String(topic).endsWith("/actuators/buzzer")) {
    if (command == "on") playMelody(); else noTone(buzzerPin);
  }
  else if (String(topic).endsWith("/actuators/led")) {
    if (command == "red") setRGB(true, false, false);
    else if (command == "green") setRGB(false, true, false);
    else if (command == "blue") setRGB(false, false, true);
    else if (command == "yellow") setRGB(true, true, false);
    else if (command == "white") setRGB(true, true, true);
    else if (command == "alert") {
      for (int i = 0; i < 5; i++) {
        setRGB(true, false, false); delay(200);
        setRGB(false, false, false); delay(200);
      }
    }
    else setRGB(false, false, false);
  }
  else if (String(topic).endsWith("/actuators/lcd")) {
    String text = doc["message"] | "Message";
    if (command == "on") {
      lcd.setBacklight(1); lcd.clear();
      lcd.setCursor(0, 0); lcd.print(text.substring(0, 16));
      if (text.length() > 16) { lcd.setCursor(0, 1); lcd.print(text.substring(16, 32)); }
    } else {
      lcd.clear(); lcd.setBacklight(0);
    }
  }
  else if (String(topic).endsWith("/alerts/intrusion")) {
    for (int i = 0; i < 10; i++) {
      setRGB(true, false, false);
      tone(buzzerPin, 2000, 100); delay(150);
      setRGB(false, false, false); delay(150);
    }
    noTone(buzzerPin);
    lcd.clear(); lcd.setBacklight(1);
    lcd.setCursor(0, 0); lcd.print("ALERTE!");
    lcd.setCursor(0, 1); lcd.print("Intrus detecte");
  }

  unsigned long latency = millis() - startTime;
  if (latency > 200) Serial.println("⚠️ Latency > 200ms!");
}

void publishGas() {
  StaticJsonDocument<256> doc;
  doc["value"] = analogRead(mq2Pin);
  doc["timestamp"] = getISO8601Time();
  doc["device_id"] = device_id;
  doc["unit"] = "ppm";
  char buffer[256];
  serializeJson(doc, buffer);
  mqttClient.publish(TOPIC_SENSORS_GAS, buffer, true);
}

void publishDistance() {
  digitalWrite(trigPin, LOW); delayMicroseconds(2);
  digitalWrite(trigPin, HIGH); delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  long duration = pulseIn(echoPin, HIGH, 30000);
  int distance = (duration > 0) ? duration * 0.034 / 2 : -1;

  StaticJsonDocument<256> doc;
  doc["value"] = distance;
  doc["timestamp"] = getISO8601Time();
  doc["device_id"] = device_id;
  doc["unit"] = "cm";
  char buffer[256];
  serializeJson(doc, buffer);
  mqttClient.publish(TOPIC_SENSORS_DISTANCE, buffer);
}

void publishMotion() {
  StaticJsonDocument<256> doc;
  doc["value"] = (digitalRead(pirPin) == HIGH) ? 1 : 0;
  doc["timestamp"] = getISO8601Time();
  doc["device_id"] = device_id;
  doc["unit"] = "boolean";
  char buffer[256];
  serializeJson(doc, buffer);
  mqttClient.publish(TOPIC_SENSORS_MOTION, buffer);
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

void handleRFID() {
  if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) return;

  String uid = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    if (mfrc522.uid.uidByte[i] < 0x10) uid += "0";
    uid += String(mfrc522.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();

  StaticJsonDocument<512> doc;
  doc["tag_id"] = uid;
  doc["timestamp"] = getISO8601Time();
  doc["device_id"] = device_id;
  doc["room_id"] = room_id;
  char buffer[512];
  serializeJson(doc, buffer);
  mqttClient.publish(TOPIC_RFID_PRESENCE, buffer);

  doorServo.write(90); delay(3000); doorServo.write(0);
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}

void handleLocalMotion() {
  int motion = digitalRead(pirPin);
  if (motion == HIGH) {
    if (!motionActive) { motionServo.write(90); motionActive = true; }
    lastMotionTime = millis();
  }
  if (motionActive && (millis() - lastMotionTime > motionDelay)) {
    motionServo.write(0); motionActive = false;
  }
}

String getISO8601Time() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return "1970-01-01T00:00:00Z";
  char buf[30];
  strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", &timeinfo);
  return String(buf);
}

void setRGB(bool r, bool g, bool b) {
  digitalWrite(redPin, r); digitalWrite(greenPin, g); digitalWrite(bluePin, b);
}

void playMelody() {
  int melody[] = {1000, 1200, 1500, 2000};
  int durations[] = {250, 250, 500, 1000};
  for (int i = 0; i < 4; i++) {
    tone(buzzerPin, melody[i], durations[i]);
    delay(durations[i] * 1.3);
    noTone(buzzerPin);
  }
}