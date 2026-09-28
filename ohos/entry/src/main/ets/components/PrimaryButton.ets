import { OoxxRadius, OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct PrimaryButton {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop label: string = '';
  @Prop color: string = OoxxTheme.light.CORAL;
  onTap: () => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Button(this.label)
      .width('100%')
      .height(52)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.theme().WHITE)
      .backgroundColor(this.color)
      .borderRadius(OoxxRadius.BUTTON)
      .border({ width: 1, color: this.theme().INK })
      .onClick(() => this.onTap())
  }
}
