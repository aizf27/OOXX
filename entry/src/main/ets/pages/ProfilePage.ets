import { OoxxBottomNav } from '../components/OoxxBottomNav';
import { OoxxCharacter } from '../components/OoxxCharacter';
import { SettingRow } from '../components/SettingRow';
import { OoxxTopBar } from '../components/OoxxTopBar';
import { StatCard } from '../components/StatCard';
import { OoxxColors, OoxxRadius, OoxxSpacing } from '../theme/OoxxTheme';

@Component
export struct ProfilePage {
  onBack: () => void = () => {};
  onOpenHistory: () => void = () => {};

  build() {
    Column() {
      OoxxTopBar({ title: '我的', showBack: true, onBack: () => this.onBack(), onAction: () => {} })
        .margin({ top: 16, bottom: 18 })
      Row() {
        OoxxCharacter({ kind: 'O', charSize: 68, accent: OoxxColors.SKY })
        Column({ space: 5 }) {
          Text('康思').fontSize(22).fontWeight(FontWeight.Bold).fontColor(OoxxColors.INK)
          Text('游客身份 · guest-local').fontSize(13).fontColor(OoxxColors.MUTED)
          Text('金币 120').fontSize(13).fontColor(OoxxColors.CORAL)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 14 })
        Blank()
        Text('›').fontSize(28).fontColor(OoxxColors.MUTED)
      }
      .width('100%')
      .padding(14)
      .backgroundColor(OoxxColors.WHITE)
      .borderRadius(OoxxRadius.CARD)
      .border({ width: 1, color: OoxxColors.LINE })
      .margin({ bottom: 16 })
      Row({ space: 8 }) {
        StatCard({ value: '3', label: '冠 军', color: OoxxColors.SUNNY_SOFT })
        StatCard({ value: '12', label: '总 对 局', color: OoxxColors.TEAL_SOFT })
        StatCard({ value: '7', label: '连续登场', color: OoxxColors.MINT })
      }
      .width('100%')
      .margin({ bottom: 16 })
      Column() {
        SettingRow({ icon: '◖', label: '声音', value: '开启', onTap: () => {} })
        SettingRow({ icon: '⌁', label: '震动', value: '开启', onTap: () => {} })
        SettingRow({ icon: '☾', label: '深色模式', value: '关闭', onTap: () => {} })
        SettingRow({ icon: 'ⓘ', label: '关于我们', onTap: () => {} })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .backgroundColor(OoxxColors.WHITE)
      .borderRadius(OoxxRadius.CARD)
      .border({ width: 1, color: OoxxColors.LINE })
      Blank()
      OoxxBottomNav({ selected: 'profile', onHome: () => this.onBack(), onHistory: () => this.onOpenHistory(), onProfile: () => {} })
    }
    .width('100%')
    .height('100%')
    .padding({ left: OoxxSpacing.PAGE, right: OoxxSpacing.PAGE })
    .backgroundColor(OoxxColors.PAPER)
  }
}
