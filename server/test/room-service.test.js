import test from "node:test";
import assert from "node:assert/strict";
import { ClientError, RoomService } from "../src/room-service.js";

function player(id, name = id) {
  return { id, name };
}

function createHarness() {
  const settlements = [];
  const service = new RoomService({
    async applyMatch(result) {
      settlements.push(result);
    }
  });
  return { service, settlements };
}

function stateOf(room) {
  return JSON.parse(JSON.stringify({
    size: room.size,
    winLength: room.winLength,
    board: room.board,
    turn: room.turn,
    status: room.status,
    winner: room.winner,
    players: room.players,
    spectators: room.spectators
  }));
}

async function assertClientError(action, code) {
  await assert.rejects(action, (error) => {
    assert.ok(error instanceof ClientError);
    assert.equal(error.code, code);
    return true;
  });
}

test("创建、加入和观战遵循 WAITING 到 PLAYING 状态迁移", () => {
  const { service } = createHarness();
  const room = service.create(player("x", "甲方"), { size: 5, winLength: 4 });

  assert.match(room.code, /^\d{6}$/);
  assert.equal(room.status, "WAITING");
  assert.equal(room.turn, "X");
  assert.equal(room.winner, null);
  assert.deepEqual(room.players, [{ id: "x", name: "甲方", mark: "X" }]);
  assert.equal(room.board.length, 5);
  assert.ok(room.board.every((row) => row.every((cell) => cell === "")));

  assert.equal(service.join(room.code, player("x", "重复连接")), room);
  assert.equal(room.players.length, 1);

  service.join(room.code, player("o", "乙方"));
  assert.equal(room.status, "PLAYING");
  assert.deepEqual(room.players.map(({ id, mark }) => ({ id, mark })), [
    { id: "x", mark: "X" },
    { id: "o", mark: "O" }
  ]);

  service.join(room.code, player("viewer", "观战者"));
  service.join(room.code, player("viewer", "重复观战"));
  assert.deepEqual(room.spectators, [{ id: "viewer", name: "观战者" }]);
  assert.equal(room.status, "PLAYING");
});

test("非法落子不会修改服务端权威状态", async () => {
  const { service, settlements } = createHarness();
  const room = service.create(player("x"));
  service.join(room.code, player("o"));
  service.join(room.code, player("viewer"));

  let before = stateOf(room);
  await assertClientError(() => service.move(room.code, "o", 0, 0), "NOT_YOUR_TURN");
  assert.deepEqual(stateOf(room), before);

  await assertClientError(() => service.move(room.code, "viewer", 0, 0), "SPECTATOR_READ_ONLY");
  assert.deepEqual(stateOf(room), before);

  await assertClientError(() => service.move(room.code, "x", -1, 0), "INVALID_MOVE");
  assert.deepEqual(stateOf(room), before);

  await service.move(room.code, "x", 0, 0);
  assert.equal(room.board[0][0], "X");
  assert.equal(room.turn, "O");

  before = stateOf(room);
  await assertClientError(() => service.move(room.code, "o", 0, 0), "CELL_OCCUPIED");
  assert.deepEqual(stateOf(room), before);
  assert.deepEqual(settlements, []);
});

test("胜局只结算一次并锁定 FINISHED 状态", async () => {
  const { service, settlements } = createHarness();
  const room = service.create(player("x", "甲方"));
  service.join(room.code, player("o", "乙方"));
  const moves = [
    ["x", 0, 0], ["o", 0, 1],
    ["x", 1, 0], ["o", 1, 1],
    ["x", 2, 0]
  ];

  for (let index = 0; index < moves.length; index += 1) {
    const [id, row, col] = moves[index];
    await service.move(room.code, id, row, col);
    if (index < moves.length - 1) {
      assert.equal(room.status, "PLAYING");
      assert.equal(room.winner, null);
    }
  }

  assert.equal(room.status, "FINISHED");
  assert.equal(room.winner, "X");
  assert.deepEqual(settlements, [
    { id: "x", name: "甲方", result: "WIN" },
    { id: "o", name: "乙方", result: "LOSS" }
  ]);

  const finished = stateOf(room);
  await assertClientError(() => service.move(room.code, "o", 2, 2), "GAME_NOT_READY");
  await assertClientError(() => service.surrender(room.code, "o"), "INVALID_SURRENDER");
  assert.deepEqual(stateOf(room), finished);
  assert.equal(settlements.length, 2);
});

test("满盘无胜者迁移到 DRAW 并为双方结算", async () => {
  const { service, settlements } = createHarness();
  const room = service.create(player("x", "甲方"));
  service.join(room.code, player("o", "乙方"));
  const moves = [
    ["x", 0, 0], ["o", 0, 1], ["x", 0, 2],
    ["o", 1, 1], ["x", 1, 0], ["o", 1, 2],
    ["x", 2, 1], ["o", 2, 0], ["x", 2, 2]
  ];

  for (const [id, row, col] of moves) await service.move(room.code, id, row, col);

  assert.equal(room.status, "FINISHED");
  assert.equal(room.winner, "DRAW");
  assert.deepEqual(settlements, [
    { id: "x", name: "甲方", result: "DRAW" },
    { id: "o", name: "乙方", result: "DRAW" }
  ]);
});

