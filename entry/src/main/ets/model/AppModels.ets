import { Board, Mark, Move } from './GameModels';

export enum Screen {
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

  constructor(board: Board = new Board(), turn: Mark = Mark.X, playerMark: Mark = Mark.X,
    kind: GameKind = GameKind.AI_3X3, moves: number = 0, message: string = '轮到你了',
    puzzleAnswer: Move | null = null, puzzleSolved: boolean | null = null, isAiThinking: boolean = false) {
    this.board = board;
    this.turn = turn;
    this.playerMark = playerMark;
    this.kind = kind;
    this.moves = moves;
    this.message = message;
    this.puzzleAnswer = puzzleAnswer;
    this.puzzleSolved = puzzleSolved;
    this.isAiThinking = isAiThinking;
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