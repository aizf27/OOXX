import { OoxxColors } from '../theme/OoxxTheme';

@Component
export struct SettingRow {
  @Prop label: string = '';
  @Prop icon: string = '•';
  @Prop value: string = '';
  onTap: () => void = () => {};

  build() {
    Row() {
      Text(this.icon).width(30).fontSize(20).fontColor(OoxxColors.INK)
      Text(this.label).fontSize(16).fontColor(OoxxColors.INK)
      Blank()
      if (this.value.length > 0) {
        Text(this.value).fontSize(14).fontColor(OoxxColors.MUTED)
      } else {
        Text('›').fontSize(26).fontColor(OoxxColors.MUTED)
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: 4, right: 4 })
    .border({ width: { bottom: 1 }, color: OoxxColors.LINE })
    .onClick(() => this.onTap())
  }
}
