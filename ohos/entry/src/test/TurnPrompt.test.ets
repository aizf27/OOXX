import { describe, it, expect } from '@ohos/hypium';
import { Mark } from '../main/ets/model/GameModels';
import { formatTurnPrompt, TurnPromptStatus } from '../main/ets/service/TurnPrompt';

export default function turnPromptTest() {
  describe('TurnPrompt', () => {
    it('formatsCurrentMark', 0, () => {
      expect(formatTurnPrompt(Mark.X)).assertEqual('轮到 X 落子');
      expect(formatTurnPrompt(Mark.O)).assertEqual('轮到 O 落子');
    });

    it('appendsTurnStatus', 0, () => {
      expect(formatTurnPrompt(Mark.X, TurnPromptStatus.YOUR_TURN)).assertEqual('轮到 X 落子 · 你的回合');
      expect(formatTurnPrompt(Mark.O, TurnPromptStatus.WAITING_OPPONENT)).assertEqual('轮到 O 落子 · 等待对方');
      expect(formatTurnPrompt(Mark.O, TurnPromptStatus.AI_THINKING)).assertEqual('轮到 O 落子 · AI 思考中…');
    });
  });
}
