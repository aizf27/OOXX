import test, { after, before } from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { WebSocket } from "ws";
import { isDraw, winner } from "../src/game-rules.js";
import { scoreForResult } from "../src/ranking-store.js";
import { ClientError, RoomService } from "../src/room-service.js";

const testRoot = dirname(fileURLToPath(import.meta.url));
const serverRoot = join(testRoot, "..");
const repositoryRoot = join(serverRoot, "..");
const gameContract = JSON.parse(await readFile(join(repositoryRoot, "contracts", "game-rules.v1.json"), "utf8"));
const protocolContract = JSON.parse(await readFile(join(repositoryRoot, "contracts", "websocket-protocol.v1.json"), "utf8"));

function boardFrom(encoded, size) {
  return Array.from({ length: size }, (_, row) =>
    Array.from({ length: size }, (_, col) => {
      const value = encoded[row * size + col];
      return value === "." ? "" : value;
    })
  );
}

function messageById(collection, id) {
  const item = collection.find((candidate) => candidate.id === id);
  assert.ok(item, `缺少协议消息：${id}`);
  return JSON.parse(item.wire);
}

async function captureClientError(action, expectedCode) {
  let captured;
  await assert.rejects(action, (error) => {
    assert.ok(error instanceof ClientError);
    assert.equal(error.code, expectedCode);
    captured = error.code;
    return true;
  });
  return captured;
}

function createSocketClient(url) {
  const socket = new WebSocket(url);
  const queue = [];
  const waiters = [];
  socket.on("message", (raw) => {
    const message = JSON.parse(raw.toString());
    const waiter = waiters.shift();
    if (waiter) waiter.resolve(message);
    else queue.push(message);
  });

  return {
    socket,
    async open() {
      if (socket.readyState === WebSocket.OPEN) return;
      await new Promise((resolve, reject) => {
        socket.once("open", resolve);
        socket.once("error", reject);
      });
    },
    send(message) {
      socket.send(JSON.stringify(message));
    },
    next() {
      if (queue.length > 0) return Promise.resolve(queue.shift());
      return new Promise((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error("等待 WebSocket 消息超时")), 5000);
        waiters.push({
          resolve(message) {
            clearTimeout(timer);
            resolve(message);
          }
        });
      });
    },
    async close() {
      if (socket.readyState === WebSocket.CLOSED) return;
      const closed = once(socket, "close");
      socket.close();
      await closed;
    }
  };
}

let serverProcess;
let serverUrl;
let temporaryDirectory;
let serverErrorOutput = "";

before(async () => {
  temporaryDirectory = await mkdtemp(join(tmpdir(), "ooxx-contract-"));
  const rankingsFile = join(temporaryDirectory, "rankings.json");
  serverProcess = spawn(process.execPath, ["src/index.js"], {
    cwd: serverRoot,
    env: {
      ...process.env,
      HOST: "127.0.0.1",
      PORT: "0",
      RANKINGS_FILE: rankingsFile
    },
    stdio: ["ignore", "pipe", "pipe"]
  });
  serverProcess.stderr.on("data", (chunk) => {
    serverErrorOutput += chunk.toString();
  });

  serverUrl = await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`服务端启动超时：${serverErrorOutput}`)), 10000);
    serverProcess.stdout.on("data", (chunk) => {
      const match = chunk.toString().match(/ws:\/\/127\.0\.0\.1:(\d+)\/ws/);
      if (!match) return;
      clearTimeout(timer);
      resolve(`ws://127.0.0.1:${match[1]}/ws`);
    });
    serverProcess.once("exit", (code) => {
      clearTimeout(timer);
      reject(new Error(`服务端提前退出，code=${code}：${serverErrorOutput}`));
    });
  });
});

after(async () => {
  if (serverProcess && serverProcess.exitCode === null) {
    const exited = once(serverProcess, "exit");
    serverProcess.kill();
    await exited;
  }
  if (temporaryDirectory) await rm(temporaryDirectory, { recursive: true, force: true });
});

test("公共规则与积分实现符合跨端契约", () => {
  assert.equal(gameContract.version, 1);
  for (const item of gameContract.cases) {
    const board = boardFrom(item.board, item.size);
    assert.equal(winner(board, item.winLength), item.winner, item.id);
    assert.equal(isDraw(board), item.draw, item.id);
  }
  for (const [result, score] of Object.entries(gameContract.scoring)) {
    assert.equal(scoreForResult(result), score, result);
  }
});

