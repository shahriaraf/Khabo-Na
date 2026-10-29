# Khabo Na

## Structure
lib/main.dart            entry point
lib/app.dart             MaterialApp and theme
lib/core/                constants, storage and calorie math
lib/services/            notifications, AI photo service
lib/widgets/             shared dialogs
lib/features/            home, meals, progress (charts), craving
server/                  small proxy that holds your AI key
tool/app.dart            setup and optimized build helper

## First time
1. `dart run tool/app.dart setup`
2. Start the server (see below), then `flutter run --dart-define=API_BASE=http://<your-pc-ip>:8787 --dart-define=APP_TOKEN=<token>`

## Server
cd server, copy .env.example to .env values into your host, then `ANTHROPIC_API_KEY=... APP_TOKEN=... node index.js`.
Deploy to Render, Railway or Fly.io over HTTPS and set the same two variables there.

## Optimized release build
`dart run tool/app.dart build apk https://your-server.com <token>`  (small split APKs, obfuscated)
`dart run tool/app.dart build bundle https://your-server.com <token>`  (for Google Play)