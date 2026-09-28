import { OoxxRadius, OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct HomeModeCard {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop icon: string = '';
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop color: string = OoxxTheme.light.SUNNY_SOFT;
  onTap: () => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Column({ space: 8 }) {
      Text(this.icon)
        .width(46)
        .height(46)
        .textAlign(TextAlign.Center)
        .fontSize(28)
        .fontColor(this.theme().INK)
        .backgroundColor(this.theme().WHITE)
        .borderRadius(23)
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme().INK)
      if (this.subtitle.length > 0) {
        Text(this.subtitle).fontSize(11).fontColor(this.theme().MUTED)
      }
    }
    .width('48%')
    .height(145)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.color)
    .borderRadius(OoxxRadius.CARD)
    .border({ width: 1, color: this.theme().LINE })
    .onClick(() => this.onTap())
  }
}
