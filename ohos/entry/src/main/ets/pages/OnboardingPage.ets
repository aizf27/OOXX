import { BoardPreview } from '../components/BoardPreview';
import { OoxxSpacing, OoxxTheme } from '../theme/OoxxTheme';
import { PrimaryButton } from '../components/PrimaryButton';

@Component
export struct OnboardingPage {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  onStart: () => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Column() {
      Text('三分钟，来一局')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme().INK)
        .margin({ top: 42, bottom: 12 })
      Text('简单规则，随时开玩')
        .fontSize(15)
        .fontColor(this.theme().MUTED)
        .margin({ bottom: 26 })
      BoardPreview()
        .margin({ bottom: 22 })
      Text('不复杂，但总有新乐趣')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.theme().INK)
      Text('三子连线获胜，先手是 O')
        .fontSize(14)
        .fontColor(this.theme().MUTED)
        .margin({ top: 8 })
      Blank()
      PrimaryButton({ label: '开始体验', onTap: () => this.onStart() })
        .margin({ bottom: OoxxSpacing.PAGE })
    }
    .width('100%')
    .height('100%')
    .padding({ left: OoxxSpacing.PAGE, right: OoxxSpacing.PAGE })
    .backgroundColor(this.theme().PAPER)
  }
}
