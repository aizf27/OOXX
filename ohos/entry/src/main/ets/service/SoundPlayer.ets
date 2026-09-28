import { audio } from '@kit.AudioKit';

export class SoundPlayer {
  private enabled: boolean = true;
  private audioRenderer: audio.AudioRenderer | null = null;

  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }

  beep(): void {
    if (!this.enabled) {
      return;
    }
    try {
      if (this.audioRenderer === null) {
        const audioStreamInfo: audio.AudioStreamInfo = {
          samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
          channels: audio.AudioChannel.CHANNEL_1,
          sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
          encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        };
        const audioRendererInfo: audio.AudioRendererInfo = {
          usage: audio.StreamUsage.STREAM_USAGE_MEDIA,
          rendererFlags: 0
        };
        this.audioRenderer = audio.createAudioRenderer(audioStreamInfo, audioRendererInfo);
      }
      // Generate a simple sine wave tone buffer
      const sampleRate = 44100;
      const durationSec = 0.12;
      const frequency = 1000;
      const numSamples = Math.floor(sampleRate * durationSec);
      const buffer = new ArrayBuffer(numSamples * 2);
      const view = new DataView(buffer);
      for (let i = 0; i < numSamples; i++) {
        const sample = Math.sin(2 * Math.PI * frequency * i / sampleRate) * 0.3 * 32767;
        view.setInt16(i * 2, Math.round(sample), true);
      }
      this.audioRenderer.write(buffer);
    } catch {
      // ignore audio errors
    }
  }

  release(): void {
    try {
      this.audioRenderer?.stop();
      this.audioRenderer?.release();
    } catch {
      // ignore
    }
    this.audioRenderer = null;
  }
}
