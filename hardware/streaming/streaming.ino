#include "esp_camera.h"
#include <WiFi.h>
#include <ArduinoWebsockets.h>

using namespace websockets;

const char* ssid = "";
const char* password = "";

// WebSocket vers serveur STREAM (Windows)
const char* websocket_server = "ws://192.168.1.101:8080/esp32";

#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM     0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM       5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

WebsocketsClient client;
bool connected = false;
unsigned long lastTry = 0;
const unsigned long retryInterval = 10000;
const unsigned long FRAME_INTERVAL = 100;
unsigned long lastFrameTime = 0;

void setupCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.frame_size = FRAMESIZE_VGA;
  config.pixel_format = PIXFORMAT_JPEG;
  config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 15;
  config.fb_count = 2;

  if (esp_camera_init(&config) != ESP_OK) {
    Serial.println("❌ Camera init failed");
  } else {
    Serial.println("✅ Camera initialized");
  }
}

void tryConnect() {
  Serial.print("⏳ WS connecting… ");
  if (client.connect(websocket_server)) {
    Serial.println("✅");
  } else {
    Serial.println("❌");
  }
  lastTry = millis();
}

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n🔧 [ESP32-CAM] Starting...");

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println("\n✅ WiFi connected");
  Serial.print("📶 IP: ");
  Serial.println(WiFi.localIP());

  setupCamera();

  client.onEvent([](WebsocketsClient& c, WebsocketsEvent e, String) {
    if (e == WebsocketsEvent::ConnectionOpened) {
      Serial.println("✅ WS connected");
      connected = true;
    }
    if (e == WebsocketsEvent::ConnectionClosed) {
      Serial.println("❌ WS disconnected");
      connected = false;
    }
  });

  tryConnect();
}

void loop() {
  client.poll();

  if (!connected && millis() - lastTry > retryInterval) {
    tryConnect();
  }
  if (!connected) return;

  unsigned long now = millis();
  if (now - lastFrameTime < FRAME_INTERVAL) return;
  lastFrameTime = now;

  camera_fb_t* fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("❌ Capture failed");
    return;
  }

  bool ok = client.sendBinary((const char*)fb->buf, fb->len);
  Serial.printf(ok ? "✅ Sent %u bytes\n" : "❌ Send failed\n", fb->len);

  esp_camera_fb_return(fb);
}