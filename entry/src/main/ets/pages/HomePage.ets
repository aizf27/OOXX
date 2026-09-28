import { HomeModeCard } from '../components/HomeModeCard';
import { OoxxBottomNav } from '../components/OoxxBottomNav';
import { OoxxCharacter } from '../components/OoxxCharacter';
import { OoxxColors, OoxxRadius, OoxxSpacing } from '../theme/OoxxTheme';

@Component
export struct HomePage {
  onOpenMode: () => void = () => {};
  onStartLocal: () => void = () => {};
  onOpenRoom: () => void = () => {};
  onOpenDaily: () => void = () => {};
  onOpenHistory: () => void = () => {};
  onOpenProfile: () => void = () => {};

  build() {
    Column() {
      Row() {
        OoxxCharacter({ kind: 'O', charSize: 52, accent: OoxxColors.SKY })
        Column({ space: 3 }) {
          Text('康思').fontSize(20).fontWeight(FontWeight.Bold).fontColor(OoxxColors.INK)
          Text('金币 120').fontSize(13).fontColor(OoxxColors.MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
        Blank()
        Text('⚙')
          .fontSize(24)
          .fontColor(OoxxColors.INK)
          .onClick(() => this.onOpenProfile())
      }
      .width('100%')
      .margin({ top: 18, bottom: 22 })

      Row() {
        Text('今天玩什么？')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(OoxxColors.INK)
        Blank()
        Text('更多 ›').fontSize(13).fontColor(OoxxColors.MUTED)
      }
      .width('100%')
      .margin({ bottom: 14 })

      Row() {
        HomeModeCard({ icon: 'ϟ', title: '快速对战', subtitle: '和 AI 过招', color: OoxxColors.SUNNY_SOFT, onTap: () => this.onOpenMode() })
        HomeModeCard({ icon: '♙', title: '双人同屏', subtitle: '面对面开局', color: OoxxColors.TEAL_SOFT, onTap: () => this.onStartLocal() })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 14 })
      Row() {
        HomeModeCard({ icon: '♧', title: '好友房间', subtitle: '联机对战预留', color: OoxxColors.CORAL_SOFT, onTap: () => this.onOpenRoom() })
        HomeModeCard({ icon: '♛', title: '每日挑战', subtitle: '寻找唯一解', color: OoxxColors.MINT, onTap: () => this.onOpenDaily() })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Row() {
        Column({ space: 4 }) {
          Text('今日挑战').fontSize(14).fontColor(OoxxColors.MUTED)
          Text('完成一局，保持手感').fontSize(16).fontWeight(FontWeight.Medium).fontColor(OoxxColors.INK)
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Text('去看看 ›').fontSize(14).fontColor(OoxxColors.CORAL)
      }
      .width('100%')
      .padding(16)
      .margin({ top: 18 })
      .backgroundColor(OoxxColors.WHITE)
      .borderRadius(OoxxRadius.CARD)
      .border({ width: 1, color: OoxxColors.LINE })
      .onClick(() => this.onOpenDaily())

      Blank()
      OoxxBottomNav({ selected: 'home', onHome: () => {}, onHistory: () => this.onOpenHistory(), onProfile: () => this.onOpenProfile() })
    }
    .width('100%')
    .height('100%')
    .padding({ left: OoxxSpacing.PAGE, right: OoxxSpacing.PAGE })
    .backgroundColor(OoxxColors.PAPER)
  }
}
