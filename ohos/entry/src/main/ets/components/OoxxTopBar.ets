import { OoxxColors } from '../theme/OoxxTheme';

@Component
export struct OoxxTopBar {
  @Prop title: string = '';
  @Prop showBack: boolean = false;
  @Prop actionIcon: string = '';
  onBack: () => void = () => {};
  onAction: () => void = () => {};

  build() {
    Row() {
      if (this.showBack) {
        Text('‹')
          .width(32)
          .fontSize(34)
          .fontColor(OoxxColors.INK)
          .onClick(() => this.onBack())
      } else {
        Text('').width(32)
      }
      Blank()
      Text(this.title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(OoxxColors.INK)
      Blank()
      if (this.actionIcon.length > 0) {
        Text(this.actionIcon)
          .width(32)
          .fontSize(24)
          .textAlign(TextAlign.Center)
          .fontColor(OoxxColors.INK)
          .onClick(() => this.onAction())
      } else {
        Text('').width(32)
      }
    }
    .width('100%')
    .height(42)
    .alignItems(VerticalAlign.Center)
  }
}
