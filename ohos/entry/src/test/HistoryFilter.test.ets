import { describe, it, expect } from '@ohos/hypium';
import { MatchRecord, MatchResult } from '../main/ets/model/AppModels';
import {
  calculateHistoryStats,
  filterMatchRecords,
  formatRelativeTime,
  HistoryFilter
} from '../main/ets/service/HistoryFilter';

export default function historyFilterTest() {
  describe('HistoryFilter', () => {
    const records: MatchRecord[] = [
      new MatchRecord(MatchResult.WIN, '在线对战', '甲', 300, 5),
      new MatchRecord(MatchResult.WIN, '经典 3×3', '乙', 200, 6),
      new MatchRecord(MatchResult.LOSS, '进阶 5×5', '丙', 100, 8),
      new MatchRecord(MatchResult.DRAW, '双人同屏', '丁', 50, 9)
    ];

    it('allFilterReturnsEveryRecordInOriginalOrder', 0, () => {
      const filtered = filterMatchRecords(records, HistoryFilter.ALL);
      expect(filtered.length).assertEqual(4);
      expect(filtered[0].playedAt).assertEqual(300);
      expect(filtered[3].playedAt).assertEqual(50);
    });

    it('resultFiltersReturnOnlyMatchingRecords', 0, () => {
      const wins = filterMatchRecords(records, HistoryFilter.WIN);
      const losses = filterMatchRecords(records, HistoryFilter.LOSS);
      const draws = filterMatchRecords(records, HistoryFilter.DRAW);
      expect(wins.length).assertEqual(2);
      expect(wins[0].opponent).assertEqual('甲');
      expect(losses.length).assertEqual(1);
      expect(losses[0].opponent).assertEqual('丙');
      expect(draws.length).assertEqual(1);
      expect(draws[0].opponent).assertEqual('丁');
    });

    it('returnsEmptyListWhenNoResultMatches', 0, () => {
      const onlyWin = [new MatchRecord(MatchResult.WIN, '经典 3×3', '甲', 100, 5)];
      expect(filterMatchRecords(onlyWin, HistoryFilter.DRAW).length).assertEqual(0);
    });

    it('calculatesOverallStatsAndLatestWinStreak', 0, () => {
      const stats = calculateHistoryStats(records);
      expect(stats.total).assertEqual(4);
      expect(stats.winRate).assertEqual(50);
      expect(stats.winStreak).assertEqual(2);
      const empty = calculateHistoryStats([]);
      expect(empty.total).assertEqual(0);
      expect(empty.winRate).assertEqual(0);
      expect(empty.winStreak).assertEqual(0);
    });

    it('formatsRelativeTimeBoundariesAndFutureAsNow', 0, () => {
      const now = 10 * 86400000;
      expect(formatRelativeTime(now + 1000, now)).assertEqual('刚刚');
      expect(formatRelativeTime(now - 59000, now)).assertEqual('刚刚');
      expect(formatRelativeTime(now - 60000, now)).assertEqual('1 分钟前');
      expect(formatRelativeTime(now - 3600000, now)).assertEqual('1 小时前');
      expect(formatRelativeTime(now - 86400000, now)).assertEqual('1 天前');
    });
  });
}
