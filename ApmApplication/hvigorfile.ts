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

// 需要保证进 entry.hap 的关键 runtime 依赖（你日志里缺的就是 libutf16string_diff.z.so）
const RUNTIME_DIFF_LIBS = [
  'libutf16string_diff.z.so',
  'libark_interop_diff.z.so',
  'libcangjie-runtime_diff.z.so',
  'libcj_frontend_ohos_diff.z.so',
];

hvigor.nodesEvaluated(() => {
  const root = hvigor.getRootNode();

  let hmMetricxPath = '';
  root.subNodes(n => {
    if (n.getNodeName() === 'hm_metricx_cj') hmMetricxPath = n.getNodePath();
  });

  root.subNodes(node => {
    // ① 裁剪 hm_metricx_cj（保留必要 diff so）
    if (node.getNodeName() === 'hm_metricx_cj') {
      const task = node.getTaskByName('default@CacheNativeLibs');
      task.afterRun(() => {
        const libsDir = path.join(
          node.getNodePath(),
          'build/default/intermediates/stripped_native_libs/default/arm64-v8a'
        );

        // 删 cjbins 里的 .cjo（保留你原逻辑）
        const cjbins = path.join(libsDir, 'cjbins/ohos_app_cangjie_hm_metricx_cj');
        if (fs.existsSync(cjbins)) {
          for (const entry of fs.readdirSync(cjbins)) {
            const fullpath = path.join(cjbins, entry);
            if (entry.endsWith('.cjo')) fs.rmSync(fullpath);
          }
        }

        // 重点：ohos 目录裁剪时，把 diff runtime 依赖加入白名单（新增 libutf16string_diff.z.so）
        const ohosDir = path.join(libsDir, 'ohos');
        if (fs.existsSync(ohosDir)) {
          for (const entry of fs.readdirSync(ohosDir)) {
            const fullpath = path.join(ohosDir, entry);
            if (!RUNTIME_DIFF_LIBS.includes(entry)) {
              fs.rmSync(fullpath);
            }
          }
        }

        // 清理 types（保留你原逻辑）
        const typesDir = path.join(node.getNodePath(), 'src/main/cangjie/types');
        if (fs.existsSync(typesDir)) {
          for (const entry of fs.readdirSync(typesDir)) {
            const fullpath = path.join(typesDir, entry);
            if (entry.startsWith('libohos_app_cangjie_hm_metricx_cj_')) {
              fs.rmSync(fullpath, { recursive: true, force: true });
            }
          }
        }
      });
    }

    // ② 关键：保证 entry.hap 一定带上 runtime diff so（一次性补齐）
    if (node.getNodeName() === 'entry') {
      const task = node.getTaskByName('default@CacheNativeLibs');
      task.afterRun(() => {
        if (!hmMetricxPath) return;

        // entry 的 HAP 输入目录（这里的内容会进包）
        const entryLibsDir = path.join(
          node.getNodePath(),
          'build/default/intermediates/stripped_native_libs/default/arm64-v8a'
        );
        const entryRuntimeDir = path.join(entryLibsDir, 'runtime');
        ensureDir(entryRuntimeDir);

        // 源目录候选：优先从 hm_metricx_cj 的 stripped_native_libs/ohos 拿（你说那里有）
        const srcCandidates = [
          path.join(hmMetricxPath, 'build/default/intermediates/stripped_native_libs/default/arm64-v8a/ohos'),
          path.join(hmMetricxPath, 'build/default/intermediates/libs/default/arm64-v8a/ohos'),
          path.join(hmMetricxPath, 'build/default/intermediates/cj/libs/default/arm64-v8a/ohos'),
        ];

        for (const lib of RUNTIME_DIFF_LIBS) {
          const dst = path.join(entryRuntimeDir, lib);
          for (const srcDir of srcCandidates) {
            copyIfExists(path.join(srcDir, lib), dst);
          }
        }
      });
    }
  });
});

export default {
  system: appTasks,
  plugins: [],
};