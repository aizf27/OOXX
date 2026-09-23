import { createServer } from "node:http";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { WebSocketServer, WebSocket } from "ws";
import { dailyPuzzle } from "./puzzles.js";
import { RankingStore } from "./ranking-store.js";
import { ClientError, RoomService } from "./room-service.js";

const port = Number(process.env.PORT ?? 9527);
const hostname = process.env.HOST ?? "0.0.0.0";
const root = dirname(fileURLToPath(import.meta.url));
const rankings = new RankingStore(join(root, "..", "data", "rankings.json"));
await rankings.load();
const rooms = new RoomService(rankings);

const server = createServer(async (request, response) => {
  cors(response);
  if (request.method === "OPTIONS") return response.writeHead(204).end();
  const url = new URL(request.url ?? "/", `http://${request.headers.host}`);
  try {
    if (request.method === "GET" && url.pathname === "/health") return json(response, 200, { ok: true, rooms: rooms.rooms.size });
    if (request.method === "GET" && url.pathname === "/games/daily") return json(response, 200, dailyPuzzle);
    if (request.method === "GET" && url.pathname === "/rankings") return json(response, 200, { entries: rankings.list(url.searchParams.get("limit")) });
    if (request.method === "POST" && url.pathname === "/rankings") {
      const body = await readJson(request);
      if (!body.playerId || !["WIN", "LOSS", "DRAW"].includes(body.result)) return json(response, 400, { error: "INVALID_REQUEST" });
      return json(response, 201, await rankings.applyMatch({ id: String(body.playerId).slice(0, 64), name: body.name, result: body.result }));
    }
    return json(response, 404, { error: "NOT_FOUND" });
  } catch (error) { console.error("HTTP error", error); return json(response, 500, { error: "INTERNAL_ERROR" }); }
});

const wss = new WebSocketServer({ server, path: "/ws", maxPayload: 8 * 1024 });
wss.on("connection", (socket) => {
  const client = { id: `guest-${crypto.randomUUID()}`, name: "匿名玩家", roomCode: null };
  send(socket, { type: "connected", playerId: client.id, protocol: 1 });
  socket.on("message", async (raw) => {
    try { await handleMessage(socket, client, JSON.parse(raw.toString())); }
    catch (error) { send(socket, { type: "error", code: error instanceof ClientError ? error.code : "INVALID_MESSAGE", message: error.message || "消息格式错误" }); }
  });
  socket.on("close", () => {
    if (!client.roomCode) return;
    const room = rooms.leave(client.roomCode, client.id);
    if (room) broadcastState(room);
  });
});

async function handleMessage(socket, client, message) {
  if (!message || typeof message.type !== "string") throw new ClientError("INVALID_MESSAGE", "缺少 type 字段");
  if (message.type === "hello") {
    client.id = String(message.playerId || client.id).slice(0, 64);
    client.name = String(message.name || "匿名玩家").replace(/[\r\n]/g, "").trim().slice(0, 20) || "匿名玩家";
    return send(socket, { type: "hello.ok", playerId: client.id, name: client.name });
  }
  if (message.type === "room.create") {
    const room = rooms.create(client, message); room.connections.set(client.id, socket); client.roomCode = room.code;
    return send(socket, { type: "room.created", room: rooms.snapshot(room, client.id) });
  }
  if (message.type === "room.join") {
    const room = rooms.join(message.code, client); room.connections.set(client.id, socket); client.roomCode = room.code;
    return broadcastState(room);
  }
  if (message.type === "room.state") {
    const room = rooms.get(client.roomCode ?? message.code);
    return send(socket, { type: "room.state", room: rooms.snapshot(room, client.id) });
  }
  if (message.type === "move") return broadcastState(await rooms.move(client.roomCode, client.id, message.row, message.col));
  if (message.type === "game.surrender") return broadcastState(await rooms.surrender(client.roomCode, client.id));
  throw new ClientError("UNKNOWN_TYPE", `未知消息：${message.type}`);
}

function broadcastState(room) {
  for (const [playerId, socket] of room.connections) if (socket.readyState === WebSocket.OPEN) send(socket, { type: "room.state", room: rooms.snapshot(room, playerId) });
}
function send(socket, message) { if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(message)); }
function json(response, status, payload) { response.writeHead(status, { "Content-Type": "application/json; charset=utf-8" }); response.end(JSON.stringify(payload)); }
function cors(response) { response.setHeader("Access-Control-Allow-Origin", "*"); response.setHeader("Access-Control-Allow-Headers", "Content-Type"); }
function readJson(request) {
  return new Promise((resolve, reject) => {
    let data = "";
    request.on("data", (chunk) => { data += chunk; if (data.length > 16 * 1024) reject(new Error("请求过大")); });
    request.on("end", () => { try { resolve(JSON.parse(data || "{}")); } catch { reject(new Error("JSON 格式错误")); } });
    request.on("error", reject);
  });
}
server.listen(port, hostname, () => console.log(`OOXX server: http://${hostname}:${port} | ws://${hostname}:${port}/ws`));
