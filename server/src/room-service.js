import { createBoard, isDraw, roomSnapshot, winner } from "./game-rules.js";

export class RoomService {
  constructor(rankingStore) { this.rankingStore = rankingStore; this.rooms = new Map(); }

  create(client, { size = 3, winLength = size === 3 ? 3 : 4 } = {}) {
    if (![3, 5].includes(size)) throw new ClientError("UNSUPPORTED_SIZE", "仅支持 3×3 或 5×5 棋盘");
    const expectedWinLength = size === 3 ? 3 : 4;
    if (winLength !== expectedWinLength) throw new ClientError("INVALID_WIN_LENGTH", "连线长度与棋盘模式不匹配");
    const room = {
      code: this.nextCode(), size, winLength, board: createBoard(size), turn: "X", status: "WAITING", winner: null,
      players: [{ ...client, mark: "X" }], spectators: [], connections: new Map()
    };
    this.rooms.set(room.code, room);
    return room;
  }

  join(code, client) {
    const room = this.get(code);
    if (room.players.some((player) => player.id === client.id)) return room;
    const spectatorIndex = room.spectators.findIndex((player) => player.id === client.id);
    if (room.players.length < 2 && room.status === "WAITING") {
      if (spectatorIndex >= 0) room.spectators.splice(spectatorIndex, 1);
      const mark = room.players.some((player) => player.mark === "X") ? "O" : "X";
      room.players.push({ ...client, mark });
      room.status = "PLAYING";
    } else if (spectatorIndex < 0) room.spectators.push(client);
    return room;
  }

  leave(code, clientId) {
    const normalizedCode = String(code).toUpperCase();
    const room = this.rooms.get(normalizedCode);
    if (!room) return null;
    const playerIndex = room.players.findIndex((player) => player.id === clientId);
    const spectatorIndex = room.spectators.findIndex((player) => player.id === clientId);
    if (playerIndex < 0 && spectatorIndex < 0) return room;

    room.connections.delete(clientId);
    if (spectatorIndex >= 0) {
      room.spectators.splice(spectatorIndex, 1);
      return room;
    }

    room.players.splice(playerIndex, 1);
    if (room.players.length === 0) {
      room.connections.clear();
      this.rooms.delete(normalizedCode);
      return null;
    }
    if (room.status === "PLAYING") this.resetToWaiting(room);
    return room;
  }

  resetToWaiting(room) {
    room.players = room.players.map((player, index) => ({ ...player, mark: index === 0 ? "X" : "O" }));
    room.board = createBoard(room.size);
    room.turn = "X";
    room.status = "WAITING";
    room.winner = null;
  }

  async move(code, clientId, row, col) {
    const room = this.get(code);
    if (room.status !== "PLAYING") throw new ClientError("GAME_NOT_READY", "等待另一位玩家加入");
    const player = room.players.find((item) => item.id === clientId);
    if (!player) throw new ClientError("SPECTATOR_READ_ONLY", "观战者不能落子");
    if (player.mark !== room.turn) throw new ClientError("NOT_YOUR_TURN", "还没有轮到你");
    if (!Number.isInteger(row) || !Number.isInteger(col) || row < 0 || row >= room.size || col < 0 || col >= room.size) throw new ClientError("INVALID_MOVE", "坐标超出棋盘");
    if (room.board[row][col]) throw new ClientError("CELL_OCCUPIED", "该位置已有棋子");
    room.board[row][col] = player.mark;
    const won = winner(room.board, room.winLength);
    if (won) { room.status = "FINISHED"; room.winner = won; await this.settle(room, won); }
    else if (isDraw(room.board)) { room.status = "FINISHED"; room.winner = "DRAW"; await this.settle(room, "DRAW"); }
    else room.turn = room.turn === "X" ? "O" : "X";
    return room;
  }

  async surrender(code, clientId) {
    const room = this.get(code);
    const player = room.players.find((item) => item.id === clientId);
    if (!player || room.status !== "PLAYING") throw new ClientError("INVALID_SURRENDER", "当前不能认输");
    room.winner = player.mark === "X" ? "O" : "X"; room.status = "FINISHED";
    await this.settle(room, room.winner); return room;
  }

  get(code) {
    const room = this.rooms.get(String(code).toUpperCase());
    if (!room) throw new ClientError("ROOM_NOT_FOUND", "房间不存在或已结束");
    return room;
  }
  snapshot(room, playerId) { return roomSnapshot(room, playerId); }
  async settle(room, winnerMark) {
    await Promise.all(room.players.map((player) => this.rankingStore.applyMatch({
      id: player.id, name: player.name,
      result: winnerMark === "DRAW" ? "DRAW" : player.mark === winnerMark ? "WIN" : "LOSS"
    })));
  }
  nextCode() { let code; do code = String(Math.floor(100000 + Math.random() * 900000)); while (this.rooms.has(code)); return code; }
}

export class ClientError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
