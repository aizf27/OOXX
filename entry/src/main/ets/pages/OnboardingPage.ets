import { BoardPreview } from '../components/BoardPreview';
import { OoxxColors, OoxxSpacing } from '../theme/OoxxTheme';
import { PrimaryButton } from '../components/PrimaryButton';

@Component
export struct OnboardingPage {
  onStart: () => void = () => {};

  build() {
    Column() {
      Text('三分钟，来一局')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor(OoxxColors.INK)
        .margin({ top: 42, bottom: 12 })
      Text('简单规则，随时开玩')
        .fontSize(15)
        .fontColor(OoxxColors.MUTED)
        .margin({ bottom: 26 })
      BoardPreview()
        .margin({ bottom: 22 })
      Text('不复杂，但总有新乐趣')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(OoxxColors.INK)
      Text('三子连线获胜，先手是 O')
        .fontSize(14)
        .fontColor(OoxxColors.MUTED)
        .margin({ top: 8 })
      Blank()
      PrimaryButton({ label: '开始体验', onTap: () => this.onStart() })
        .margin({ bottom: OoxxSpacing.PAGE })
    }
    .width('100%')
    .height('100%')
    .padding({ left: OoxxSpacing.PAGE, right: OoxxSpacing.PAGE })
    .backgroundColor(OoxxColors.PAPER)
  }
}
