import { GameKind } from '../model/AppModels';
import { OoxxColors, OoxxRadius, OoxxSpacing } from '../theme/OoxxTheme';

@Component
struct BoardCell {
  @Prop value: string = '';
  @Prop color: string = OoxxColors.INK;
  @Prop cellSize: number = 86;
  onTap: () => void = () => {};

  build() {
    Text(this.value)
      .width(this.cellSize)
      .height(this.cellSize)
      .textAlign(TextAlign.Center)
      .fontSize(this.cellSize > 70 ? 46 : 30)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.color)
      .backgroundColor(OoxxColors.WHITE)
      .border({ width: 1.5, color: OoxxColors.INK })
      .borderRadius(OoxxRadius.CELL)
      .margin(2)
      .onClick(() => this.onTap())
  }
}

@Component
export struct GamePage {
  @Prop board: string[] = ['', '', '', '', '', '', '', '', ''];
  @Prop playerTurn: string = '轮到你了';
  @Prop isLocal: boolean = false;
  @Prop isNetwork: boolean = false;
  @Prop kind: GameKind = GameKind.AI_3X3;
  onBack: () => void = () => {};
  onTapCell: (index: number) => void = (_: number) => {};
  onUndo: () => void = () => {};
  onSurrender: () => void = () => {};

  cellColor(index: number): string {
    return this.board[index] === 'O' ? OoxxColors.CORAL : OoxxColors.SKY;
  }

  leftName(): string {
    if (this.isLocal) {
      return '玩家 O';
    }
    if (this.isNetwork) {
      return '康思';
    }
    return '康思';
  }

