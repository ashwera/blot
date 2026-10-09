# Engineering decisions

- **Transport:** JSON messages over standard WebSockets, one complete event per frame. Server validation rejects unknown types and caps payloads at 24 KB. Client actions are authorized from the session token bound to the socket.
- **Canvas:** Points are normalized to the canvas width and height, so room histories scale across phones. Strokes retain color, width, and erase mode. Quadratic interpolation smooths paths.
- **Authority and privacy:** Room membership, host, turn order, word selection, deadlines, guess validation, and scores live on the server. A room snapshot contains a masked word only; the selected word is sent to the drawer. Clients cannot submit scores.
- **Scoring:** A correct guess yields `max(100, round(1000 * (1 - 0.75 * elapsed/duration)))`, where elapsed is server measured and capped to the round duration. The drawer earns 150 points per correct guess. One correct score per player per round.
- **Text handling:** Inputs are NFC normalized, locale-aware lowercased, punctuation/spacing normalized for fuzzy matching, and iterated by Unicode code point for edit distance and hint masking. Exact matching currently uses NFC and lowercase with trimmed whitespace; language-specific aliases can be added to packs later.
- **Reconnection:** Each player gets a cryptographically random session token. Reconnect requires that token and restores room snapshot/history. Tokens are in-memory and should be persisted securely on-device before release.
- **Rooms and deployment:** Room codes are unique six-character uppercase alphanumeric strings, capacity is eight, and empty rooms are deleted. State is process-local; run one instance until shared storage and cross-instance routing are added.
- **Reliability:** Server timers are cleared on round end, empty-room removal, and shutdown. WebSocket payload size and guess frequency are bounded.

## Current implementation boundary

This is a working foundation, not a release-complete game. The backend rotates turns and calculates a final leaderboard, but the Flutter UI still needs countdown and hint presentation, guess/chat history, correct-guess indicators, color/brush/eraser controls, room-code sharing, and a configurable server URL. Drawing currently transmits at stroke completion instead of batching every 50 ms. Reconnect tokens need secure on-device persistence before release.
