import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { hvigor } from '@ohos/hvigor';
import * as fs from 'fs';
import * as path from 'path';

function ensureDir(p: string) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

function copyIfExists(src: string, dst: string) {
  if (!fs.existsSync(src)) return;
  ensureDir(path.dirname(dst));
  fs.copyFileSync(src, dst);
}

function pruneDirToWhitelist(dir: string, keepFiles: string[]) {
  if (!fs.existsSync(dir)) return;

  for (const entry of fs.readdirSync(dir)) {
    if (!entry.endsWith('.so')) continue;
    if (keepFiles.includes(entry)) continue;

    fs.rmSync(path.join(dir, entry), { force: true });
  }
}

function getNodeByName(root: any, name: string): any | null {
  let found: any = null;
  root.subNodes((n: any) => {
    if (n.getNodeName() === name) found = n;
  });
  return found;
}

const RUNTIME_DIFF_LIBS = [
  'libutf16string_diff.z.so',
  'libark_interop_diff.z.so',
  'libcangjie-runtime_diff.z.so',
  'libcj_frontend_ohos_diff.z.so',
  'libtransform_interaction_ext.z.so',
  'libohos.base.so',
];

hvigor.nodesEvaluated(() => {
  const root = hvigor.getRootNode();
  const hmNode = getNodeByName(root, 'hm_metricx_cj');
  const entryNode = getNodeByName(root, 'entry');

  if (!hmNode || !entryNode) return;

  const task = entryNode.getTaskByName('default@CacheNativeLibs');
  if (!task || typeof task.afterRun !== 'function') return;

  task.afterRun(() => {
    const hmMetricxPath = hmNode.getNodePath();
    const entryRuntimeDirs = [
      path.join(entryNode.getNodePath(), 'build/default/intermediates/stripped_native_libs/default/arm64-v8a/runtime'),
      path.join(entryNode.getNodePath(), 'build/default/intermediates/libs/default/arm64-v8a/runtime'),
    ];

    for (const dir of entryRuntimeDirs) {
      ensureDir(dir);
    }

    const srcCandidates = [
      path.join(hmMetricxPath, 'build/default/intermediates/stripped_native_libs/default/arm64-v8a/ohos'),
      path.join(hmMetricxPath, 'build/default/intermediates/libs/default/arm64-v8a/ohos'),
      path.join(hmMetricxPath, 'build/default/intermediates/cj/libs/default/arm64-v8a/ohos'),
    ];

    for (const lib of RUNTIME_DIFF_LIBS) {
      for (const entryRuntimeDir of entryRuntimeDirs) {
        const dst = path.join(entryRuntimeDir, lib);
        if (fs.existsSync(dst)) continue;

        for (const srcDir of srcCandidates) {
          const src = path.join(srcDir, lib);
          if (fs.existsSync(src)) {
            copyIfExists(src, dst);
            break;
          }
        }
      }
    }

    const entryOhosDirs = [
      path.join(entryNode.getNodePath(), 'build/default/intermediates/stripped_native_libs/default/arm64-v8a/ohos'),
      path.join(entryNode.getNodePath(), 'build/default/intermediates/libs/default/arm64-v8a/ohos'),
    ];

    for (const dir of entryOhosDirs) {
      pruneDirToWhitelist(dir, RUNTIME_DIFF_LIBS);
    }
  });
});

export default {
  system: appTasks,
  plugins: []
};
