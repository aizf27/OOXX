import { OoxxColors } from '../theme/OoxxTheme';

@Component
export struct OoxxCharacter {
  @Prop kind: string = 'O';
  @Prop charSize: number = 74;
  @Prop accent: string = OoxxColors.CORAL;
  @Prop label: string = '';

  build() {
    Column({ space: 4 }) {
      Stack() {
        Text(this.kind)
          .width(this.charSize)
          .height(this.charSize)
          .textAlign(TextAlign.Center)
          .fontSize(this.charSize * 0.52)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.kind === 'O' ? OoxxColors.INK : OoxxColors.WHITE)
          .backgroundColor(this.accent)
          .borderRadius(this.charSize / 2)
          .border({ width: 3, color: OoxxColors.INK })
        if (this.kind === 'O') {
          Text('•  •')
            .fontSize(this.charSize * 0.18)
            .fontColor(OoxxColors.INK)
            .margin({ top: -this.charSize * 0.08 })
        }
      }
      if (this.label.length > 0) {
        Text(this.label)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(OoxxColors.INK)
      }
    }
  }
}
