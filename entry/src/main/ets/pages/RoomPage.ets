import { OoxxCharacter } from '../components/OoxxCharacter';
import { OoxxTopBar } from '../components/OoxxTopBar';
import { PrimaryButton } from '../components/PrimaryButton';
import { OoxxColors, OoxxRadius, OoxxSpacing } from '../theme/OoxxTheme';

@Component
export struct RoomPage {
  @State code: string = '';
  @State status: string = '';
  onBack: () => void = () => {};
  onCreate: () => void = () => {};
  onJoin: () => void = () => {};

  build() {
    Column() {
      OoxxTopBar({ title: '好友房间', showBack: true, onBack: () => this.onBack(), onAction: () => {} })
        .margin({ top: 16, bottom: 24 })
      Text('和朋友一起玩，更有趣！')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(OoxxColors.INK)
        .margin({ bottom: 18 })
      Row({ space: 38 }) {
        OoxxCharacter({ kind: 'O', charSize: 76, accent: OoxxColors.SKY, label: '康思' })
        Text('VS').fontSize(16).fontWeight(FontWeight.Bold).fontColor(OoxxColors.MUTED)
        OoxxCharacter({ kind: 'X', charSize: 76, accent: OoxxColors.CORAL, label: '好友' })
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .margin({ bottom: 28 })
      TextInput({ placeholder: '输入房间码' })
        .height(52)
        .width('100%')
        .fontSize(16)
        .fontColor(OoxxColors.INK)
        .backgroundColor(OoxxColors.WHITE)
        .borderRadius(OoxxRadius.BUTTON)
        .border({ width: 1, color: OoxxColors.LINE })
        .onChange((value: string) => this.code = value)
        .margin({ bottom: 14 })
      PrimaryButton({ label: '创建房间', color: OoxxColors.CORAL, onTap: () => { this.status = '房间功能将在跨端阶段接入'; this.onCreate(); } })
        .margin({ bottom: 12 })
      PrimaryButton({ label: '加入房间', color: OoxxColors.TEAL, onTap: () => { this.status = this.code.length === 0 ? '请先输入房间码' : '房间功能将在跨端阶段接入'; this.onJoin(); } })
      if (this.status.length > 0) {
        Text(this.status)
          .fontSize(14)
          .fontColor(OoxxColors.CORAL)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 16 })
      }
      Blank()
      Text('联网后由 WebSocket 房间接管状态，客户端只发送操作。')
        .fontSize(13)
        .fontColor(OoxxColors.MUTED)
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ bottom: OoxxSpacing.PAGE })
    }
    .width('100%')
    .height('100%')
    .padding({ left: OoxxSpacing.PAGE, right: OoxxSpacing.PAGE })
    .backgroundColor(OoxxColors.PAPER)
  }
}
