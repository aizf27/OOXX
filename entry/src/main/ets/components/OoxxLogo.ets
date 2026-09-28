import { OoxxColors } from '../theme/OoxxTheme';

@Component
export struct OoxxLogo {
  @Prop logoSize: number = 52;

  build() {
    Column({ space: 5 }) {
      Row({ space: 1 }) {
        Text('O').fontSize(this.logoSize).fontWeight(FontWeight.Bold).fontColor(OoxxColors.CORAL)
        Text('O').fontSize(this.logoSize).fontWeight(FontWeight.Bold).fontColor(OoxxColors.SKY)
        Text('X').fontSize(this.logoSize).fontWeight(FontWeight.Bold).fontColor(OoxxColors.INK)
        Text('X').fontSize(this.logoSize).fontWeight(FontWeight.Bold).fontColor(OoxxColors.INK)
      }
      Divider()
        .width(this.logoSize * 2.5)
        .strokeWidth(5)
        .color(OoxxColors.SUNNY)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
