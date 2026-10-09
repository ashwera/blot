# Blot contributor notes

- Keep Flutter UI in `app/lib/features`, shared visual tokens in `core/theme`, transport in `data/network`, and serializable models in `data/models`.
- The server is authoritative. Never accept client scores, deadlines, player IDs, or secret words as authority.
- Keep secrets out of room snapshots and logs. Send a selected word only to the drawer.
- Canvas positions are normalized to `[0,1]`; preserve that representation on the wire.
- Use typed discriminated message unions and validate every inbound action before state mutation.
- Word packs are JSON arrays loaded by the server; keep selection independent of room transitions.

Commands: `cd server && npm run dev`, `npm run check`, `npm test`; `cd app && flutter pub get`, `flutter analyze`, `flutter test`.

Before adding a protocol message, update both client and server and cover authorization. Avoid external network dependencies in tests; use deterministic clocks/timers when adding round timer tests.
