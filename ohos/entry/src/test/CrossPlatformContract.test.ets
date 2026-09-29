import { describe, it, expect } from '@ohos/hypium';
import { MatchResult } from '../main/ets/model/AppModels';
import { DailyPuzzlePayload } from '../main/ets/network/ApiContracts';
import { Board, Mark } from '../main/ets/model/GameModels';
import {
  ConnectedRoomEvent,
  FailureRoomEvent,
  HelloOkRoomEvent,
  RoomCreatedEvent,
  RoomProtocol,
  RoomStateEvent
} from '../main/ets/match/RoomProtocol';
import { scoreForResult } from '../main/ets/repository/LocalGameRepository';
import { GameEngine } from '../main/ets/service/GameEngine';
import { PuzzleValidator } from '../main/ets/service/PuzzleValidator';
import {
  CLIENT_MESSAGE_CASES,
  CONTRACT_SCORE_DRAW,
  CONTRACT_SCORE_LOSS,
  CONTRACT_SCORE_WIN,
  CONTRACT_VERSION,
  ContractInvalidRuleCase,
  ContractPuzzlePayload,
  ContractRuleCase,
  ContractWireCase,
  GAME_RULE_CASES,
  INVALID_GAME_RULE_CASES,
  INVALID_PUZZLE_CASES,
  INVALID_SERVER_MESSAGE_CASES,
  SERVER_MESSAGE_CASES,
  VALID_PUZZLE_CASES
} from './fixtures/ContractFixtures';

function wireById(items: ContractWireCase[], id: string): string {
  for (let index = 0; index < items.length; index++) {
    if (items[index].id === id) {
      return items[index].wire;
    }
  }
  throw new Error(`找不到契约消息：${id}`);
}

function markFromWire(value: string | null): Mark | null {
  if (value === 'X') {
    return Mark.X;
  }
  if (value === 'O') {
    return Mark.O;
  }
  return null;
}

function boardFromValues(size: number, winLength: number, encoded: string): Board {
  if (!((size === 3 && winLength === 3) || (size === 5 && winLength === 4))) {
    throw new Error('不支持的棋盘模式');
  }
  if (encoded.length !== size * size) {
    throw new Error('棋盘长度无效');
  }
  const cells: Mark[] = [];
  for (let index = 0; index < encoded.length; index++) {
    const value = encoded[index];
    if (value === 'X') {
      cells.push(Mark.X);
    } else if (value === 'O') {
      cells.push(Mark.O);
    } else if (value === '.') {
      cells.push(Mark.EMPTY);
    } else {
      throw new Error('棋盘包含非法棋子');
    }
  }
  return new Board(size, winLength, cells);
}

function boardFrom(item: ContractRuleCase): Board {
  return boardFromValues(item.size, item.winLength, item.board);
}

function puzzlePayloadFrom(item: ContractPuzzlePayload): DailyPuzzlePayload {
  return {
    id: item.id,
    title: item.title,
    size: item.size,
    winLength: item.winLength,
    board: item.board,
    next: item.next,
    answer: {
      row: item.answer.row,
      col: item.answer.col
    }
  };
}

function invalidBoardFrom(item: ContractInvalidRuleCase): Board {
  return boardFromValues(item.size, item.winLength, item.board);
}

