import { OoxxBottomNav } from '../components/OoxxBottomNav';
import { OoxxCharacter } from '../components/OoxxCharacter';
import { SettingRow } from '../components/SettingRow';
import { OoxxTopBar } from '../components/OoxxTopBar';
import { StatCard } from '../components/StatCard';
import { Settings } from '../model/AppModels';
import { OoxxRadius, OoxxSpacing, OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct ProfilePage {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop settings: Settings = new Settings();
  onBack: () => void = () => {};
  onOpenHistory: () => void = () => {};
  onSoundChanged: (enabled: boolean) => void = () => {};
  onVibrationChanged: (enabled: boolean) => void = () => {};
  onDarkModeChanged: (enabled: boolean) => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Column() {
      OoxxTopBar({ title: '我的', showBack: true, onBack: () => this.onBack(), onAction: () => {} })
        .margin({ top: 16, bottom: 18 })
      Row() {
        OoxxCharacter({ kind: 'O', charSize: 68, accent: this.theme().SKY })
        Column({ space: 5 }) {
          Text('康思').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.theme().INK)
          Text('游客身份 · guest-local').fontSize(13).fontColor(this.theme().MUTED)
          Text('金币 120').fontSize(13).fontColor(this.theme().CORAL)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 14 })
        Blank()
        Text('›').fontSize(28).fontColor(this.theme().MUTED)
      }
      .width('100%')
      .padding(14)
      .backgroundColor(this.theme().WHITE)
      .borderRadius(OoxxRadius.CARD)
      .border({ width: 1, color: this.theme().LINE })
      .margin({ bottom: 16 })
      Row({ space: 8 }) {
        StatCard({ value: '3', label: '冠 军', color: this.theme().SUNNY_SOFT })
        StatCard({ value: '12', label: '总 对 局', color: this.theme().TEAL_SOFT })
        StatCard({ value: '7', label: '连续登场', color: this.theme().MINT })
      }
      .width('100%')
      .margin({ bottom: 16 })
      Column() {
        SettingRow({
          icon: '◖',
          label: '声音',
          value: this.settings.sound ? '开启' : '关闭',
          onTap: () => this.onSoundChanged(!this.settings.sound)
        })
        SettingRow({
          icon: '⌁',
          label: '震动',
          value: this.settings.vibration ? '开启' : '关闭',
          onTap: () => this.onVibrationChanged(!this.settings.vibration)
        })
        SettingRow({
          icon: '☾',
          label: '深色模式',
          value: this.settings.darkMode ? '开启' : '关闭',
          onTap: () => this.onDarkModeChanged(!this.settings.darkMode)
        })
        SettingRow({ icon: 'ⓘ', label: '关于我们', onTap: () => {} })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .backgroundColor(this.theme().WHITE)
      .borderRadius(OoxxRadius.CARD)
      .border({ width: 1, color: this.theme().LINE })
      Blank()
      OoxxBottomNav({ selected: 'profile', onHome: () => this.onBack(), onHistory: () => this.onOpenHistory(), onProfile: () => {} })
    }
    .width('100%')
    .height('100%')
    .padding({ left: OoxxSpacing.PAGE, right: OoxxSpacing.PAGE })
    .backgroundColor(this.theme().PAPER)
  }
}
