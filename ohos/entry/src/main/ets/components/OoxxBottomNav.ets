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
      Column({ space: 3 }) {
        Text('⌂').fontSize(25).fontColor(this.itemColor('home'))
        Text('首页').fontSize(12).fontColor(this.itemColor('home'))
      }.layoutWeight(1).onClick(() => this.onHome())
      Column({ space: 3 }) {
        Text('▣').fontSize(22).fontColor(this.itemColor('history'))
        Text('战绩').fontSize(12).fontColor(this.itemColor('history'))
      }.layoutWeight(1).onClick(() => this.onHistory())
      Column({ space: 3 }) {
        Text('♙').fontSize(23).fontColor(this.itemColor('profile'))
        Text('我的').fontSize(12).fontColor(this.itemColor('profile'))
      }.layoutWeight(1).onClick(() => this.onProfile())
    }
    .width('100%')
    .height(66)
    .padding({ top: 8 })
    .backgroundColor(this.theme().PAPER)
    .border({ width: { top: 1 }, color: this.theme().LINE })
    .borderRadius(OoxxRadius.CARD)
  }
}
