import { OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct SettingRow {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop label: string = '';
  @Prop icon: string = '•';
  @Prop value: string = '';
  onTap: () => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  build() {
    Row() {
      Text(this.icon).width(30).fontSize(20).fontColor(this.theme().INK)
      Text(this.label).fontSize(16).fontColor(this.theme().INK)
      Blank()
      if (this.value.length > 0) {
        Text(this.value).fontSize(14).fontColor(this.theme().MUTED)
      } else {
        Text('›').fontSize(26).fontColor(this.theme().MUTED)
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: 4, right: 4 })
    .border({ width: { bottom: 1 }, color: this.theme().LINE })
    .onClick(() => this.onTap())
  }
}
