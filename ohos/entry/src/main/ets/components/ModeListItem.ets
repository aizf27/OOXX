import { OoxxColors, OoxxRadius } from '../theme/OoxxTheme';

@Component
export struct ModeListItem {
  @Prop icon: string = '▦';
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop color: string = OoxxColors.WHITE;
  onTap: () => void = () => {};

  build() {
    Row() {
      Text(this.icon)
        .width(48)
        .height(48)
        .textAlign(TextAlign.Center)
        .fontSize(27)
        .fontColor(OoxxColors.SKY)
        .backgroundColor(OoxxColors.WHITE)
        .borderRadius(12)
      Column({ space: 4 }) {
        Text(this.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor(OoxxColors.INK)
        Text(this.subtitle).fontSize(13).fontColor(OoxxColors.MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      Blank()
      Text('›').fontSize(30).fontColor(OoxxColors.INK)
    }
    .width('100%')
    .height(82)
    .padding({ left: 14, right: 14 })
    .backgroundColor(this.color)
    .borderRadius(OoxxRadius.CARD)
    .border({ width: 1, color: OoxxColors.LINE })
    .onClick(() => this.onTap())
  }
}
