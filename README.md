# Blot

Blot is a Flutter draw-and-guess game for private groups of 2–8 players. One person draws a secret word while friends race to guess it. The server owns game state, scores, turns, and secrets; the mobile app paints strokes locally and synchronizes normalized coordinates over WebSockets.

## Features

- Private six-character rooms with host controls and reconnect session tokens.
- English, Hindi, Hinglish, and Marathi word packs.
- Responsive normalized-coordinate drawing canvas with smooth curves, undo, and clear; the serialized stroke format stores color, width, and eraser state.
- Server-side guess checking, speed scoring, timer, and room state.
- Warm Material 3 visual theme and touch-friendly mobile layout.

## Structure

`app/` is the Flutter/Riverpod client; `server/` is a Node.js/TypeScript WebSocket service using `ws`; `words/` contains server-loaded packs. The protocol is JSON, one message per WebSocket frame. Shared room snapshots exclude the selected secret.

## Prerequisites and local setup

Install Flutter (stable, Dart 3.4+) and Node.js 22+. From the repository root:

```sh
cd server && npm install
npm run dev
```

In another terminal:

```sh
cd app
flutter pub get
flutter run
```

Android emulator defaults to `ws://10.0.2.2:3000`. The iOS simulator can use `ws://localhost:3000`. On a physical phone, edit the server URL in the home screen to `ws://<computer-LAN-IP>:3000`; both devices must be on a reachable network. For deployed TLS endpoints, use `wss://`.

Server environment variables are `PORT` (default 3000) and `ROUND_SECONDS` (default 70; use 60–80). Copy `.env.example` as a reference; the server currently reads environment variables directly and does not load `.env` itself.

## Checks

```sh
cd server && npm test && npm run check && npm run build
cd app && flutter analyze && flutter test
```

## Deployment

Build with `npm run build`, then run `npm start`. The HTTP endpoint reports health and the same port upgrades WebSocket connections. Set the host's `PORT` variable. Render, Railway, and Fly.io can run the service as a Node process; configure a persistent hostname and TLS for mobile clients. Each process currently holds rooms in memory, so use one instance until room state is moved to shared storage.

## Known limitations

The current slice includes room/lobby, drawing, guessing, server-side scoring, round rotation, and a final leaderboard. The mobile UI still needs a visible countdown, hint presentation, guess/chat history, correct-guess indicators, drawing color/brush/eraser controls, room-code copy/share, and a configurable server URL. Strokes currently send at stroke completion rather than being batched every 50 ms. Reconnect tokens are not yet persisted on-device. The server has no distributed room store; add production observability and shared state before scaling horizontally.