test("房间服务覆盖契约场景和业务错误码", async () => {
  const settled = [];
  const service = new RoomService({
    async applyMatch(result) {
      settled.push(result);
    }
  });
  const observedCodes = new Set();
  const x = { id: protocolContract.scenario.players[0].playerId, name: protocolContract.scenario.players[0].name };
  const o = { id: protocolContract.scenario.players[1].playerId, name: protocolContract.scenario.players[1].name };

  observedCodes.add(await captureClientError(
    () => Promise.resolve().then(() => service.create(x, { size: 4, winLength: 3 })),
    "UNSUPPORTED_SIZE"
  ));
  observedCodes.add(await captureClientError(
    () => Promise.resolve().then(() => service.create(x, { size: 5, winLength: 3 })),
    "INVALID_WIN_LENGTH"
  ));
  observedCodes.add(await captureClientError(
    () => Promise.resolve().then(() => service.get("MISSING")),
    "ROOM_NOT_FOUND"
  ));

  const waiting = service.create({ id: "waiting-x", name: "等待玩家" });
  observedCodes.add(await captureClientError(() => service.move(waiting.code, "waiting-x", 0, 0), "GAME_NOT_READY"));
  observedCodes.add(await captureClientError(() => service.surrender(waiting.code, "waiting-x"), "INVALID_SURRENDER"));

  const room = service.create(x, {
    size: protocolContract.scenario.size,
    winLength: protocolContract.scenario.winLength
  });
  service.join(room.code, o);
  service.join(room.code, { id: "spectator", name: "观战者" });
  observedCodes.add(await captureClientError(() => service.move(room.code, "spectator", 0, 0), "SPECTATOR_READ_ONLY"));
  observedCodes.add(await captureClientError(() => service.move(room.code, o.id, 0, 0), "NOT_YOUR_TURN"));
  observedCodes.add(await captureClientError(() => service.move(room.code, x.id, -1, 0), "INVALID_MOVE"));

  const [firstMove, ...remainingMoves] = protocolContract.scenario.moves;
  await service.move(room.code, firstMove.playerId, firstMove.row, firstMove.col);
  observedCodes.add(await captureClientError(() => service.move(room.code, o.id, firstMove.row, firstMove.col), "CELL_OCCUPIED"));
  for (const move of remainingMoves) {
    await service.move(room.code, move.playerId, move.row, move.col);
  }

  assert.equal(room.status, "FINISHED");
  assert.equal(room.winner, protocolContract.scenario.winner);
  assert.equal(winner(room.board, room.winLength), protocolContract.scenario.winner);
  assert.deepEqual(settled, [
    { id: x.id, name: x.name, result: "WIN" },
    { id: o.id, name: o.name, result: "LOSS" }
  ]);

  const roomErrorCodes = protocolContract.errorCodes.filter((code) =>
    code !== "INVALID_MESSAGE" && code !== "UNKNOWN_TYPE"
  );
  assert.deepEqual([...observedCodes].sort(), [...roomErrorCodes].sort());
});

test("真实 WebSocket 端点符合协议消息与标准胜局", async () => {
  const x = createSocketClient(serverUrl);
  const o = createSocketClient(serverUrl);
  await Promise.all([x.open(), o.open()]);

  try {
    const connectedContract = messageById(protocolContract.serverMessages, "connected");
    const xConnected = await x.next();
    const oConnected = await o.next();
    assert.equal(xConnected.type, connectedContract.type);
    assert.equal(oConnected.type, connectedContract.type);
    assert.equal(xConnected.protocol, protocolContract.version);
    assert.equal(oConnected.protocol, protocolContract.version);

    const helloTemplate = messageById(protocolContract.clientMessages, "hello");
    x.send({ ...helloTemplate, playerId: "contract-x", name: "甲方" });
    assert.deepEqual(await x.next(), { type: "hello.ok", playerId: "contract-x", name: "甲方" });
    o.send({ ...helloTemplate, playerId: "contract-o", name: "乙方" });
    assert.deepEqual(await o.next(), { type: "hello.ok", playerId: "contract-o", name: "乙方" });

    x.send(messageById(protocolContract.clientMessages, "create-classic-room"));
    const created = await x.next();
    const createdContract = messageById(protocolContract.serverMessages, "room-created-waiting");
    assert.equal(created.type, createdContract.type);
    assert.deepEqual(Object.keys(created.room).sort(), Object.keys(createdContract.room).sort());
    assert.equal(created.room.status, "WAITING");
    assert.equal(created.room.yourMark, "X");
    const roomCode = created.room.code;

    const joinMessage = messageById(protocolContract.clientMessages, "join-room");
    o.send({ ...joinMessage, code: roomCode });
    const [xPlaying, oPlaying] = await Promise.all([x.next(), o.next()]);
    assert.equal(xPlaying.room.status, "PLAYING");
    assert.equal(oPlaying.room.status, "PLAYING");
    assert.equal(xPlaying.room.yourMark, "X");
    assert.equal(oPlaying.room.yourMark, "O");

    const stateMessage = messageById(protocolContract.clientMessages, "request-room-state");
    x.send({ ...stateMessage, code: roomCode });
    const requestedState = await x.next();
    assert.equal(requestedState.type, "room.state");
    assert.equal(requestedState.room.code, roomCode);

    x.send({});
    assert.equal((await x.next()).code, "INVALID_MESSAGE");
    x.send({ type: "contract.unknown" });
    assert.equal((await x.next()).code, "UNKNOWN_TYPE");

    o.send({ type: "move", row: 0, col: 0 });
    assert.deepEqual(await o.next(), messageById(protocolContract.serverMessages, "error"));

    let finalXState;
    let finalOState;
    for (const move of protocolContract.scenario.moves) {
      const client = move.playerId === "contract-x" ? x : o;
      client.send({ type: "move", row: move.row, col: move.col });
      [finalXState, finalOState] = await Promise.all([x.next(), o.next()]);
    }

    assert.equal(finalXState.room.status, "FINISHED");
    assert.equal(finalOState.room.status, "FINISHED");
    assert.equal(finalXState.room.winner, protocolContract.scenario.winner);
    assert.equal(finalOState.room.winner, protocolContract.scenario.winner);
    assert.equal(winner(finalXState.room.board, finalXState.room.winLength), protocolContract.scenario.winner);

    x.send(messageById(protocolContract.clientMessages, "create-classic-room"));
    const surrenderRoom = await x.next();
    o.send({ ...joinMessage, code: surrenderRoom.room.code });
    await Promise.all([x.next(), o.next()]);
    o.send(messageById(protocolContract.clientMessages, "surrender"));
    const [xSurrendered, oSurrendered] = await Promise.all([x.next(), o.next()]);
    assert.equal(xSurrendered.room.status, "FINISHED");
    assert.equal(oSurrendered.room.status, "FINISHED");
    assert.equal(xSurrendered.room.winner, "X");
  } finally {
    await Promise.all([x.close(), o.close()]);
  }
});
