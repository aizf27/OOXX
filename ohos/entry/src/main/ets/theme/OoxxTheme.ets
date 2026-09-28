export class OoxxTheme {
  static current(isDark: boolean): OoxxTheme {
    return isDark ? OoxxTheme.dark : OoxxTheme.light;
  }

  static readonly light = new OoxxTheme(
    '#FFFDF6',
    '#262522',
    '#77716A',
    '#D9D2C6',
    '#FF765E',
    '#FFC8BC',
    '#45BFC2',
    '#A9E1F6',
    '#FFD657',
    '#FFE590',
    '#3E9DDB',
    '#AEE5CD',
    '#FFFFFF',
    '#FFF9E9',
    '#E95D56',
    '#F0EEE8'
  );

  static readonly dark = new OoxxTheme(
    '#201F1C',
    '#ECE8DF',
    '#A8A39A',
    '#4A4843',
    '#FF8A7A',
    '#5C3A36',
    '#5ED1D4',
    '#2A5557',
    '#FFE066',
    '#5A4F2E',
    '#7AC4FF',
    '#3A5A4A',
    '#2C2B27',
    '#2A2925',
    '#E96B60',
    '#3A3935'
  );

  readonly PAPER: string;
  readonly INK: string;
  readonly MUTED: string;
  readonly LINE: string;
  readonly CORAL: string;
  readonly CORAL_SOFT: string;
  readonly TEAL: string;
  readonly TEAL_SOFT: string;
  readonly SUNNY: string;
  readonly SUNNY_SOFT: string;
  readonly SKY: string;
  readonly MINT: string;
  readonly WHITE: string;
  readonly BOARD: string;
  readonly DANGER: string;
  readonly SOFT_GRAY: string;

  constructor(paper: string, ink: string, muted: string, line: string,
    coral: string, coralSoft: string, teal: string, tealSoft: string,
    sunny: string, sunnySoft: string, sky: string, mint: string,
    white: string, board: string, danger: string, softGray: string) {
    this.PAPER = paper;
    this.INK = ink;
    this.MUTED = muted;
    this.LINE = line;
    this.CORAL = coral;
    this.CORAL_SOFT = coralSoft;
    this.TEAL = teal;
    this.TEAL_SOFT = tealSoft;
    this.SUNNY = sunny;
    this.SUNNY_SOFT = sunnySoft;
    this.SKY = sky;
    this.MINT = mint;
    this.WHITE = white;
    this.BOARD = board;
    this.DANGER = danger;
    this.SOFT_GRAY = softGray;
  }
}

// Keep old static colors for compatibility with existing components.
export class OoxxColors {
  static readonly PAPER: string = OoxxTheme.light.PAPER;
  static readonly INK: string = OoxxTheme.light.INK;
  static readonly MUTED: string = OoxxTheme.light.MUTED;
  static readonly LINE: string = OoxxTheme.light.LINE;
  static readonly CORAL: string = OoxxTheme.light.CORAL;
  static readonly CORAL_SOFT: string = OoxxTheme.light.CORAL_SOFT;
  static readonly TEAL: string = OoxxTheme.light.TEAL;
  static readonly TEAL_SOFT: string = OoxxTheme.light.TEAL_SOFT;
  static readonly SUNNY: string = OoxxTheme.light.SUNNY;
  static readonly SUNNY_SOFT: string = OoxxTheme.light.SUNNY_SOFT;
  static readonly SKY: string = OoxxTheme.light.SKY;
  static readonly MINT: string = OoxxTheme.light.MINT;
  static readonly WHITE: string = OoxxTheme.light.WHITE;
  static readonly BOARD: string = OoxxTheme.light.BOARD;
  static readonly DANGER: string = OoxxTheme.light.DANGER;
  static readonly SOFT_GRAY: string = OoxxTheme.light.SOFT_GRAY;
}

export class OoxxSpacing {
  static readonly PAGE: number = 20;
  static readonly SECTION: number = 18;
  static readonly CARD: number = 14;
  static readonly SMALL: number = 8;
  static readonly TINY: number = 4;
}

export class OoxxRadius {
  static readonly BUTTON: number = 18;
  static readonly CARD: number = 16;
  static readonly CELL: number = 8;
  static readonly PILL: number = 24;
}

export class OoxxStroke {
  static readonly HAIRLINE: number = 1;
  static readonly EMPHASIS: number = 2;
}
