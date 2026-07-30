import abilityTest from './Ability.test';
import bearerTest from './Bearer.test';
import pageParamTest from './PageParam.test';

export default function testsuite() {
  abilityTest();
  bearerTest();
  pageParamTest();
}
