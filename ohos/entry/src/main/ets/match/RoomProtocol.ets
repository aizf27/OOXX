import { Board, Mark, Move } from '../model/GameModels';
import { MatchResult } from '../model/AppModels';

export interface PlayerPayload {
  id: string;
  name: string;
  mark: string;
}

export interface SpectatorPayload {
  id: string;
  name: string;
}

export interface RoomSnapshotPayload {
  code: string;
  size: number;
  winLength: number;
  board: string[][];
  turn: string;
  status: string;
  winner: string | null;
  yourMark: string | null;
  players: PlayerPayload[];
  spectators: SpectatorPayload[];
}

export class RoomSnapshot {
  readonly code: string;
  readonly board: Board;
  readonly turn: Mark;
  readonly status: string;
  readonly winner: string | null;
  readonly yourMark: Mark | null;
  readonly opponentName: string | null;

  constructor(payload: RoomSnapshotPayload) {
    this.code = payload.code;
    this.board = this.parseBoard(payload);
    this.turn = this.parseMark(payload.turn);
    this.status = payload.status;
    this.winner = payload.winner;
    this.yourMark = payload.yourMark !== null ? this.parseMark(payload.yourMark) : null;
    this.opponentName = this.findOpponentName(payload);
  }

  get isPlaying(): boolean {
    return this.status === 'PLAYING';
  }

  get isWaiting(): boolean {
    return this.status === 'WAITING';
  }

  get isFinished(): boolean {
    return this.status === 'FINISHED';
  }

  toMatchResult(): MatchResult | null {
    if (!this.isFinished || this.winner === null) {
      return null;
    }
    if (this.winner === 'DRAW') {
      return MatchResult.DRAW;
    }
    if (this.yourMark === null) {
      return null;
    }
    return this.winner === this.markWire(this.yourMark) ? MatchResult.WIN : MatchResult.LOSS;
  }

  private parseBoard(payload: RoomSnapshotPayload): Board {
    const size = payload.size;
    const cells: Mark[] = [];
    for (let row = 0; row < size; row++) {
      const line = payload.board[row];
      for (let col = 0; col < size; col++) {
        cells.push(this.parseMark(line[col]));
      }
    }
    return new Board(size, payload.winLength, cells);
  }

  private findOpponentName(payload: RoomSnapshotPayload): string | null {
    const mine = payload.yourMark ?? '';
    for (let i = 0; i < payload.players.length; i++) {
      const player = payload.players[i];
      if (player.mark !== mine) {
        return player.name;
      }
    }
    return null;
  }

  private parseMark(raw: string): Mark {
    if (raw === 'X') {
      return Mark.X;
    }
    if (raw === 'O') {
      return Mark.O;
    }
    return Mark.EMPTY;
  }

  private markWire(mark: Mark): string {
    if (mark === Mark.X) {
      return 'X';
    }
    if (mark === Mark.O) {
      return 'O';
    }
    return '';
  }
}

export class RoomEvent {
  static connected(playerId: string): ConnectedRoomEvent {
    return new ConnectedRoomEvent(playerId);
  }

  static helloOk(playerId: string, name: string): HelloOkRoomEvent {
    return new HelloOkRoomEvent(playerId, name);
  }

  static roomCreated(room: RoomSnapshot): RoomCreatedEvent {
    return new RoomCreatedEvent(room);
  }

  static roomState(room: RoomSnapshot): RoomStateEvent {
    return new RoomStateEvent(room);
  }

  static failure(code: string, message: string): FailureRoomEvent {
    return new FailureRoomEvent(code, message);
  }
}

export class ConnectedRoomEvent {
  readonly playerId: string;

  constructor(playerId: string) {
    this.playerId = playerId;
  }
}

export class HelloOkRoomEvent {
  readonly playerId: string;
  readonly name: string;

  constructor(playerId: string, name: string) {
    this.playerId = playerId;
    this.name = name;
  }
}

export class RoomCreatedEvent {
  readonly room: RoomSnapshot;

  constructor(room: RoomSnapshot) {
    this.room = room;
  }
}

export class RoomStateEvent {
  readonly room: RoomSnapshot;

  constructor(room: RoomSnapshot) {
    this.room = room;
  }
}

export class FailureRoomEvent {
  readonly code: string;
  readonly message: string;

  constructor(code: string, message: string) {
    this.code = code;
    this.message = message;
  }
}

export type RoomEventUnion =
  | ConnectedRoomEvent
  | HelloOkRoomEvent
  | RoomCreatedEvent
  | RoomStateEvent
  | FailureRoomEvent;

export interface HelloMessage {
  type: string;
  playerId: string;
  name: string;
}

export interface CreateRoomMessage {
  type: string;
  size: number;
  winLength: number;
}

export interface JoinRoomMessage {
  type: string;
  code: string;
}

export interface MoveMessage {
  type: string;
  row: number;
  col: number;
}

export class RoomProtocol {
  static hello(playerId: string, name: string): string {
    return JSON.stringify({ type: 'hello', playerId, name });
  }

  static createRoom(size: number = 3, winLength: number = size === 3 ? 3 : 4): string {
    return JSON.stringify({ type: 'room.create', size, winLength });
  }

  static joinRoom(code: string): string {
    return JSON.stringify({ type: 'room.join', code });
  }

  static requestRoomState(code: string): string {
    return JSON.stringify({ type: 'room.state', code });
  }

  static move(row: number, col: number): string {
    return JSON.stringify({ type: 'move', row, col });
  }

  static surrender(): string {
    return JSON.stringify({ type: 'game.surrender' });
  }

  static decode(text: string): RoomEventUnion | null {
    try {
      const json: Record<string, Object> = JSON.parse(text);
      const type = json.type as string;
      if (type === 'connected') {
        return RoomEvent.connected(String(json.playerId));
      }
      if (type === 'hello.ok') {
        return RoomEvent.helloOk(String(json.playerId), String(json.name ?? ''));
      }
      if (type === 'room.created') {
        return RoomEvent.roomCreated(new RoomSnapshot(json.room as RoomSnapshotPayload));
      }
      if (type === 'room.state') {
        return RoomEvent.roomState(new RoomSnapshot(json.room as RoomSnapshotPayload));
      }
      if (type === 'error') {
        return RoomEvent.failure(String(json.code ?? 'UNKNOWN'), String(json.message ?? '未知错误'));
      }
      return null;
    } catch {
      return null;
    }
  }
}

