import { ModeListItem } from '../components/ModeListItem';
import { OoxxTopBar } from '../components/OoxxTopBar';
import { PrimaryButton } from '../components/PrimaryButton';
import { OoxxColors, OoxxSpacing } from '../theme/OoxxTheme';

@Component
export struct ModePage {
  onBack: () => void = () => {};
  onStartClassic: () => void = () => {};
  onStartAdvanced: () => void = () => {};
  onStartDaily: () => void = () => {};

  build() {
    Column() {
      OoxxTopBar({ title: '选择模式', showBack: true, onBack: () => this.onBack(), onAction: () => {} })
        .margin({ top: 16, bottom: 24 })
      ModeListItem({ icon: '▦', title: '经典 3×3', subtitle: '最纯粹的乐趣', color: OoxxColors.SUNNY_SOFT, onTap: () => this.onStartClassic() })
        .margin({ bottom: 12 })
      ModeListItem({ icon: '▦', title: '进阶 5×5', subtitle: '更大的挑战', color: OoxxColors.TEAL_SOFT, onTap: () => this.onStartAdvanced() })
        .margin({ bottom: 12 })
      ModeListItem({ icon: '◷', title: '限时赛', subtitle: '和时间赛跑', color: OoxxColors.MINT, onTap: () => this.onStartDaily() })
      Blank()
      Text('不同的玩法，同样的快乐！')
        .fontSize(15)
        .fontColor(OoxxColors.MUTED)
        .margin({ bottom: 18 })
      PrimaryButton({ label: '开始匹配', onTap: () => this.onStartClassic() })
        .margin({ bottom: OoxxSpacing.PAGE })
    }
    .width('100%')
    .height('100%')
    .padding({ left: OoxxSpacing.PAGE, right: OoxxSpacing.PAGE })
    .backgroundColor(OoxxColors.PAPER)
  }
}
