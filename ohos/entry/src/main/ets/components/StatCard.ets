import { OoxxRadius, OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct StatCard {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop value: string = '';
  @Prop label: string = '';
  @Prop color: string = OoxxTheme.light.SUNNY_SOFT;

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Column({ space: 5 }) {
      Text(this.value).fontSize(27).fontWeight(FontWeight.Bold).fontColor(this.theme().INK)
      Text(this.label).fontSize(12).fontColor(this.theme().MUTED)
    }
    .layoutWeight(1)
    .height(78)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.color)
    .borderRadius(OoxxRadius.CARD)
    .border({ width: 1, color: this.theme().LINE })
  }
}
