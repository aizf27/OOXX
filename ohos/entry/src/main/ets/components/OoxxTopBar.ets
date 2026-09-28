import { OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct OoxxTopBar {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop title: string = '';
  @Prop showBack: boolean = false;
  @Prop actionIcon: string = '';
  onBack: () => void = () => {};
  onAction: () => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Row() {
      if (this.showBack) {
        Text('‹')
          .width(32)
          .fontSize(34)
          .fontColor(this.theme().INK)
          .onClick(() => this.onBack())
      } else {
        Text('').width(32)
      }
      Blank()
      Text(this.title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme().INK)
      Blank()
      if (this.actionIcon.length > 0) {
        Text(this.actionIcon)
          .width(32)
          .fontSize(24)
          .textAlign(TextAlign.Center)
          .fontColor(this.theme().INK)
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
