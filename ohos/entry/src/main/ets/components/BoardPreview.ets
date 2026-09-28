import { OoxxColors, OoxxRadius } from '../theme/OoxxTheme';

@Component
struct PreviewCell {
  @Prop mark: string = '';
  @Prop color: string = OoxxColors.INK;

  build() {
    Text(this.mark)
      .width(62)
      .height(62)
      .textAlign(TextAlign.Center)
      .fontSize(35)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.color)
      .backgroundColor(OoxxColors.WHITE)
      .border({ width: 1.5, color: OoxxColors.INK })
      .borderRadius(OoxxRadius.CELL)
  }
}

@Component
export struct BoardPreview {
  build() {
    Column({ space: 5 }) {
      Row({ space: 5 }) {
        PreviewCell({ mark: 'O', color: OoxxColors.CORAL })
        PreviewCell()
        PreviewCell({ mark: 'X', color: OoxxColors.SKY })
      }
      Row({ space: 5 }) {
        PreviewCell()
        PreviewCell({ mark: 'O', color: OoxxColors.CORAL })
        PreviewCell()
      }
      Row({ space: 5 }) {
        PreviewCell({ mark: 'X', color: OoxxColors.SKY })
        PreviewCell()
        PreviewCell({ mark: 'O', color: OoxxColors.CORAL })
      }
    }
    .padding(10)
    .backgroundColor(OoxxColors.BOARD)
    .borderRadius(OoxxRadius.CARD)
    .border({ width: 1.5, color: OoxxColors.INK })
  }
}