export default function crossPlatformContractTest() {
  describe('CrossPlatformContract', () => {
    const engine = new GameEngine();
    const puzzleValidator = new PuzzleValidator(engine);

    it('matchesSharedGameRulesAndScoring', 0, () => {
      expect(CONTRACT_VERSION).assertEqual(1);
      for (let index = 0; index < GAME_RULE_CASES.length; index++) {
        const item = GAME_RULE_CASES[index];
        const board = boardFrom(item);
        expect(engine.winner(board)).assertEqual(markFromWire(item.winner));
        expect(engine.isDraw(board)).assertEqual(item.draw);
      }
      for (let index = 0; index < INVALID_GAME_RULE_CASES.length; index++) {
        let rejected = false;
        try {
          invalidBoardFrom(INVALID_GAME_RULE_CASES[index]);
        } catch (_) {
          rejected = true;
        }
        expect(rejected).assertTrue();
      }
      expect(scoreForResult(MatchResult.WIN)).assertEqual(CONTRACT_SCORE_WIN);
      expect(scoreForResult(MatchResult.DRAW)).assertEqual(CONTRACT_SCORE_DRAW);
      expect(scoreForResult(MatchResult.LOSS)).assertEqual(CONTRACT_SCORE_LOSS);
    });

    it('validatesSharedPuzzleCases', 0, () => {
      for (let index = 0; index < VALID_PUZZLE_CASES.length; index++) {
        const item = VALID_PUZZLE_CASES[index];
        const puzzle = puzzleValidator.validate(puzzlePayloadFrom(item.payload));
        expect(puzzle.answer.row).assertEqual(item.expected.answer.row);
        expect(puzzle.answer.col).assertEqual(item.expected.answer.col);
        const completed = puzzle.board.place(puzzle.answer, puzzle.next);
        expect(engine.winner(completed)).assertEqual(markFromWire(item.expected.winnerAfterMove));
      }

      for (let index = 0; index < INVALID_PUZZLE_CASES.length; index++) {
        let rejected = false;
        try {
          puzzleValidator.validate(puzzlePayloadFrom(INVALID_PUZZLE_CASES[index].payload));
        } catch (_) {
          rejected = true;
        }
        expect(rejected).assertTrue();
      }
    });

    it('serializesClientMessagesFromContract', 0, () => {
      expect(RoomProtocol.hello('guest-contract', '契约玩家'))
        .assertEqual(wireById(CLIENT_MESSAGE_CASES, 'hello'));
      expect(RoomProtocol.createRoom(3))
        .assertEqual(wireById(CLIENT_MESSAGE_CASES, 'create-classic-room'));
      expect(RoomProtocol.createRoom(5))
        .assertEqual(wireById(CLIENT_MESSAGE_CASES, 'create-advanced-room'));
      expect(RoomProtocol.joinRoom('ABC123'))
        .assertEqual(wireById(CLIENT_MESSAGE_CASES, 'join-room'));
      expect(RoomProtocol.requestRoomState('ABC123'))
        .assertEqual(wireById(CLIENT_MESSAGE_CASES, 'request-room-state'));
      expect(RoomProtocol.move(1, 2))
        .assertEqual(wireById(CLIENT_MESSAGE_CASES, 'move'));
      expect(RoomProtocol.surrender())
        .assertEqual(wireById(CLIENT_MESSAGE_CASES, 'surrender'));
    });

    it('decodesServerMessagesFromContract', 0, () => {
      const connected = RoomProtocol.decode(wireById(SERVER_MESSAGE_CASES, 'connected'));
      expect(connected instanceof ConnectedRoomEvent).assertTrue();
      if (connected instanceof ConnectedRoomEvent) {
        expect(connected.playerId).assertEqual('guest-server');
      }

      const helloOk = RoomProtocol.decode(wireById(SERVER_MESSAGE_CASES, 'hello-ok'));
      expect(helloOk instanceof HelloOkRoomEvent).assertTrue();
      if (helloOk instanceof HelloOkRoomEvent) {
        expect(helloOk.name).assertEqual('契约玩家');
      }

      const created = RoomProtocol.decode(wireById(SERVER_MESSAGE_CASES, 'room-created-waiting'));
      expect(created instanceof RoomCreatedEvent).assertTrue();
      if (created instanceof RoomCreatedEvent) {
        expect(created.room.isWaiting).assertTrue();
        expect(created.room.yourMark).assertEqual(Mark.X);
      }

      const playing = RoomProtocol.decode(wireById(SERVER_MESSAGE_CASES, 'room-state-playing'));
      expect(playing instanceof RoomStateEvent).assertTrue();
      if (playing instanceof RoomStateEvent) {
        expect(playing.room.isPlaying).assertTrue();
        expect(playing.room.opponentName).assertEqual('乙方');
      }

      const win = RoomProtocol.decode(wireById(SERVER_MESSAGE_CASES, 'room-state-win'));
      expect(win instanceof RoomStateEvent).assertTrue();
      if (win instanceof RoomStateEvent) {
        expect(win.room.toMatchResult()).assertEqual(MatchResult.WIN);
        expect(engine.winner(win.room.board)).assertEqual(Mark.X);
      }

      const draw = RoomProtocol.decode(wireById(SERVER_MESSAGE_CASES, 'room-state-draw'));
      expect(draw instanceof RoomStateEvent).assertTrue();
      if (draw instanceof RoomStateEvent) {
        expect(draw.room.toMatchResult()).assertEqual(MatchResult.DRAW);
        expect(engine.isDraw(draw.room.board)).assertTrue();
      }

      const failure = RoomProtocol.decode(wireById(SERVER_MESSAGE_CASES, 'error'));
      expect(failure instanceof FailureRoomEvent).assertTrue();
      if (failure instanceof FailureRoomEvent) {
        expect(failure.code).assertEqual('NOT_YOUR_TURN');
      }

      for (let index = 0; index < INVALID_SERVER_MESSAGE_CASES.length; index++) {
        expect(RoomProtocol.decode(INVALID_SERVER_MESSAGE_CASES[index].wire)).assertNull();
      }
    });
  });
}
