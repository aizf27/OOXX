import { OoxxRadius, OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct ModeListItem {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop icon: string = '▦';
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop color: string = OoxxTheme.light.WHITE;
  onTap: () => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Row() {
      Text(this.icon)
        .width(48)
        .height(48)
        .textAlign(TextAlign.Center)
        .fontSize(27)
        .fontColor(this.theme().SKY)
        .backgroundColor(this.theme().WHITE)
        .borderRadius(12)
      Column({ space: 4 }) {
        Text(this.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.theme().INK)
        Text(this.subtitle).fontSize(13).fontColor(this.theme().MUTED)
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      Blank()
      Text('›').fontSize(30).fontColor(this.theme().INK)
    }
    .width('100%')
    .height(82)
    .padding({ left: 14, right: 14 })
    .backgroundColor(this.color)
    .borderRadius(OoxxRadius.CARD)
    .border({ width: 1, color: this.theme().LINE })
    .onClick(() => this.onTap())
  }
}
