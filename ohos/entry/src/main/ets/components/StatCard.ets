import { OoxxColors, OoxxRadius } from '../theme/OoxxTheme';

@Component
export struct StatCard {
  @Prop value: string = '';
  @Prop label: string = '';
  @Prop color: string = OoxxColors.SUNNY_SOFT;

  build() {
    Column({ space: 5 }) {
      Text(this.value).fontSize(27).fontWeight(FontWeight.Bold).fontColor(OoxxColors.INK)
      Text(this.label).fontSize(12).fontColor(OoxxColors.MUTED)
    }
    .layoutWeight(1)
    .height(78)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.color)
    .borderRadius(OoxxRadius.CARD)
    .border({ width: 1, color: OoxxColors.LINE })
  }
}
