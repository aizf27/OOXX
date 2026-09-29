import { OoxxRadius, OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct OoxxBottomNav {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop selected: string = 'home';
  onHome: () => void = () => {};
  onHistory: () => void = () => {};
  onProfile: () => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  itemColor(key: string): string {
    return this.selected === key ? this.theme().CORAL : this.theme().MUTED;
  }

  build() {
    Row() {
      Column() {
        Row() {
          Text('⌂').fontSize(25).fontColor(this.itemColor('home'))
        }.width('100%').height(30).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
        Row() {
          Text('首页').fontSize(12).fontColor(this.itemColor('home'))
        }.width('100%').height(18).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .height(50)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.onHome())
      Column() {
        Row() {
          Text('▣').fontSize(22).fontColor(this.itemColor('history'))
        }.width('100%').height(30).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
        Row() {
          Text('战绩').fontSize(12).fontColor(this.itemColor('history'))
        }.width('100%').height(18).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .height(50)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.onHistory())
      Column() {
        Row() {
          Text('♙').fontSize(23).fontColor(this.itemColor('profile'))
        }.width('100%').height(30).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
        Row() {
          Text('我的').fontSize(12).fontColor(this.itemColor('profile'))
        }.width('100%').height(18).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .height(50)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.onProfile())
    }
    .width('100%')
    .height(66)
    .padding({ top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.theme().PAPER)
    .border({ width: { top: 1 }, color: this.theme().LINE })
    .borderRadius(OoxxRadius.CARD)
  }
}