  rightName(): string {
    if (this.isLocal) {
      return '玩家 X';
    }
    if (this.isNetwork) {
      return '在线玩家';
    }
    return 'AI 棋手';
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(34).fontColor(OoxxColors.INK).onClick(() => this.onBack())
        Blank()
        Text('对战中').fontSize(20).fontWeight(FontWeight.Bold).fontColor(OoxxColors.INK)
        Blank()
        Text('⋯').fontSize(26).fontColor(OoxxColors.INK)
      }
      .width('100%')
      .margin({ top: 16, bottom: 14 })
      Row() {
        Column({ space: 4 }) {
          Text('O').fontSize(22).fontWeight(FontWeight.Bold).fontColor(OoxxColors.CORAL)
          Text(this.leftName()).fontSize(13).fontColor(OoxxColors.INK)
        }
        .layoutWeight(1)
        Text('0  :  0').fontSize(21).fontWeight(FontWeight.Bold).fontColor(OoxxColors.INK)
        Column({ space: 4 }) {
          Text('X').fontSize(22).fontWeight(FontWeight.Bold).fontColor(OoxxColors.SKY)
          Text(this.rightName()).fontSize(13).fontColor(OoxxColors.INK)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 16 })
      Text(this.playerTurn)
        .fontSize(21)
        .fontWeight(FontWeight.Bold)
        .fontColor(OoxxColors.INK)
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .backgroundColor(OoxxColors.SUNNY)
        .borderRadius(OoxxRadius.BUTTON)
        .margin({ bottom: 20 })
      Column() {
        if (this.board.length === 9) {
          Row() {
            BoardCell({ value: this.board[0], color: this.cellColor(0), onTap: () => this.onTapCell(0) })
            BoardCell({ value: this.board[1], color: this.cellColor(1), onTap: () => this.onTapCell(1) })
            BoardCell({ value: this.board[2], color: this.cellColor(2), onTap: () => this.onTapCell(2) })
          }
          Row() {
            BoardCell({ value: this.board[3], color: this.cellColor(3), onTap: () => this.onTapCell(3) })
            BoardCell({ value: this.board[4], color: this.cellColor(4), onTap: () => this.onTapCell(4) })
            BoardCell({ value: this.board[5], color: this.cellColor(5), onTap: () => this.onTapCell(5) })
          }
          Row() {
            BoardCell({ value: this.board[6], color: this.cellColor(6), onTap: () => this.onTapCell(6) })
            BoardCell({ value: this.board[7], color: this.cellColor(7), onTap: () => this.onTapCell(7) })
            BoardCell({ value: this.board[8], color: this.cellColor(8), onTap: () => this.onTapCell(8) })
          }
        } else {
          Row() {
            BoardCell({ value: this.board[0], cellSize: 58, color: this.cellColor(0), onTap: () => this.onTapCell(0) })
            BoardCell({ value: this.board[1], cellSize: 58, color: this.cellColor(1), onTap: () => this.onTapCell(1) })
            BoardCell({ value: this.board[2], cellSize: 58, color: this.cellColor(2), onTap: () => this.onTapCell(2) })
            BoardCell({ value: this.board[3], cellSize: 58, color: this.cellColor(3), onTap: () => this.onTapCell(3) })
            BoardCell({ value: this.board[4], cellSize: 58, color: this.cellColor(4), onTap: () => this.onTapCell(4) })
          }
          Row() {
            BoardCell({ value: this.board[5], cellSize: 58, color: this.cellColor(5), onTap: () => this.onTapCell(5) })
            BoardCell({ value: this.board[6], cellSize: 58, color: this.cellColor(6), onTap: () => this.onTapCell(6) })
            BoardCell({ value: this.board[7], cellSize: 58, color: this.cellColor(7), onTap: () => this.onTapCell(7) })
            BoardCell({ value: this.board[8], cellSize: 58, color: this.cellColor(8), onTap: () => this.onTapCell(8) })
            BoardCell({ value: this.board[9], cellSize: 58, color: this.cellColor(9), onTap: () => this.onTapCell(9) })
          }
          Row() {
            BoardCell({ value: this.board[10], cellSize: 58, color: this.cellColor(10), onTap: () => this.onTapCell(10) })
            BoardCell({ value: this.board[11], cellSize: 58, color: this.cellColor(11), onTap: () => this.onTapCell(11) })
            BoardCell({ value: this.board[12], cellSize: 58, color: this.cellColor(12), onTap: () => this.onTapCell(12) })
            BoardCell({ value: this.board[13], cellSize: 58, color: this.cellColor(13), onTap: () => this.onTapCell(13) })
            BoardCell({ value: this.board[14], cellSize: 58, color: this.cellColor(14), onTap: () => this.onTapCell(14) })
          }
          Row() {
            BoardCell({ value: this.board[15], cellSize: 58, color: this.cellColor(15), onTap: () => this.onTapCell(15) })
            BoardCell({ value: this.board[16], cellSize: 58, color: this.cellColor(16), onTap: () => this.onTapCell(16) })
            BoardCell({ value: this.board[17], cellSize: 58, color: this.cellColor(17), onTap: () => this.onTapCell(17) })
            BoardCell({ value: this.board[18], cellSize: 58, color: this.cellColor(18), onTap: () => this.onTapCell(18) })
            BoardCell({ value: this.board[19], cellSize: 58, color: this.cellColor(19), onTap: () => this.onTapCell(19) })
          }
          Row() {
            BoardCell({ value: this.board[20], cellSize: 58, color: this.cellColor(20), onTap: () => this.onTapCell(20) })
            BoardCell({ value: this.board[21], cellSize: 58, color: this.cellColor(21), onTap: () => this.onTapCell(21) })
            BoardCell({ value: this.board[22], cellSize: 58, color: this.cellColor(22), onTap: () => this.onTapCell(22) })
            BoardCell({ value: this.board[23], cellSize: 58, color: this.cellColor(23), onTap: () => this.onTapCell(23) })
            BoardCell({ value: this.board[24], cellSize: 58, color: this.cellColor(24), onTap: () => this.onTapCell(24) })
          }
        }
      }
      .padding(8)
      .backgroundColor(OoxxColors.BOARD)
      .borderRadius(OoxxRadius.CARD)
      .border({ width: 1, color: OoxxColors.LINE })
      Blank()
      Row() {
        Column({ space: 3 }) {
          Text('↶').fontSize(24).fontColor(OoxxColors.INK)
          Text('悔棋').fontSize(12).fontColor(OoxxColors.MUTED)
        }.layoutWeight(1).onClick(() => this.onUndo())
        Column({ space: 3 }) {
          Text('☺').fontSize(24).fontColor(OoxxColors.INK)
          Text('表情').fontSize(12).fontColor(OoxxColors.MUTED)
        }.layoutWeight(1)
        Column({ space: 3 }) {
          Text('⚑').fontSize(24).fontColor(OoxxColors.INK)
          Text('认输').fontSize(12).fontColor(OoxxColors.MUTED)
        }.layoutWeight(1).onClick(() => this.onSurrender())
      }
      .width('100%')
      .height(64)
      .padding({ bottom: OoxxSpacing.PAGE })
    }
    .width('100%')
    .height('100%')
    .padding({ left: OoxxSpacing.PAGE, right: OoxxSpacing.PAGE })
    .backgroundColor(OoxxColors.PAPER)
  }
}
