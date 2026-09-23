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
