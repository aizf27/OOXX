import { HomeModeCard } from '../components/HomeModeCard';
import { OoxxBottomNav } from '../components/OoxxBottomNav';
import { OoxxCharacter } from '../components/OoxxCharacter';
import { OoxxRadius, OoxxSpacing, OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct HomePage {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  onOpenMode: () => void = () => {};
  onStartLocal: () => void = () => {};
  onOpenRoom: () => void = () => {};
  onOpenDaily: () => void = () => {};
  onOpenHistory: () => void = () => {};
  onOpenProfile: () => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Column() {
      Row() {
        OoxxCharacter({ kind: 'O', charSize: 52, accent: this.theme().SKY })
        Column({ space: 3 }) {
          Text('康思').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.theme().INK)
          Text('金币 120').fontSize(13).fontColor(this.theme().MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
        Blank()
        Text('⚙')
          .fontSize(24)
          .fontColor(this.theme().INK)
          .onClick(() => this.onOpenProfile())
      }
      .width('100%')
      .margin({ top: 18, bottom: 22 })

      Row() {
        Text('今天玩什么？')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme().INK)
        Blank()
        Text('更多 ›').fontSize(13).fontColor(this.theme().MUTED)
      }
      .width('100%')
      .margin({ bottom: 14 })

      Row() {
        HomeModeCard({ icon: 'ϟ', title: '快速对战', subtitle: '和 AI 过招', color: this.theme().SUNNY_SOFT, onTap: () => this.onOpenMode() })
        HomeModeCard({ icon: '♙', title: '双人同屏', subtitle: '面对面开局', color: this.theme().TEAL_SOFT, onTap: () => this.onStartLocal() })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 14 })
      Row() {
        HomeModeCard({ icon: '♧', title: '好友房间', subtitle: '联机对战', color: this.theme().CORAL_SOFT, onTap: () => this.onOpenRoom() })
        HomeModeCard({ icon: '♛', title: '每日挑战', subtitle: '寻找唯一解', color: this.theme().MINT, onTap: () => this.onOpenDaily() })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Row() {
        Column({ space: 4 }) {
          Text('今日挑战').fontSize(14).fontColor(this.theme().MUTED)
          Text('完成一局，保持手感').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.theme().INK)
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Text('去看看 ›').fontSize(14).fontColor(this.theme().CORAL)
      }
      .width('100%')
      .padding(16)
      .margin({ top: 18 })
      .backgroundColor(this.theme().WHITE)
      .borderRadius(OoxxRadius.CARD)
      .border({ width: 1, color: this.theme().LINE })
      .onClick(() => this.onOpenDaily())

      Blank()
      OoxxBottomNav({ selected: 'home', onHome: () => {}, onHistory: () => this.onOpenHistory(), onProfile: () => this.onOpenProfile() })
    }
    .width('100%')
    .height('100%')
    .padding({ left: OoxxSpacing.PAGE, right: OoxxSpacing.PAGE })
    .backgroundColor(this.theme().PAPER)
  }
}
