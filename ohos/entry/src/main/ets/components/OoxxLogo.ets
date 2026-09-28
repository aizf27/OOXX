import { OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct OoxxLogo {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop logoSize: number = 52;

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Column({ space: 5 }) {
      Row({ space: 1 }) {
        Text('O').fontSize(this.logoSize).fontWeight(FontWeight.Bold).fontColor(this.theme().CORAL)
        Text('O').fontSize(this.logoSize).fontWeight(FontWeight.Bold).fontColor(this.theme().SKY)
        Text('X').fontSize(this.logoSize).fontWeight(FontWeight.Bold).fontColor(this.theme().INK)
        Text('X').fontSize(this.logoSize).fontWeight(FontWeight.Bold).fontColor(this.theme().INK)
      }
      Divider()
        .width(this.logoSize * 2.5)
        .strokeWidth(5)
        .color(this.theme().SUNNY)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
