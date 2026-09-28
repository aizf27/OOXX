import { OoxxRadius, OoxxTheme } from '../theme/OoxxTheme';

@Component
struct PreviewCell {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop mark: string = '';
  @Prop color: string = OoxxTheme.light.INK;

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Text(this.mark)
      .width(62)
      .height(62)
      .textAlign(TextAlign.Center)
      .fontSize(35)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.color)
      .backgroundColor(this.theme().WHITE)
      .border({ width: 1.5, color: this.theme().INK })
      .borderRadius(OoxxRadius.CELL)
  }
}

@Component
export struct BoardPreview {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Column({ space: 5 }) {
      Row({ space: 5 }) {
        PreviewCell({ mark: 'O', color: this.theme().CORAL })
        PreviewCell()
        PreviewCell({ mark: 'X', color: this.theme().SKY })
      }
      Row({ space: 5 }) {
        PreviewCell()
        PreviewCell({ mark: 'O', color: this.theme().CORAL })
        PreviewCell()
      }
      Row({ space: 5 }) {
        PreviewCell({ mark: 'X', color: this.theme().SKY })
        PreviewCell()
        PreviewCell({ mark: 'O', color: this.theme().CORAL })
      }
    }
    .padding(10)
    .backgroundColor(this.theme().BOARD)
    .borderRadius(OoxxRadius.CARD)
    .border({ width: 1.5, color: this.theme().INK })
  }
}
