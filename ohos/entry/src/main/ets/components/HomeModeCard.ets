import { OoxxColors, OoxxRadius } from '../theme/OoxxTheme';

@Component
export struct HomeModeCard {
  @Prop icon: string = '';
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop color: string = OoxxColors.SUNNY_SOFT;
  onTap: () => void = () => {};

  build() {
    Column({ space: 8 }) {
      Text(this.icon)
        .width(46)
        .height(46)
        .textAlign(TextAlign.Center)
        .fontSize(28)
        .fontColor(OoxxColors.INK)
        .backgroundColor(OoxxColors.WHITE)
        .borderRadius(23)
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(OoxxColors.INK)
      if (this.subtitle.length > 0) {
        Text(this.subtitle).fontSize(11).fontColor(OoxxColors.MUTED)
      }
    }
    .width('48%')
    .height(145)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.color)
    .borderRadius(OoxxRadius.CARD)
    .border({ width: 1, color: OoxxColors.LINE })
    .onClick(() => this.onTap())
  }
}
