import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { Settings } from '../model/AppModels';

const PREFERENCES_NAME = 'ooxx_settings';

export class PreferenceStore {
  private static instance: PreferenceStore | null = null;
  private pref: preferences.Preferences | null = null;

  static getInstance(): PreferenceStore {
    if (PreferenceStore.instance === null) {
      PreferenceStore.instance = new PreferenceStore();
    }
    return PreferenceStore.instance;
  }

  async init(context: Context): Promise<void> {
    if (this.pref !== null) {
      return;
    }
    this.pref = await preferences.getPreferences(context, PREFERENCES_NAME);
  }

  loadSettings(): Settings {
    if (this.pref === null) {
      return new Settings();
    }
    return new Settings(
      this.pref.getSync('sound', true) as boolean,
      this.pref.getSync('vibration', true) as boolean,
      this.pref.getSync('darkMode', false) as boolean
    );
  }

  async saveSettings(settings: Settings): Promise<void> {
    if (this.pref === null) {
      return;
    }
    await this.pref.put('sound', settings.sound);
    await this.pref.put('vibration', settings.vibration);
    await this.pref.put('darkMode', settings.darkMode);
    await this.pref.flush();
  }

  loadPlayerId(): string {
    if (this.pref === null) {
      return this.makeId();
    }
    const stored = this.pref.getSync('playerId', '') as string;
    if (stored.length > 0) {
      return stored;
    }
    const id = this.makeId();
    this.pref.putSync('playerId', id);
    return id;
  }

  private makeId(): string {
    return `guest-${this.randomUuid()}`;
  }

  private randomUuid(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (char) => {
      const random = Math.random() * 16 | 0;
      const value = char === 'x' ? random : (random & 0x3 | 0x8);
      return value.toString(16);
    });
  }
}
