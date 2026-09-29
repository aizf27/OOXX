import { describe, it, expect } from '@ohos/hypium';
import { GameKind, GameSession, MatchResult } from '../main/ets/model/AppModels';
import { Board, Mark, Move } from '../main/ets/model/GameModels';
import { LocalGameRepository, MemoryRecordDataSource } from '../main/ets/repository/LocalGameRepository';
import { GameStore, MoveHandling } from '../main/ets/store/GameStore';

export default function gameStoreTest() {
  describe('GameStore', () => {
    it('runsPlayerAndAiAsSeparateTurns', 0, async () => {
      const repository = new LocalGameRepository(new MemoryRecordDataSource());
      const store = new GameStore(repository);
      store.start(GameKind.AI_3X3);
      expect(store.session.message).assertEqual('轮到 X 落子');

      const decision = await store.play(new Move(0, 0));
      expect(decision.handling).assertEqual(MoveHandling.LOCAL_APPLIED);
      expect(store.session.isAiThinking).assertTrue();
      expect(store.session.moves).assertEqual(1);
      expect(store.session.message).assertEqual('轮到 O 落子 · AI 思考中…');

      expect(await store.playAiTurn()).assertTrue();
      expect(store.session.isAiThinking).assertFalse();
      expect(store.session.moves).assertEqual(2);
      expect(store.session.turn).assertEqual(Mark.X);
      expect(store.session.message).assertEqual('轮到 X 落子');
    });

    it('switchesLocalTurnPromptBetweenXAndO', 0, async () => {
      const repository = new LocalGameRepository(new MemoryRecordDataSource());
      const store = new GameStore(repository);
      store.start(GameKind.LOCAL);
      expect(store.session.message).assertEqual('轮到 X 落子');

      await store.play(new Move(0, 0));
      expect(store.session.message).assertEqual('轮到 O 落子');
      await store.play(new Move(1, 0));
      expect(store.session.message).assertEqual('轮到 X 落子');
    });

    it('finishesLocalWinningLineAndSavesRecord', 0, async () => {
      const repository = new LocalGameRepository(new MemoryRecordDataSource());
      const store = new GameStore(repository);
      store.start(GameKind.LOCAL);
      await store.play(new Move(0, 0));
      await store.play(new Move(1, 0));
      await store.play(new Move(0, 1));
      await store.play(new Move(1, 1));
      await store.play(new Move(0, 2));

      expect(store.result).assertEqual(MatchResult.WIN);
      expect((await repository.records()).length).assertEqual(1);
    });

    it('keepsSpecialModePrompts', 0, () => {
      const repository = new LocalGameRepository(new MemoryRecordDataSource());
      const store = new GameStore(repository);
      store.start(GameKind.DAILY, repository.fallbackPuzzle());
      expect(store.session.message).assertEqual('请选择唯一最优的一步');

      store.start(GameKind.LOGIC_6X6);
      expect(store.session.message).assertContain('点击空格切换 X / O');
    });

    it('solvesDailyPuzzleWithDeclaredMove', 0, async () => {
      const repository = new LocalGameRepository(new MemoryRecordDataSource());
      const store = new GameStore(repository);
      const puzzle = repository.fallbackPuzzle();
      store.start(GameKind.DAILY, puzzle);
      await store.play(puzzle.answer);

      expect(store.session.puzzleSolved).assertTrue();
      expect(store.result).assertEqual(MatchResult.WIN);
    });

    it('doesNotPredictNetworkStateLocally', 0, async () => {
      const repository = new LocalGameRepository(new MemoryRecordDataSource());
      const store = new GameStore(repository);
      store.start(GameKind.NETWORK);

      const decision = await store.play(new Move(0, 0));
      expect(decision.handling).assertEqual(MoveHandling.REMOTE_REQUIRED);
      expect(store.session.board.get(0, 0)).assertEqual(Mark.EMPTY);

      const serverBoard = new Board().place(new Move(0, 0), Mark.X);
      const serverSession = new GameSession(serverBoard, Mark.O, Mark.X, GameKind.NETWORK, 1, '等待对手');
      await store.applyAuthoritativeState(serverSession, null);
      expect(store.session.board.get(0, 0)).assertEqual(Mark.X);
    });

    it('undoRestoresStateBeforePlayerAndAiPair', 0, async () => {
      const repository = new LocalGameRepository(new MemoryRecordDataSource());
      const store = new GameStore(repository);
      store.start(GameKind.AI_3X3);
      await store.play(new Move(0, 0));
      await store.playAiTurn();

      expect(store.undo()).assertTrue();
      expect(store.session.moves).assertEqual(0);
      expect(store.session.board.availableMoves().length).assertEqual(9);
    });
  });
}
