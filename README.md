# Smart University IoT — Unified Codebase

This repository combines two IoT projects into a single, functionally-organized codebase for a smart university/school monitoring system.

## Origin

- **smart_school** (mobile app): Flutter application for monitoring and controlling smart school environments. Originally from `Aminebht/smart_school` (private).
- **Smart_University_Prototype** (backend + hardware): Node.js bridge/stream servers and ESP32/Arduino firmware for real-time university facility monitoring. Originally from `azizguidara03-cpu/Smart_University_Prototype` (public).

## Folder Structure

```
smart-university-iot/
├── mobile/
│   └── smart_school_app/          # Flutter mobile application
│       ├── android/
│       ├── ios/
│       ├── lib/                   # Dart source code (features, services, models)
│       ├── web/
│       ├── windows/
│       ├── macos/
│       ├── linux/
│       ├── assets/
│       └── pubspec.yaml
├── backend/
│   ├── bridge-server/             # Node.js bridge server
│   │   ├── bridge-server.js
│   │   ├── package.json
│   │   └── package-lock.json
│   └── stream-server/             # Node.js stream server
│       ├── stream-server.js
│       ├── package.json
│       └── package-lock.json
├── hardware/
│   ├── SMART_FST_1/
│   │   └── SMART_FST_1.ino      # ESP32/Arduino firmware variant 1
│   ├── SMART_FST_2/
│   │   └── SMART_FST_2.ino      # ESP32/Arduino firmware variant 2
│   └── streaming/
│       └── streaming.ino        # ESP32/Arduino streaming firmware
├── docs/
│   ├── smart_school_README.md
│   └── cahier_des_charges_smart_university.pdf
└── README.md
```

## Quick Start

### Mobile App
```bash
cd mobile/smart_school_app
flutter pub get
flutter run
```

### Backend Servers
```bash
cd backend/bridge-server
npm install
node bridge-server.js

cd backend/stream-server
npm install
node stream-server.js
```

### Hardware Firmware
Open each `.ino` file in the Arduino IDE (folder name must match sketch name). Upload to your ESP32/Arduino board after selecting the correct board and port.

## Technology Stack

| Layer       | Technology                                    |
|-------------|-----------------------------------------------|
| Mobile      | Flutter, Dart, Provider, Supabase             |
| Backend     | Node.js, WebSocket, HTTP                      |
| Hardware    | ESP32 / Arduino, C++                          |
| Cloud/DB    | Supabase, Firebase (varies by origin repo)    |

## Notes

- `node_modules` directories are excluded; run `npm install` in each backend folder.
- The mobile app uses **Supabase** (`supabase_flutter`) for its backend services.
- The hardware sketches may require additional libraries depending on the sensors used.
- Original Git histories were not preserved; this is a clean snapshot merge.
