import { describe, beforeAll, afterAll, it } from '@ohos/hypium';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { Want } from '@kit.AbilityKit';

let driver: Driver;
const delegator = abilityDelegatorRegistry.getAbilityDelegator();

export default function pageInteractionTest() {
  describe('PageInteraction', () => {
    beforeAll(async () => {
      const want: Want = {
        bundleName: 'com.example.ooxx',
        moduleName: 'entry',
        abilityName: 'EntryAbility'
      };
      await delegator.startAbility(want);
      driver = Driver.create();
      await driver.delayMs(1200);
    });

    afterAll(async () => {
      await delegator.finishTest('页面交互测试完成', 0);
    });

    it('navigatesHomeLocalGameHistoryAndProfile', 0, async () => {
      await driver.assertComponentExist(ON.text('开始体验'));
      await (await driver.findComponent(ON.text('开始体验'))).click();
      await driver.assertComponentExist(ON.text('今天玩什么？'));

      await (await driver.findComponent(ON.text('双人同屏'))).click();
      await driver.assertComponentExist(ON.text('对战中'));
      await driver.assertComponentExist(ON.text('轮到 X 落子'));

      await (await driver.findComponent(ON.id('board_cell_0'))).click();
      await driver.assertComponentExist(ON.id('board_cell_0').text('X'));
      await driver.assertComponentExist(ON.text('轮到 O 落子'));

      await (await driver.findComponent(ON.id('game_back'))).click();
      await driver.assertComponentExist(ON.text('今天玩什么？'));
      await (await driver.findComponent(ON.text('战绩'))).click();
      await driver.assertComponentExist(ON.text('对战记录'));
      await driver.assertComponentExist(ON.text('全部'));
      await driver.assertComponentExist(ON.text('胜利'));

      await (await driver.findComponent(ON.text('我的'))).click();
      await driver.assertComponentExist(ON.text('关于我们'));
    });
  });
}
