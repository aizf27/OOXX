import { OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct OoxxCharacter {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop kind: string = 'O';
  @Prop charSize: number = 74;
  @Prop accent: string = OoxxTheme.light.CORAL;
  @Prop label: string = '';

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Column({ space: 4 }) {
      Stack() {
        Text(this.kind)
          .width(this.charSize)
          .height(this.charSize)
          .textAlign(TextAlign.Center)
          .fontSize(this.charSize * 0.52)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.kind === 'O' ? this.theme().INK : this.theme().WHITE)
          .backgroundColor(this.accent)
          .borderRadius(this.charSize / 2)
          .border({ width: 3, color: this.theme().INK })
        if (this.kind === 'O') {
          Text('•  •')
            .fontSize(this.charSize * 0.18)
            .fontColor(this.theme().INK)
            .margin({ top: -this.charSize * 0.08 })
        }
      }
      if (this.label.length > 0) {
        Text(this.label)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.theme().INK)
      }
    }
  }
}
