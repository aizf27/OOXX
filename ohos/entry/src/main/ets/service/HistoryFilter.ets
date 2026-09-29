import { MatchRecord, MatchResult } from '../model/AppModels';

export enum HistoryFilter {
  ALL = 'ALL',
  WIN = 'WIN',
  LOSS = 'LOSS',
  DRAW = 'DRAW'
}

export class HistoryStats {
  readonly winRate: number;
  readonly winStreak: number;
  readonly total: number;

  constructor(winRate: number, winStreak: number, total: number) {
    this.winRate = winRate;
    this.winStreak = winStreak;
    this.total = total;
  }
}

export function historyFilterLabel(filter: HistoryFilter): string {
  if (filter === HistoryFilter.WIN) {
    return '胜利';
  }
  if (filter === HistoryFilter.LOSS) {
    return '失败';
  }
  if (filter === HistoryFilter.DRAW) {
    return '平局';
  }
  return '全部';
}

export function filterMatchRecords(records: MatchRecord[], filter: HistoryFilter): MatchRecord[] {
  if (filter === HistoryFilter.ALL) {
    return records.slice();
  }
  const expected = filter === HistoryFilter.WIN ? MatchResult.WIN :
    filter === HistoryFilter.LOSS ? MatchResult.LOSS : MatchResult.DRAW;
  const filtered: MatchRecord[] = [];
  for (let index = 0; index < records.length; index++) {
    if (records[index].result === expected) {
      filtered.push(records[index]);
    }
  }
  return filtered;
}

export function calculateHistoryStats(records: MatchRecord[]): HistoryStats {
  let wins = 0;
  for (let index = 0; index < records.length; index++) {
    if (records[index].result === MatchResult.WIN) {
      wins++;
    }
  }

  let winStreak = 0;
  for (let index = 0; index < records.length; index++) {
    if (records[index].result !== MatchResult.WIN) {
      break;
    }
    winStreak++;
  }

  const winRate = records.length === 0 ? 0 : Math.floor(wins * 100 / records.length);
  return new HistoryStats(winRate, winStreak, records.length);
}

export function formatRelativeTime(playedAt: number, now: number = Date.now()): string {
  const elapsed = now - playedAt;
  if (elapsed < 60000) {
    return '刚刚';
  }
  if (elapsed < 3600000) {
    return `${Math.floor(elapsed / 60000)} 分钟前`;
  }
  if (elapsed < 86400000) {
    return `${Math.floor(elapsed / 3600000)} 小时前`;
  }
  return `${Math.floor(elapsed / 86400000)} 天前`;
}
