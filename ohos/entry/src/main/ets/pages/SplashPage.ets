import { OoxxCharacter } from '../components/OoxxCharacter';
import { OoxxLogo } from '../components/OoxxLogo';
import { OoxxSpacing, OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct SplashPage {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  onContinue: () => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Column() {
      Blank()
      OoxxLogo({ logoSize: 64 })
      Text('康思小游戏')
        .fontSize(25)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme().INK)
        .margin({ top: 8 })
      Divider()
        .width(150)
        .strokeWidth(5)
        .color(this.theme().SUNNY)
        .margin({ top: 10 })
      Text('小小方格，装下大大快乐')
        .fontSize(16)
        .fontColor(this.theme().MUTED)
        .margin({ top: 26 })
      Blank()
      Row({ space: 26 }) {
        OoxxCharacter({ kind: 'O', charSize: 86, accent: this.theme().CORAL })
        OoxxCharacter({ kind: 'X', charSize: 86, accent: this.theme().SKY })
      }
      .margin({ bottom: 24 })
      Text('点击任意位置开始')
        .fontSize(14)
        .fontColor(this.theme().MUTED)
        .margin({ bottom: OoxxSpacing.PAGE })
    }
    .width('100%')
    .height('100%')
    .padding(OoxxSpacing.PAGE)
    .backgroundColor(this.theme().PAPER)
    .onClick(() => this.onContinue())
  }
}
