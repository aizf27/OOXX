import { OoxxBottomNav } from '../components/OoxxBottomNav';
import { OoxxTopBar } from '../components/OoxxTopBar';
import { StatCard } from '../components/StatCard';
import { MatchRecord, MatchResult } from '../model/AppModels';
import {
  calculateHistoryStats,
  filterMatchRecords,
  formatRelativeTime,
  HistoryFilter,
  HistoryStats,
  historyFilterLabel
} from '../service/HistoryFilter';
import { OoxxRadius, OoxxSpacing, OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct HistoryPage {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop records: MatchRecord[] = [];
  @State selectedFilter: HistoryFilter = HistoryFilter.ALL;
  onBack: () => void = () => {};
  onOpenProfile: () => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  stats(): HistoryStats {
    return calculateHistoryStats(this.records);
  }

  visibleRecords(): MatchRecord[] {
    return filterMatchRecords(this.records, this.selectedFilter).slice(0, 20);
  }

  build() {
    Column() {
      OoxxTopBar({ title: '对战记录', showBack: true, onBack: () => this.onBack(), onAction: () => {} })
        .margin({ top: 16, bottom: 18 })
      Row({ space: 8 }) {
        StatCard({ value: `${this.stats().winRate}%`, label: '胜率', color: this.theme().SUNNY_SOFT })
        StatCard({ value: `${this.stats().winStreak}`, label: '连胜场次', color: this.theme().TEAL_SOFT })
        StatCard({ value: `${this.stats().total}`, label: '总场次', color: this.theme().MINT })
      }
      .width('100%')
      .margin({ bottom: 18 })
      Row({ space: 4 }) {
        this.filterTab(HistoryFilter.ALL)
        this.filterTab(HistoryFilter.WIN)
        this.filterTab(HistoryFilter.LOSS)
        this.filterTab(HistoryFilter.DRAW)
      }
      .width('100%')
      .height(38)
      .borderRadius(OoxxRadius.PILL)
      .backgroundColor(this.theme().WHITE)
      .border({ width: 1, color: this.theme().LINE })
      .padding(4)
      .margin({ bottom: 14 })
      Text('最近对局')
        .width('100%')
        .fontSize(13)
        .fontColor(this.theme().MUTED)
        .margin({ bottom: 8 })
      if (this.visibleRecords().length === 0) {
        Column({ space: 8 }) {
          Text('◎')
            .fontSize(34)
            .fontColor(this.theme().MUTED)
          Text(this.emptyMessage())
            .fontSize(14)
            .fontColor(this.theme().MUTED)
            .textAlign(TextAlign.Center)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.visibleRecords(), (record: MatchRecord) => {
            ListItem() {
              this.recordRow(record)
            }
          }, (record: MatchRecord) => `${record.playedAt}-${record.mode}-${record.steps}`)
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
      }
      OoxxBottomNav({ selected: 'history', onHome: () => this.onBack(), onHistory: () => {}, onProfile: () => this.onOpenProfile() })
    }
    .width('100%')
    .height('100%')
    .padding({ left: OoxxSpacing.PAGE, right: OoxxSpacing.PAGE })
    .backgroundColor(this.theme().PAPER)
  }

  emptyMessage(): string {
    if (this.records.length === 0) {
      return '还没有记录，先去完成一局吧';
    }
    return `暂无${historyFilterLabel(this.selectedFilter)}战绩`;
  }

  resultLabel(result: MatchResult): string {
    if (result === MatchResult.WIN) {
      return '胜';
    }
    if (result === MatchResult.LOSS) {
      return '负';
    }
    return '平';
  }

  resultColor(result: MatchResult): string {
    if (result === MatchResult.WIN) {
      return this.theme().TEAL;
    }
    if (result === MatchResult.LOSS) {
      return this.theme().CORAL;
    }
    return this.theme().SKY;
  }

  @Builder
  filterTab(filter: HistoryFilter) {
    Text(historyFilterLabel(filter))
      .layoutWeight(1)
      .height(28)
      .textAlign(TextAlign.Center)
      .fontSize(13)
      .fontWeight(this.selectedFilter === filter ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.selectedFilter === filter ? this.theme().WHITE : this.theme().MUTED)
      .backgroundColor(this.selectedFilter === filter ? this.theme().CORAL : Color.Transparent)
      .borderRadius(OoxxRadius.PILL)
      .onClick(() => this.selectedFilter = filter)
  }

  @Builder
  recordRow(record: MatchRecord) {
    Row() {
      Text(this.resultLabel(record.result))
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.resultColor(record.result))
        .backgroundColor(this.theme().SOFT_GRAY)
        .borderRadius(20)
      Column({ space: 4 }) {
        Text(record.mode)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme().INK)
          .maxLines(1)
        Text(`对手：${record.opponent} · ${record.steps} 步`)
          .fontSize(12)
          .fontColor(this.theme().MUTED)
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 10, right: 8 })
      Text(formatRelativeTime(record.playedAt))
        .fontSize(12)
        .fontColor(this.theme().MUTED)
    }
    .width('100%')
    .height(64)
    .padding({ left: 10, right: 10 })
    .backgroundColor(this.theme().WHITE)
    .borderRadius(OoxxRadius.CARD)
    .border({ width: 1, color: this.theme().LINE })
  }
}