test("认输由服务端确定胜者并锁定房间", async () => {
  const { service, settlements } = createHarness();
  const room = service.create(player("x", "甲方"));
  service.join(room.code, player("o", "乙方"));

  await service.surrender(room.code, "o");

  assert.equal(room.status, "FINISHED");
  assert.equal(room.winner, "X");
  assert.ok(room.board.every((row) => row.every((cell) => cell === "")));
  assert.deepEqual(settlements, [
    { id: "x", name: "甲方", result: "WIN" },
    { id: "o", name: "乙方", result: "LOSS" }
  ]);
});

test("观战者或未知连接离开不会中断正在进行的对局", async () => {
  const { service } = createHarness();
  const room = service.create(player("x"));
  service.join(room.code, player("o"));
  service.join(room.code, player("viewer"));
  await service.move(room.code, "x", 1, 1);
  const playing = stateOf(room);

  assert.equal(service.leave(room.code, "unknown"), room);
  assert.deepEqual(stateOf(room), playing);

  assert.equal(service.leave(room.code, "viewer"), room);
  assert.equal(room.status, "PLAYING");
  assert.equal(room.turn, "O");
  assert.equal(room.board[1][1], "X");
  assert.equal(room.players.length, 2);
  assert.deepEqual(room.spectators, []);
});

test("对局玩家离开后清空棋局并重新建立合法先后手", async () => {
  for (const leavingId of ["x", "o"]) {
    const { service, settlements } = createHarness();
    const room = service.create(player("x", "甲方"));
    service.join(room.code, player("o", "乙方"));
    service.join(room.code, player("viewer", "候补玩家"));
    room.connections.set("x", { id: "socket-x" });
    room.connections.set("o", { id: "socket-o" });
    room.connections.set("viewer", { id: "socket-viewer" });
    await service.move(room.code, "x", 0, 0);

    service.leave(room.code, leavingId);

    const remainingId = leavingId === "x" ? "o" : "x";
    assert.equal(room.status, "WAITING");
    assert.equal(room.turn, "X");
    assert.equal(room.winner, null);
    assert.deepEqual(room.players.map(({ id, mark }) => ({ id, mark })), [{ id: remainingId, mark: "X" }]);
    assert.ok(room.board.every((row) => row.every((cell) => cell === "")));
    assert.equal(room.connections.has(leavingId), false);
    assert.equal(room.connections.has(remainingId), true);
    assert.deepEqual(settlements, []);

    service.join(room.code, player("viewer", "候补玩家"));
    assert.equal(room.status, "PLAYING");
    assert.deepEqual(room.players.map(({ id, mark }) => ({ id, mark })), [
      { id: remainingId, mark: "X" },
      { id: "viewer", mark: "O" }
    ]);
    assert.deepEqual(room.spectators, []);
  }
});

test("最后一名玩家离开后删除房间", () => {
  const { service } = createHarness();
  const room = service.create(player("x"));
  room.connections.set("x", { id: "socket-x" });

  assert.equal(service.leave(room.code, "x"), null);
  assert.equal(service.rooms.has(room.code), false);
  assert.equal(room.connections.size, 0);
  assert.throws(() => service.get(room.code), (error) => {
    assert.equal(error.code, "ROOM_NOT_FOUND");
    return true;
  });
});

test("结束房间保持终局状态并在最后玩家离开后释放", async () => {
  const { service } = createHarness();
  const room = service.create(player("x"));
  service.join(room.code, player("o"));
  service.join(room.code, player("viewer"));
  for (const id of ["x", "o", "viewer"]) room.connections.set(id, { id: `socket-${id}` });
  await service.surrender(room.code, "o");
  const finishedBoard = room.board.map((row) => [...row]);

  service.join(room.code, player("late", "终局观战者"));
  room.connections.set("late", { id: "socket-late" });
  assert.equal(room.status, "FINISHED");
  assert.equal(room.players.length, 2);
  assert.deepEqual(room.spectators.map((item) => item.id), ["viewer", "late"]);

  assert.equal(service.leave(room.code, "x"), room);
  assert.equal(room.status, "FINISHED");
  assert.equal(room.winner, "X");
  assert.deepEqual(room.board, finishedBoard);
  assert.deepEqual(room.players.map((item) => item.id), ["o"]);

  assert.equal(service.leave(room.code, "o"), null);
  assert.equal(service.rooms.has(room.code), false);
  assert.equal(room.connections.size, 0);
});
