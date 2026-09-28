import { ModeListItem } from '../components/ModeListItem';
import { OoxxTopBar } from '../components/OoxxTopBar';
import { PrimaryButton } from '../components/PrimaryButton';
import { OoxxSpacing, OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct ModePage {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  onBack: () => void = () => {};
  onStartClassic: () => void = () => {};
  onStartAdvanced: () => void = () => {};
  onStartDaily: () => void = () => {};
  onStartLogic: () => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Column() {
      OoxxTopBar({ title: '选择模式', showBack: true, onBack: () => this.onBack(), onAction: () => {} })
        .margin({ top: 16, bottom: 24 })
      ModeListItem({ icon: '▦', title: '经典 3×3', subtitle: '最纯粹的乐趣', color: this.theme().SUNNY_SOFT, onTap: () => this.onStartClassic() })
        .margin({ bottom: 12 })
      ModeListItem({ icon: '▦', title: '进阶 5×5', subtitle: '更大的挑战', color: this.theme().TEAL_SOFT, onTap: () => this.onStartAdvanced() })
        .margin({ bottom: 12 })
      ModeListItem({ icon: '◫', title: '逻辑 6×6', subtitle: '每行每列都刚好', color: this.theme().MINT, onTap: () => this.onStartLogic() })
        .margin({ bottom: 12 })
      ModeListItem({ icon: '◷', title: '限时赛', subtitle: '和时间赛跑', color: this.theme().CORAL_SOFT, onTap: () => this.onStartDaily() })
      Blank()
      Text('不同的玩法，同样的快乐！')
        .fontSize(15)
        .fontColor(this.theme().MUTED)
        .margin({ bottom: 18 })
      PrimaryButton({ label: '开始匹配', onTap: () => this.onStartClassic() })
        .margin({ bottom: OoxxSpacing.PAGE })
    }
    .width('100%')
    .height('100%')
    .padding({ left: OoxxSpacing.PAGE, right: OoxxSpacing.PAGE })
    .backgroundColor(this.theme().PAPER)
  }
}
