import { OoxxBottomNav } from '../components/OoxxBottomNav';
import { OoxxTopBar } from '../components/OoxxTopBar';
import { StatCard } from '../components/StatCard';
import { OoxxColors, OoxxRadius, OoxxSpacing } from '../theme/OoxxTheme';

@Component
export struct HistoryPage {
  onBack: () => void = () => {};
  onOpenProfile: () => void = () => {};

  build() {
    Column() {
      OoxxTopBar({ title: '对战记录', showBack: true, onBack: () => this.onBack(), onAction: () => {} })
        .margin({ top: 16, bottom: 18 })
      Row({ space: 8 }) {
        StatCard({ value: '67%', label: '胜率', color: OoxxColors.SUNNY_SOFT })
        StatCard({ value: '3', label: '连胜场次', color: OoxxColors.TEAL_SOFT })
        StatCard({ value: '12', label: '总场次', color: OoxxColors.MINT })
      }
      .width('100%')
      .margin({ bottom: 18 })
      Row({ space: 8 }) {
        Text('全部').fontColor(OoxxColors.WHITE).backgroundColor(OoxxColors.CORAL)
        Text('胜利').fontColor(OoxxColors.MUTED)
        Text('失败').fontColor(OoxxColors.MUTED)
        Text('平局').fontColor(OoxxColors.MUTED)
      }
      .width('100%')
      .height(34)
      .justifyContent(FlexAlign.SpaceAround)
      .borderRadius(OoxxRadius.PILL)
      .backgroundColor(OoxxColors.WHITE)
      .border({ width: 1, color: OoxxColors.LINE })
      .padding({ left: 4, right: 4 })
      .margin({ bottom: 14 })
      Text('最近对局（视觉示例）')
        .width('100%')
        .fontSize(13)
        .fontColor(OoxxColors.MUTED)
        .margin({ bottom: 8 })
      Column({ space: 8 }) {
        this.recordRow('胜利', '经典 3×3', '1 天前', OoxxColors.CORAL)
        this.recordRow('失败', '经典 3×3', '2 天前', OoxxColors.CORAL)
        this.recordRow('平局', '限时赛', '3 天前', OoxxColors.SKY)
        this.recordRow('胜利', '进阶 5×5', '4 天前', OoxxColors.TEAL)
      }
      .width('100%')
      Blank()
      OoxxBottomNav({ selected: 'history', onHome: () => this.onBack(), onHistory: () => {}, onProfile: () => this.onOpenProfile() })
    }
    .width('100%')
    .height('100%')
    .padding({ left: OoxxSpacing.PAGE, right: OoxxSpacing.PAGE })
    .backgroundColor(OoxxColors.PAPER)
  }

  @Builder
  recordRow(result: string, mode: string, time: string, color: string) {
    Row() {
      Text(result === '胜利' ? 'O' : result === '失败' ? 'X' : '—')
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .backgroundColor(OoxxColors.WHITE)
        .borderRadius(18)
      Column({ space: 3 }) {
        Text(result).fontSize(16).fontWeight(FontWeight.Bold).fontColor(color)
        Text(mode).fontSize(13).fontColor(OoxxColors.MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })
      Blank()
      Text(time).fontSize(13).fontColor(OoxxColors.MUTED)
    }
    .width('100%')
    .height(58)
    .padding({ left: 10, right: 10 })
    .backgroundColor(OoxxColors.WHITE)
    .borderRadius(OoxxRadius.CARD)
    .border({ width: 1, color: OoxxColors.LINE })
  }
}
