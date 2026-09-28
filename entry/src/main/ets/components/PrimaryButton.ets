import { OoxxColors, OoxxRadius } from '../theme/OoxxTheme';

@Component
export struct PrimaryButton {
  @Prop label: string = '';
  @Prop color: string = OoxxColors.CORAL;
  onTap: () => void = () => {};

  build() {
    Button(this.label)
      .width('100%')
      .height(52)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor(OoxxColors.WHITE)
      .backgroundColor(this.color)
      .borderRadius(OoxxRadius.BUTTON)
      .border({ width: 1, color: OoxxColors.INK })
      .onClick(() => this.onTap())
  }
}
