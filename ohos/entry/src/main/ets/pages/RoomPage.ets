import { OoxxCharacter } from '../components/OoxxCharacter';
import { OoxxTopBar } from '../components/OoxxTopBar';
import { PrimaryButton } from '../components/PrimaryButton';
import { NetworkRoom } from '../model/AppModels';
import { OoxxColors, OoxxRadius, OoxxSpacing } from '../theme/OoxxTheme';

@Component
export struct RoomPage {
  @Prop network: NetworkRoom = new NetworkRoom();
  @State code: string = '';
  onBack: () => void = () => {};
  onCreate: () => void = () => {};
  onJoin: (code: string) => void = () => {};

  normalizedCode(): string {
    return this.code
      .split('')
      .filter((char) => /[a-zA-Z0-9]/.test(char))
      .join('')
      .toUpperCase()
      .slice(0, 6);
  }

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

      TextInput({ placeholder: '输入 6 位房间码' })
        .height(52)
        .width('100%')
        .fontSize(16)
        .fontColor(OoxxColors.INK)
        .backgroundColor(OoxxColors.WHITE)
        .borderRadius(OoxxRadius.BUTTON)
        .border({ width: 1, color: OoxxColors.LINE })
        .onChange((value: string) => this.code = value)
        .margin({ bottom: 14 })

      PrimaryButton({ label: '创建房间', color: OoxxColors.CORAL, onTap: () => this.onCreate() })
        .margin({ bottom: 12 })
      PrimaryButton({ label: '加入房间', color: OoxxColors.TEAL, onTap: () => this.onJoin(this.normalizedCode()) })

      if (this.network.roomCode.length > 0 && this.network.waiting) {
        Text(`房间码 ${this.network.roomCode}`)
          .width('100%')
          .height(56)
          .fontSize(24)
          .fontWeight(FontWeight.Black)
          .fontColor(OoxxColors.INK)
          .textAlign(TextAlign.Center)
          .backgroundColor(OoxxColors.SOFT_GRAY)
          .borderRadius(OoxxRadius.CARD)
          .margin({ top: 16 })
      }

      if (this.network.connecting) {
        Text('连接中…')
          .fontSize(14)
          .fontColor(OoxxColors.MUTED)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 16 })
      }

      if (this.network.error !== null && this.network.error.length > 0) {
        Text(this.network.error)
          .fontSize(14)
          .fontColor(OoxxColors.DANGER)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 16 })
      } else if (this.network.statusMessage.length > 0 &&
        !(this.network.roomCode.length > 0 && this.network.waiting)) {
        Text(this.network.statusMessage)
          .fontSize(14)
          .fontColor(OoxxColors.MUTED)
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
