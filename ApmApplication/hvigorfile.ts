import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { hvigor } from '@ohos/hvigor';
import * as fs from 'fs';
import * as path from 'path';

/**
 * ===================== 配置区 =====================
 * 你只需要改 DISABLE_FEATURES：
 * - []            => 不裁剪（全量保留）
 * - ['fps']       => 禁用 fps
 * - ['util']      => 禁用 util 以及 util.*（包括 util.zlib）
 * - ['util.zlib'] => 只禁用 util.zlib
 */

// 最终打 hap 的模块名（通常是 entry）
const FINAL_HAP_MODULE = 'entry';

// 不要的功能（黑名单）——空数组表示不禁用任何功能
const DISABLE_FEATURES: string[] = [
  // 'fps',
  // 'freeze',
  // 'traffic',
  // 'util.zlib',
];

// 你的 feature so 命名：libohos_app_cangjie_hm_metricx_cj.<feature>.so
const SO_PREFIX = 'libohos_app_cangjie_hm_metricx_cj.';

// 需要保证进 entry.hap 的关键 runtime 依赖（你日志里缺的就是 libutf16string_diff.z.so）
const RUNTIME_DIFF_LIBS = [
  'libutf16string_diff.z.so',
  'libark_interop_diff.z.so',
  'libcangjie-runtime_diff.z.so',
  'libcj_frontend_ohos_diff.z.so',
];

/**
 * ===================== 工具函数 =====================
 */
function ensureDir(p: string) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

function safeReadDir(dir: string): string[] {
  try {
    return fs.readdirSync(dir);
  } catch {
    return [];
  }
}

function copyIfExists(src: string, dst: string) {
  if (fs.existsSync(src)) {
    ensureDir(path.dirname(dst));
    fs.copyFileSync(src, dst);
  }
}

function getNodeByName(root: any, name: string): any | null {
  let found: any = null;
  root.subNodes((n: any) => {
    if (n.getNodeName() === name) found = n;
  });
  return found;
}

function hookAfterRun(task: any, fn: () => void) {
  if (!task || typeof task.afterRun !== 'function') return false;
  task.afterRun(fn);
  return true;
}

function hookBeforeRun(task: any, fn: () => void) {
  if (!task || typeof (task as any).beforeRun !== 'function') return false;
  (task as any).beforeRun(fn);
  return true;
}

/**
 * ===================== feature so 识别/裁剪 =====================
 */

function normalizeList(arr: string[]): string[] {
  return Array.from(new Set(arr.map(s => s.trim()).filter(Boolean)));
}

function isHmMetricxFeatureSo(file: string): boolean {
  return file.startsWith(SO_PREFIX) && file.endsWith('.so');
}

function featureNameFromSo(file: string): string | null {
  if (!isHmMetricxFeatureSo(file)) return null;
  return file.slice(SO_PREFIX.length, file.length - 3);
}

/**
 * 黑名单匹配规则：
 * - 精确匹配：disable = 'fps'  => 禁用 fps
 * - 前缀匹配：disable = 'util' => 禁用 util 以及 util.*（包括 util.zlib）
 */
function shouldDisableFeature(feat: string, disable: string[]): boolean {
  for (const d of disable) {
    if (feat === d) return true;
    if (feat.startsWith(d + '.')) return true;
  }
  return false;
}

function findArm64Dirs(modulePath: string): string[] {
  // 只扫常见的几个“会产出/聚合 so 的目录”，避免全树遍历
  const bases = [
    path.join(modulePath, 'build', 'default', 'intermediates', 'stripped_native_libs'),
    path.join(modulePath, 'build', 'default', 'intermediates', 'merged_native_libs'),
    path.join(modulePath, 'build', 'default', 'intermediates', 'native_libs'),
  ];

  const out: string[] = [];

  for (const base of bases) {
    if (!fs.existsSync(base)) continue;

    // 通常结构：<base>/<variant>/<abi> 或 <base>/<variant>/<something>/<abi>
    const level1 = safeReadDir(base);
    for (const a of level1) {
      const p1 = path.join(base, a);
      if (!fs.existsSync(p1)) continue;

      let stat1: fs.Stats;
      try {
        stat1 = fs.statSync(p1);
      } catch {
        continue;
      }
      if (!stat1.isDirectory()) continue;

      const abiDirect = path.join(p1, 'arm64-v8a');
      if (fs.existsSync(abiDirect) && fs.statSync(abiDirect).isDirectory()) {
        out.push(abiDirect);
        continue;
      }

      const level2 = safeReadDir(p1);
      for (const b of level2) {
        const p2 = path.join(p1, b);
        if (!fs.existsSync(p2)) continue;

        let stat2: fs.Stats;
        try {
          stat2 = fs.statSync(p2);
        } catch {
          continue;
        }
        if (!stat2.isDirectory()) continue;

        const abiDir = path.join(p2, 'arm64-v8a');
        if (fs.existsSync(abiDir) && fs.statSync(abiDir).isDirectory()) {
          out.push(abiDir);
        }
      }
    }
  }

  return Array.from(new Set(out));
}

/**
 * 在 entry 的 intermediates 里删除“不需要的 feature so”
 * 注意：这只是打包层裁剪，不会改变 cjpm 的 requires/编译依赖树
 */
