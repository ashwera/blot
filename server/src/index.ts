import { createServer } from "node:http";
import { WebSocketServer, WebSocket } from "ws";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { resolve, dirname } from "node:path";
import { RoomManager } from "./rooms/manager.js";
import { GameEngine } from "./game/engine.js";
import { parseMessage } from "./protocol/messages.js";
const root = resolve(dirname(fileURLToPath(import.meta.url)), "../../words");
const words = Object.fromEntries(
  ["en", "hi", "hinglish", "mr"].map((lang) => [
    lang,
    JSON.parse(readFileSync(resolve(root, `${lang}.json`), "utf8")) as string[],
  ]),
);
for (const [lang, pack] of Object.entries(words))
  if (
    !Array.isArray(pack) ||
    pack.length < 3 ||
    pack.some((word) => typeof word !== "string" || !word.trim())
  )
    throw new Error(`Invalid word pack: ${lang}`);
const duration = Number(process.env.ROUND_SECONDS ?? 70);
if (!Number.isInteger(duration) || duration < 60 || duration > 80)
  throw new Error("ROUND_SECONDS must be an integer from 60 to 80");
const manager = new RoomManager(),
  engine = new GameEngine(manager, words, duration);
const server = createServer((_req, res) => {
  res.writeHead(200, { "content-type": "application/json" });
  res.end(JSON.stringify({ name: "Blot", status: "ok" }));
});
const wss = new WebSocketServer({ server, maxPayload: 24_000 });
function send(ws: WebSocket | undefined, msg: unknown) {
  if (ws?.readyState === WebSocket.OPEN) ws.send(JSON.stringify(msg));
}
function state(room: any) {
  return {
    type: "room_state",
    room: {
      code: room.code,
      hostId: room.hostId,
      phase: room.phase,
      round: room.round,
      language: room.language,
      players: room.players.map((p: any) => ({
        id: p.id,
        name: p.name,
        score: p.score,
        connected: p.connected,
      })),
      drawerId:
        room.phase === "LOBBY" ? null : room.players[room.drawerIndex]?.id,
      maskedWord:
        room.phase === "DRAWING" && room.word
          ? room.word.replace(/[\p{L}]/gu, "_")
          : undefined,
      deadline: room.deadline,
      strokes: room.strokes,
    },
  };
}
function broadcast(room: any, msg: unknown) {
  for (const p of room.players) send(p.socket, msg);
}
engine.onRoundEnd = (room) => {
  broadcast(room, {
    type: "round_end",
    scores: room.players.map((p: any) => ({
      id: p.id,
      name: p.name,
      score: p.score,
    })),
  });
  broadcast(room, state(room));
  room.timer = setTimeout(() => {
    room.timer = undefined;
    engine.next(room);
    if (room.phase === "GAME_END") {
      broadcast(room, {
        type: "game_end",
        leaderboard: [...room.players]
          .sort((a: any, b: any) => b.score - a.score)
          .map((p: any) => ({ id: p.id, name: p.name, score: p.score })),
      });
      broadcast(room, state(room));
      return;
    }
    const drawer = room.players[room.drawerIndex];
    const choices = engine.choices(room);
    send(drawer?.socket, { type: "word_choices", choices });
    broadcast(room, state(room));
  }, 4000);
};
wss.on("connection", (ws) => {
  let actor: any;
  const counts = new Map<string, { n: number; t: number }>();
  ws.on("message", (raw) => {
    try {
      const m = parseMessage(raw.toString());
      if (m.type === "create_room") {
        const out = manager.create(m.name, m.language);
        actor = out.player;
        actor.socket = ws;
        send(ws, {
          type: "reconnect_success",
          token: actor.token,
          playerId: actor.id,
        });
        send(ws, state(out.room));
        return;
      }
      if (m.type === "join_room") {
        const out = manager.join(m.code, m.name);
        actor = out.player;
        actor.socket = ws;
        send(ws, {
          type: "reconnect_success",
          token: actor.token,
          playerId: actor.id,
        });
        broadcast(out.room, state(out.room));
        return;
      }
      if (m.type === "reconnect") {
        const out = manager.byToken(m.token);
        if (!out) throw new Error("Session expired");
        actor = out.player;
        actor.connected = true;
        actor.socket = ws;
        send(ws, {
          type: "reconnect_success",
          token: actor.token,
          playerId: actor.id,
        });
        send(ws, state(out.room));
        if (out.room.phase === "DRAWING")
          send(ws, { type: "stroke_batch", strokes: out.room.strokes });
        return;
      }
      if (!actor) throw new Error("Join a room first");
      const found = manager.byToken(actor.token);
      if (!found) throw new Error("Room session expired");
      const { room, player } = found;
      if (m.type === "leave_room") {
        manager.remove(room, player);
        broadcast(room, { type: "player_left", playerId: player.id });
        send(ws, { type: "left_room" });
        actor = undefined;
        return;
      }
      if (m.type === "start_game") {
        if (player.id !== room.hostId)
          throw new Error("Only the host can start");
        if (room.players.length < 2)
          throw new Error("At least two players are required");
        room.round = 0;
        room.drawerIndex = 0;
        const choices = engine.choices(room);
        send(player.socket, { type: "word_choices", choices });
        broadcast(room, state(room));
        return;
      }
      if (m.type === "choose_word") {
        const word = engine.choose(room, player.id, m.wordId);
        broadcast(room, {
          type: "round_start",
          drawerId: player.id,
          duration: engine.duration,
          deadline: room.deadline,
          maskedWord: word.replace(/[\p{L}]/gu, "_"),
        });
        send(player.socket, { type: "word_choices", secret: word });
        return;
      }
      if (m.type === "guess") {
        const slot = counts.get(player.id) ?? { n: 0, t: Date.now() };
        if (Date.now() - slot.t > 1000) {
          slot.n = 0;
          slot.t = Date.now();
        }
        if (++slot.n > 5) throw new Error("Slow down");
        counts.set(player.id, slot);
        const result = engine.guess(room, player.id, m.text);
        broadcast(room, {
          type: "guess_result",
          playerId: player.id,
          correct: result.correct,
          near: result.near,
          duplicate: result.duplicate,
          text: result.correct ? `${player.name} guessed it!` : m.text,
        });
        broadcast(room, state(room));
        if (room.phase === "ROUND_END")
          broadcast(room, {
            type: "round_end",
            scores: room.players.map((p: any) => ({
              id: p.id,
              score: p.score,
            })),
          });
        return;
      }
      if (m.type === "stroke_batch") {
        if (room.players[room.drawerIndex]?.id !== player.id)
          throw new Error("Only the drawer can draw");
        engine.addStrokes(room, m.strokes);
        broadcast(room, { type: "stroke_batch", strokes: m.strokes });
        return;
      }
      if (m.type === "undo" || m.type === "clear") {
        if (room.players[room.drawerIndex]?.id !== player.id)
          throw new Error("Only the drawer can edit the canvas");
        if (m.type === "clear") room.strokes = [];
        else room.strokes.pop();
        broadcast(room, { type: m.type });
        return;
      }
    } catch (e) {
      send(ws, {
        type: "error",
        message: e instanceof Error ? e.message : "Invalid request",
      });
    }
  });
  ws.on("close", () => {
    if (actor) {
      const found = manager.byToken(actor.token);
      if (found) {
        found.player.connected = false;
        found.player.socket = undefined;
        broadcast(found.room, state(found.room));
      }
    }
  });
});
const port = Number(process.env.PORT ?? 3000);
server.listen(port, "0.0.0.0", () =>
  console.log(`Blot server listening on ${port}`),
);
function shutdown() {
  for (const room of manager.rooms.values())
    if (room.timer) clearTimeout(room.timer);
  wss.close(() => server.close(() => process.exit(0)));
}
process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
