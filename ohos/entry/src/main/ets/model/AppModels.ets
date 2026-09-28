import { LogicBoard } from '../service/LogicPuzzleEngine';
import { Board, Mark, Move } from './GameModels';

export enum AppScreen {
  SPLASH = 'SPLASH',
  ONBOARDING = 'ONBOARDING',
  HOME = 'HOME',
  MODE = 'MODE',
  ROOM = 'ROOM',
  GAME = 'GAME',
  RESULT = 'RESULT',
  HISTORY = 'HISTORY',
  PROFILE = 'PROFILE'
}

export enum GameKind {
  AI_3X3 = 'AI_3X3',
  AI_5X5 = 'AI_5X5',
  LOGIC_6X6 = 'LOGIC_6X6',
  LOCAL = 'LOCAL',
  DAILY = 'DAILY',
  NETWORK = 'NETWORK',
  BLUETOOTH = 'BLUETOOTH'
}

export enum MatchResult {
  WIN = 'WIN',
  LOSS = 'LOSS',
  DRAW = 'DRAW'
}

export enum RoomStatus {
  WAITING = 'WAITING',
  PLAYING = 'PLAYING',
  FINISHED = 'FINISHED'
}

export interface GameSessionUpdate {
  board?: Board;
  turn?: Mark;
  playerMark?: Mark;
  kind?: GameKind;
  moves?: number;
  message?: string;
  puzzleAnswer?: Move | null;
  puzzleSolved?: boolean | null;
  isAiThinking?: boolean;
  logicBoard?: LogicBoard | null;
  logicHistory?: LogicBoard[];
  opponentName?: string | null;
}

export class GameSession {
  readonly board: Board;
  readonly turn: Mark;
  readonly playerMark: Mark;
  readonly kind: GameKind;
  readonly moves: number;
  readonly message: string;
  readonly puzzleAnswer: Move | null;
  readonly puzzleSolved: boolean | null;
  readonly isAiThinking: boolean;
  readonly logicBoard: LogicBoard | null;
  readonly logicHistory: LogicBoard[];
  readonly opponentName: string | null;

  constructor(board: Board = new Board(), turn: Mark = Mark.X, playerMark: Mark = Mark.X,
    kind: GameKind = GameKind.AI_3X3, moves: number = 0, message: string = '轮到你了',
    puzzleAnswer: Move | null = null, puzzleSolved: boolean | null = null, isAiThinking: boolean = false,
    logicBoard: LogicBoard | null = null, logicHistory: LogicBoard[] = [], opponentName: string | null = null) {
    this.board = board;
    this.turn = turn;
    this.playerMark = playerMark;
    this.kind = kind;
    this.moves = moves;
    this.message = message;
    this.puzzleAnswer = puzzleAnswer;
    this.puzzleSolved = puzzleSolved;
    this.isAiThinking = isAiThinking;
    this.logicBoard = logicBoard;
    this.logicHistory = logicHistory;
    this.opponentName = opponentName;
  }

  copy(params?: GameSessionUpdate): GameSession {
    return new GameSession(
      params?.board ?? this.board,
      params?.turn ?? this.turn,
      params?.playerMark ?? this.playerMark,
      params?.kind ?? this.kind,
      params?.moves ?? this.moves,
      params?.message ?? this.message,
      params?.puzzleAnswer ?? this.puzzleAnswer,
      params?.puzzleSolved ?? this.puzzleSolved,
      params?.isAiThinking ?? this.isAiThinking,
      params?.logicBoard ?? this.logicBoard,
      params?.logicHistory ?? this.logicHistory,
      params?.opponentName ?? this.opponentName
    );
  }
}

export class MatchRecord {
  readonly result: MatchResult;
  readonly mode: string;
  readonly opponent: string;
  readonly playedAt: number;
  readonly steps: number;

  constructor(result: MatchResult, mode: string, opponent: string, playedAt: number, steps: number) {
    this.result = result;
    this.mode = mode;
    this.opponent = opponent;
    this.playedAt = playedAt;
    this.steps = steps;
  }
}

export class RankingEntry {
  readonly rank: number;
  readonly playerId: string;
  readonly name: string;
  readonly score: number;
  readonly wins: number;
  readonly losses: number;
  readonly draws: number;
  readonly isMe: boolean;

  constructor(rank: number, playerId: string, name: string, score: number,
    wins: number, losses: number, draws: number, isMe: boolean = false) {
    this.rank = rank;
    this.playerId = playerId;
    this.name = name;
    this.score = score;
    this.wins = wins;
    this.losses = losses;
    this.draws = draws;
    this.isMe = isMe;
  }
}

export interface SettingsUpdate {
  sound?: boolean;
  vibration?: boolean;
  darkMode?: boolean;
}

export class Settings {
  readonly sound: boolean;
  readonly vibration: boolean;
  readonly darkMode: boolean;

  constructor(sound: boolean = true, vibration: boolean = true, darkMode: boolean = false) {
    this.sound = sound;
    this.vibration = vibration;
    this.darkMode = darkMode;
  }

  copy(params?: SettingsUpdate): Settings {
    return new Settings(
      params?.sound ?? this.sound,
      params?.vibration ?? this.vibration,
      params?.darkMode ?? this.darkMode
    );
  }
}

export interface NetworkRoomUpdate {
  connecting?: boolean;
  roomCode?: string;
  waiting?: boolean;
  statusMessage?: string;
  error?: string | null;
}

export class NetworkRoom {
  readonly connecting: boolean;
  readonly roomCode: string;
  readonly waiting: boolean;
  readonly statusMessage: string;
  readonly error: string | null;

  constructor(connecting: boolean = false, roomCode: string = '', waiting: boolean = false,
    statusMessage: string = '选择连接方式', error: string | null = null) {
    this.connecting = connecting;
    this.roomCode = roomCode;
    this.waiting = waiting;
    this.statusMessage = statusMessage;
    this.error = error;
  }

  copy(params?: NetworkRoomUpdate): NetworkRoom {
    return new NetworkRoom(
      params?.connecting ?? this.connecting,
      params?.roomCode ?? this.roomCode,
      params?.waiting ?? this.waiting,
      params?.statusMessage ?? this.statusMessage,
      params?.error ?? this.error
    );
  }
}
