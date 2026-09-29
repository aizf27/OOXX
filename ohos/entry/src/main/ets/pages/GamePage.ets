import { GameKind } from '../model/AppModels';
import { OoxxRadius, OoxxSpacing, OoxxTheme } from '../theme/OoxxTheme';

@Component
struct BoardCell {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop value: string = '';
  @Prop color: string = OoxxTheme.light.INK;
  @Prop invalid: boolean = false;
  @Prop cellSize: number = 86;
  onTap: () => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Text(this.value)
      .width(this.cellSize)
      .height(this.cellSize)
      .textAlign(TextAlign.Center)
      .fontSize(this.cellSize > 70 ? 46 : 30)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.color)
      .backgroundColor(this.invalid ? '#FFCCCC' : this.theme().WHITE)
      .border({ width: 1.5, color: this.theme().INK })
      .borderRadius(OoxxRadius.CELL)
      .margin(2)
      .onClick(() => this.onTap())
  }
}

@Component
export struct GamePage {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop board: string[] = ['', '', '', '', '', '', '', '', ''];
  @Prop playerTurn: string = '轮到你了';
  @Prop isLocal: boolean = false;
  @Prop isNetwork: boolean = false;
  @Prop isLogic: boolean = false;
  @Prop kind: GameKind = GameKind.AI_3X3;
  onBack: () => void = () => {};
  onTapCell: (index: number) => void = (_: number) => {};
  onUndo: () => void = () => {};
  onSurrender: () => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  cellColor(index: number): string {
    return this.board[index] === 'O' ? this.theme().CORAL : this.theme().SKY;
  }

  cellSize(): number {
    return this.board.length === 9 ? 86 : 58;
  }

  boardSize(): number {
    return Math.floor(Math.sqrt(this.board.length));
  }

  rowIndices(row: number): number[] {
    const size = this.boardSize();
    const result: number[] = [];
    for (let i = 0; i < size; i++) {
      result.push(row * size + i);
    }
    return result;
  }

  rowRange(): number[] {
    const size = this.boardSize();
    const result: number[] = [];
    for (let i = 0; i < size; i++) {
      result.push(i);
    }
    return result;
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
    if (this.isLogic) {
      return '逻辑谜题';
    }
    return 'AI 棋手';
  }

  @Builder
  renderRow(start: number, count: number) {
    Row() {
      ForEach(this.rowIndices(Math.floor(start / count)), (index: number) => {
        BoardCell({
          value: this.board[index],
          color: this.cellColor(index),
          cellSize: this.cellSize(),
          onTap: () => this.onTapCell(index)
        })
      }, (index: number) => index.toString())
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(34).fontColor(this.theme().INK).onClick(() => this.onBack())
        Blank()
        Text('对战中').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.theme().INK)
        Blank()
        Text('⋯').fontSize(26).fontColor(this.theme().INK)
      }
      .width('100%')
      .margin({ top: 16, bottom: 14 })
      Row() {
        Column({ space: 4 }) {
          Text('O').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.theme().CORAL)
          Text(this.leftName()).fontSize(13).fontColor(this.theme().INK)
        }
        .layoutWeight(1)
        Text('0  :  0').fontSize(21).fontWeight(FontWeight.Bold).fontColor(this.theme().INK)
        Column({ space: 4 }) {
          Text('X').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.theme().SKY)
          Text(this.rightName()).fontSize(13).fontColor(this.theme().INK)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 16 })
      Text(this.playerTurn)
        .fontSize(21)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme().INK)
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .backgroundColor(this.theme().SUNNY)
        .borderRadius(OoxxRadius.BUTTON)
        .margin({ bottom: 20 })
      Column() {
        if (this.board.length === 9) {
          this.renderRow(0, 3);
          this.renderRow(3, 3);
          this.renderRow(6, 3);
        } else {
          ForEach(this.rowRange(), (row: number) => {
            this.renderRow(row * this.boardSize(), this.boardSize());
          }, (row: number) => row.toString())
        }
      }
      .padding(8)
      .backgroundColor(this.theme().BOARD)
      .borderRadius(OoxxRadius.CARD)
      .border({ width: 1, color: this.theme().LINE })
      Blank()
      Row() {
        Column() {
          Row() {
            Text('↶').fontSize(24).fontColor(this.theme().INK)
          }.width('100%').height(27).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
          Row() {
            Text('悔棋').fontSize(12).fontColor(this.theme().MUTED)
          }.width('100%').height(17).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .height(44)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.onUndo())
        Column() {
          Row() {
            Text('☺').fontSize(24).fontColor(this.theme().INK)
          }.width('100%').height(27).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
          Row() {
            Text('表情').fontSize(12).fontColor(this.theme().MUTED)
          }.width('100%').height(17).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .height(44)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        Column() {
          Row() {
            Text('⚑').fontSize(24).fontColor(this.theme().INK)
          }.width('100%').height(27).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
          Row() {
            Text('认输').fontSize(12).fontColor(this.theme().MUTED)
          }.width('100%').height(17).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .height(44)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.onSurrender())
      }
      .width('100%')
      .height(64)
      .padding({ bottom: OoxxSpacing.PAGE })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding({ left: OoxxSpacing.PAGE, right: OoxxSpacing.PAGE })
    .backgroundColor(this.theme().PAPER)
  }
}
