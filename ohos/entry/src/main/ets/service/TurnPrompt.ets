import { Mark } from '../model/GameModels';

export enum TurnPromptStatus {
  NONE = '',
  YOUR_TURN = '你的回合',
  WAITING_OPPONENT = '等待对方',
  AI_THINKING = 'AI 思考中…'
}

export function formatTurnPrompt(turn: Mark, status: TurnPromptStatus = TurnPromptStatus.NONE): string {
  const prompt = `轮到 ${turn} 落子`;
  return status === TurnPromptStatus.NONE ? prompt : `${prompt} · ${status}`;
}
