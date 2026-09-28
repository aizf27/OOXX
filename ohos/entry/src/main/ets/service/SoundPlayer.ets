import { audio } from '@kit.AudioKit';

export class SoundPlayer {
  private enabled: boolean = true;
  private tonePlayer: audio.TonePlayer | null = null;

  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }

  beep(): void {
    if (!this.enabled) {
      return;
    }
    try {
      if (this.tonePlayer === null) {
        this.tonePlayer = audio.createTonePlayer(audio.StreamUsage.STREAM_USAGE_MEDIA);
      }
      this.tonePlayer.start(1000, 120);
    } catch {
      // ignore audio errors
    }
  }

  release(): void {
    try {
      this.tonePlayer?.stop();
      this.tonePlayer?.release();
    } catch {
      // ignore
    }
    this.tonePlayer = null;
  }
}
