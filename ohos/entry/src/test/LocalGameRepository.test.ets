import { describe, it, expect } from '@ohos/hypium';
import { MatchRecord, MatchResult } from '../main/ets/model/AppModels';
import { LocalGameRepository, MemoryRecordDataSource } from '../main/ets/repository/LocalGameRepository';

export default function localGameRepositoryTest() {
  describe('LocalGameRepository', () => {
    it('savesRecordsInReverseTimeOrder', 0, async () => {
      const repository = new LocalGameRepository(new MemoryRecordDataSource());
      await repository.save(new MatchRecord(MatchResult.WIN, '经典 3×3', 'AI 棋手', 100, 5));
      await repository.save(new MatchRecord(MatchResult.DRAW, '双人同屏', '本地玩家', 300, 9));
      await repository.save(new MatchRecord(MatchResult.LOSS, '进阶 5×5', 'AI 棋手', 200, 8));

      const records = await repository.records();
      expect(records.length).assertEqual(3);
      expect(records[0].playedAt).assertEqual(300);
      expect(records[2].playedAt).assertEqual(100);
    });

    it('calculatesSameScoreRuleAsAndroid', 0, async () => {
      const repository = new LocalGameRepository(new MemoryRecordDataSource());
      await repository.save(new MatchRecord(MatchResult.WIN, '经典 3×3', 'AI 棋手', 100, 5));
      await repository.save(new MatchRecord(MatchResult.DRAW, '双人同屏', '本地玩家', 200, 9));
      await repository.save(new MatchRecord(MatchResult.LOSS, '进阶 5×5', 'AI 棋手', 300, 8));

      const ranking = await repository.ranking();
      let myScore = 0;
      for (let index = 0; index < ranking.length; index++) {
        if (ranking[index].isMe) {
          myScore = ranking[index].score;
        }
      }
      expect(myScore).assertEqual(662);
    });

    it('fallbackPuzzleKeepsUniqueAnswer', 0, () => {
      const repository = new LocalGameRepository(new MemoryRecordDataSource());
      const puzzle = repository.fallbackPuzzle();
      expect(puzzle.board.isEmpty(puzzle.answer)).assertTrue();
    });
  });
}
