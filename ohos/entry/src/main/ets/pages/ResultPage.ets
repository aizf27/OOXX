import { OoxxCharacter } from '../components/OoxxCharacter';
import { PrimaryButton } from '../components/PrimaryButton';
import { MatchResult } from '../model/AppModels';
import { OoxxRadius, OoxxSpacing, OoxxTheme } from '../theme/OoxxTheme';

@Component
export struct ResultPage {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop result: MatchResult | null = null;
  @Prop moves: number = 0;
  @Prop mode: string = '经典 3×3';
  onReplay: () => void = () => {};
  onHome: () => void = () => {};

  theme(): OoxxTheme {
    return OoxxTheme.current(this.isDarkMode);
  }

  title(): string {
    if (this.result === MatchResult.WIN) {
      return '你赢了！';
    }
    if (this.result === MatchResult.DRAW) {
      return '平局！';
    }
    return '再接再厉！';
  }

  resultColor(): string {
    return this.result === MatchResult.WIN ? this.theme().CORAL : this.result === MatchResult.DRAW ? this.theme().SKY : this.theme().MUTED;
  }

  build() {
    Column() {
      Row() {
        Text('·  ·  ·  ·  ·').fontSize(26).fontColor(this.theme().SUNNY)
      }
      .margin({ top: 32, bottom: 12 })
      Text(this.title()).fontSize(40).fontWeight(FontWeight.Bold).fontColor(this.resultColor())
      Text(this.result === MatchResult.WIN ? '这一手很漂亮' : '下一局还有机会')
        .fontSize(17)
        .fontColor(this.theme().MUTED)
        .margin({ top: 10, bottom: 22 })
      OoxxCharacter({ kind: 'O', charSize: 100, accent: this.result === MatchResult.WIN ? this.theme().CORAL : this.theme().SKY })
        .margin({ bottom: 22 })
      Row({ space: 8 }) {
        this.infoCard('--', '本局用时')
        this.infoCard(this.moves.toString(), '落子步数')
        this.infoCard(this.mode, '对战模式')
      }
      .width('100%')
      .margin({ bottom: 24 })
      PrimaryButton({ label: '再来一局', onTap: () => this.onReplay() }).margin({ bottom: 12 })
      PrimaryButton({ label: '返回首页', color: this.theme().TEAL, onTap: () => this.onHome() })
      Blank()
    }
    .width('100%')
    .height('100%')
    .padding({ left: OoxxSpacing.PAGE, right: OoxxSpacing.PAGE })
    .backgroundColor(this.theme().PAPER)
  }

  @Builder
  infoCard(value: string, label: string) {
    Column({ space: 4 }) {
      Text(value).fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.theme().INK)
      Text(label).fontSize(11).fontColor(this.theme().MUTED)
    }
    .layoutWeight(1)
    .height(62)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.theme().WHITE)
    .borderRadius(OoxxRadius.CARD)
    .border({ width: 1, color: this.theme().LINE })
  }
}
