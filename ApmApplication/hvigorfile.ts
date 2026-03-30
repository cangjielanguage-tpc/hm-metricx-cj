import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { hvigor } from '@ohos/hvigor';
import * as fs from 'fs';
import * as path from 'path';

function ensureDir(p: string) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

function copyIfExists(src: string, dst: string) {
  if (fs.existsSync(src)) {
    ensureDir(path.dirname(dst));
    fs.copyFileSync(src, dst);
  }
}

const RUNTIME_DIFF_LIBS = [
  'libutf16string_diff.z.so',
  'libark_interop_diff.z.so',
  'libcangjie-runtime_diff.z.so',
  'libcj_frontend_ohos_diff.z.so',
];

hvigor.nodesEvaluated(() => {
  console.log('[plugin] hvigor.nodesEvaluated triggered'); // 打印触发

  const root = hvigor.getRootNode();
  console.log('[plugin] root node:', root);

  let hmMetricxPath = '';
  root.subNodes(n => {
    if (n.getNodeName() === 'hm_metricx_cj') hmMetricxPath = n.getNodePath();
  });
  console.log('[plugin] hm_metricxPath:', hmMetricxPath);

  root.subNodes(node => {
    console.log('[plugin] visiting node:', node.getNodeName ? node.getNodeName() : '(unknown)');

    if (node.getNodeName() === 'hm_metricx_cj') {
      const task = node.getTaskByName('default@CacheNativeLibs');
      console.log('[plugin] hm_metricx_cj task:', task);
      task.afterRun(() => console.log('[plugin] hm_metricx_cj CacheNativeLibs afterRun triggered'));
    }

    if (node.getNodeName() === 'entry') {
      const task = node.getTaskByName('default@CacheNativeLibs');
      console.log('[plugin] entry task:', task);
      task.afterRun(() => console.log('[plugin] entry CacheNativeLibs afterRun triggered'));
    }
  });
});

export default {
  system: appTasks,
  plugins: []
};