function cleanArm64FeatureSosByDisableList(modulePath: string, disable: string[]) {
  const disableList = normalizeList(disable);

  if (disableList.length === 0) {
    console.log('[feature-pack] disable list empty => keep all feature so');
    return;
  }

  const arm64Dirs = findArm64Dirs(modulePath);
  if (arm64Dirs.length === 0) {
    console.warn('[feature-pack] no arm64-v8a dirs found under known intermediates paths');
    return;
  }

  let scannedDirs = 0;
  let removed = 0;
  let kept = 0;

  for (const dir of arm64Dirs) {
    scannedDirs++;
    const files = safeReadDir(dir);

    for (const f of files) {
      if (!f.endsWith('.so')) continue;
      if (!isHmMetricxFeatureSo(f)) continue;

      const feat = featureNameFromSo(f);
      if (!feat) continue;

      if (shouldDisableFeature(feat, disableList)) {
        try {
          fs.rmSync(path.join(dir, f), { force: true });
          removed++;
        } catch (err) {
          console.warn(`[feature-pack] remove failed: ${path.join(dir, f)}`, err);
        }
      } else {
        kept++;
      }
    }
  }

  console.log(
    `[feature-pack] cleaned(disable-mode): scannedDirs=${scannedDirs}, kept=${kept}, removed=${removed}, disable=${disableList.join(',')}`
  );
}

/**
 * ===================== 主逻辑：hook 构建任务 =====================
 */
hvigor.nodesEvaluated(() => {
  const root = hvigor.getRootNode();

  const hmNode = getNodeByName(root, 'hm_metricx_cj');
  const entryNode = getNodeByName(root, FINAL_HAP_MODULE);

  const hmMetricxPath = hmNode ? hmNode.getNodePath() : '';

  // ① hm_metricx_cj：裁剪 hm_metricx_cj 自己的中间产物（保留 diff runtime so）
  if (hmNode) {
    const task = hmNode.getTaskByName('default@CacheNativeLibs');
    hookAfterRun(task, () => {
      const libsDir = path.join(
        hmNode.getNodePath(),
        'build/default/intermediates/stripped_native_libs/default/arm64-v8a'
      );

      // 删 cjbins 里的 .cjo（保留你原逻辑）
      const cjbins = path.join(libsDir, 'cjbins/ohos_app_cangjie_hm_metricx_cj');
      if (fs.existsSync(cjbins)) {
        for (const entry of safeReadDir(cjbins)) {
          if (!entry.endsWith('.cjo')) continue;
          try {
            fs.rmSync(path.join(cjbins, entry), { force: true });
          } catch {}
        }
      }

      // ohos 目录裁剪：只保留 runtime diff so 白名单
      const ohosDir = path.join(libsDir, 'ohos');
      if (fs.existsSync(ohosDir)) {
        for (const entry of safeReadDir(ohosDir)) {
          const fullpath = path.join(ohosDir, entry);
          if (!RUNTIME_DIFF_LIBS.includes(entry)) {
            try {
              fs.rmSync(fullpath, { force: true, recursive: true });
            } catch {}
          }
        }
      }

      // 清理 types（保留你原逻辑）
      const typesDir = path.join(hmNode.getNodePath(), 'src/main/cangjie/types');
      if (fs.existsSync(typesDir)) {
        for (const entry of safeReadDir(typesDir)) {
          const fullpath = path.join(typesDir, entry);
          if (entry.startsWith('libohos_app_cangjie_hm_metricx_cj_')) {
            try {
              fs.rmSync(fullpath, { recursive: true, force: true });
            } catch {}
          }
        }
      }
    });
  } else {
    console.warn('[feature-pack] hm_metricx_cj node not found (skip hm_metricx trims)');
  }

  // ② entry：补齐 runtime diff so（一次性补齐，避免 runtime 缺库）
  if (entryNode) {
    const task = entryNode.getTaskByName('default@CacheNativeLibs');
    hookAfterRun(task, () => {
      if (!hmMetricxPath) return;

      // entry 的 HAP 输入目录（这里的内容会进包）
      const entryLibsDir = path.join(
        entryNode.getNodePath(),
        'build/default/intermediates/stripped_native_libs/default/arm64-v8a'
      );
      const entryRuntimeDir = path.join(entryLibsDir, 'runtime');
      ensureDir(entryRuntimeDir);

      // 源目录候选：优先从 hm_metricx_cj 的 stripped_native_libs/ohos 拿
      const srcCandidates = [
        path.join(hmMetricxPath, 'build/default/intermediates/stripped_native_libs/default/arm64-v8a/ohos'),
        path.join(hmMetricxPath, 'build/default/intermediates/libs/default/arm64-v8a/ohos'),
        path.join(hmMetricxPath, 'build/default/intermediates/cj/libs/default/arm64-v8a/ohos'),
      ];

      for (const lib of RUNTIME_DIFF_LIBS) {
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
    });
  } else {
    console.warn(`[feature-pack] entry node not found: ${FINAL_HAP_MODULE} (skip runtime copy & feature trim)`);
    return;
  }

  // ③ entry：打包前按黑名单裁剪 feature so
  // 你说的“不要 all 模式”：disable 为空就相当于全量保留
  const pkgTask = entryNode.getTaskByName('default@PackageHap');

  const doClean = () => {
    console.log(`[feature-pack] before PackageHap: disable=${normalizeList(DISABLE_FEATURES).join(',') || '(empty)'}`);
    cleanArm64FeatureSosByDisableList(entryNode.getNodePath(), DISABLE_FEATURES);
  };

  if (!hookBeforeRun(pkgTask, doClean)) {
    // 兜底：beforeRun 不可用就直接清一次
    doClean();
  }
});

export default {
  system: appTasks,
  plugins: [],
};