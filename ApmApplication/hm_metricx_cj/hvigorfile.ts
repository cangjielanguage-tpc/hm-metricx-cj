import { harTasks } from '@ohos/hvigor-ohos-plugin';
import { hvigor } from '@ohos/hvigor';
import { execFileSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

/**
 * ===================== 配置区 =====================
 * 只保留 INCLUDE_FEATURES 中声明的功能进最终 HAR 包。
 * 不修改源码目录，不提前删中间产物，只在 PackageHar 完成后重写 HAR 内容。
 */
const INCLUDE_FEATURES: string[] = [
  'battery',
  'cpu',
  'crash',
  'exitInfo',
  'fps',
  'freeze',
  'laggy',
  'memory',
  'storage',
  'thermal',
  'traffic',
];

const VALID_FEATURES = new Set([
  'battery',
  'cpu',
  'crash',
  'exitInfo',
  'fps',
  'freeze',
  'laggy',
  'memory',
  'storage',
  'thermal',
  'traffic',
]);

const ALWAYS_INCLUDED_FEATURES = new Set([
  'util',
  'util.zlib',
  'wrapper',
]);

const SO_PREFIX = 'libohos_app_cangjie_hm_metricx_cj.';
const GENERATED_TYPES_PREFIX = 'libohos_app_cangjie_hm_metricx_cj_';

const KEEP_CANGJIE_DIRS = new Set([
  'ark_interop_api',
  'loader',
  'types',
]);

const KEEP_TYPE_DIRS = new Set([
  'libohos_app_cangjie_hm_metricx_cj',
]);

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

function safeRemove(target: string) {
  try {
    fs.rmSync(target, { recursive: true, force: true });
  } catch {}
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

function isHmMetricxFeatureSo(file: string): boolean {
  return file.startsWith(SO_PREFIX) && file.endsWith('.so');
}

function featureNameFromSo(file: string): string | null {
  if (!isHmMetricxFeatureSo(file)) return null;
  return file.slice(SO_PREFIX.length, file.length - '.so'.length);
}

function featureNameFromGeneratedTypeDir(dirName: string): string | null {
  if (!dirName.startsWith(GENERATED_TYPES_PREFIX)) return null;
  return dirName.slice(GENERATED_TYPES_PREFIX.length).replace(/_/g, '.');
}

function shouldIncludeFeature(featureName: string, includeFeatures: string[]): boolean {
  if (ALWAYS_INCLUDED_FEATURES.has(featureName)) return true;
  return includeFeatures.some((included) =>
  featureName === included || featureName.startsWith(`${included}.`)
  );
}

function validateIncludeFeatures(rawIncludeFeatures: string[]): string[] {
  const errors: string[] = [];
  const normalized: string[] = [];
  const firstIndexByName = new Map<string, number>();

  rawIncludeFeatures.forEach((rawItem, index) => {
    const featureName = rawItem.trim();

    if (!featureName) {
      errors.push(`INCLUDE_FEATURES[${index}] 不能为空字符串`);
      return;
    }

    const firstIndex = firstIndexByName.get(featureName);
    if (typeof firstIndex === 'number') {
      errors.push(`INCLUDE_FEATURES[${index}] 与 INCLUDE_FEATURES[${firstIndex}] 重复: "${featureName}"`);
      return;
    }
    firstIndexByName.set(featureName, index);

    if (!VALID_FEATURES.has(featureName)) {
      errors.push(
        `INCLUDE_FEATURES[${index}] 非法: "${featureName}"，可选值为: ${Array.from(VALID_FEATURES).join(', ')}`
      );
      return;
    }

    normalized.push(featureName);
  });

  if (errors.length > 0) {
    throw new Error(`[feature-pack] INCLUDE_FEATURES 配置错误:\n- ${errors.join('\n- ')}`);
  }

  return normalized;
}

function removeExcludedFeatureSos(packageRoot: string, includeFeatures: string[]) {
  const libsDir = path.join(packageRoot, 'libs', 'arm64-v8a');
  if (!fs.existsSync(libsDir)) return;

  for (const entry of safeReadDir(libsDir)) {
    const featureName = featureNameFromSo(entry);
    if (!featureName) continue;
    if (shouldIncludeFeature(featureName, includeFeatures)) continue;

    safeRemove(path.join(libsDir, entry));
    console.log(`[feature-pack] removed feature so from HAR: ${entry}`);
  }
}

function copyRuntimeDiffLibsToRuntime(packageRoot: string) {
  const libsDir = path.join(packageRoot, 'libs', 'arm64-v8a');
  const ohosDir = path.join(libsDir, 'ohos');
  const runtimeDir = path.join(libsDir, 'runtime');

  if (!fs.existsSync(ohosDir)) return;
  ensureDir(runtimeDir);

  const keepLibs = new Set([
    'libutf16string_diff.z.so',
    'libark_interop_diff.z.so',
    'libcangjie-runtime_diff.z.so',
    'libcj_frontend_ohos_diff.z.so',
    'libtransform_interaction_ext.z.so',
    'libohos.base.so',
  ]);

  for (const lib of keepLibs) {
    const src = path.join(ohosDir, lib);
    const dst = path.join(runtimeDir, lib);
    if (!fs.existsSync(src)) continue;
    if (fs.existsSync(dst)) continue;

    fs.copyFileSync(src, dst);
    console.log(`[feature-pack] copied runtime diff lib into runtime: ${lib}`);
  }
}

function slimHarSources(packageRoot: string, includeFeatures: string[]) {
  const cangjieDir = path.join(packageRoot, 'src', 'main', 'cangjie');
  if (!fs.existsSync(cangjieDir)) return;

  for (const entry of safeReadDir(cangjieDir)) {
    if (KEEP_CANGJIE_DIRS.has(entry)) continue;
    safeRemove(path.join(cangjieDir, entry));
  }

  const typesDir = path.join(cangjieDir, 'types');
  if (!fs.existsSync(typesDir)) return;

  for (const entry of safeReadDir(typesDir)) {
    if (KEEP_TYPE_DIRS.has(entry)) continue;

    if (VALID_FEATURES.has(entry)) {
      if (!shouldIncludeFeature(entry, includeFeatures)) {
        safeRemove(path.join(typesDir, entry));
        console.log(`[feature-pack] removed type dir from HAR: types/${entry}`);
      }
      continue;
    }

    const generatedFeatureName = featureNameFromGeneratedTypeDir(entry);
    if (generatedFeatureName && !shouldIncludeFeature(generatedFeatureName, includeFeatures)) {
      safeRemove(path.join(typesDir, entry));
      console.log(`[feature-pack] removed generated type dir from HAR: types/${entry}`);
    }
  }
}

function filterObjectEntries(
  input: Record<string, any> | undefined,
  includeFeatures: string[],
  featureNameGetter: (key: string, value: any) => string | null
) {
  const next: Record<string, any> = {};

  for (const [key, value] of Object.entries(input || {})) {
    const featureName = featureNameGetter(key, value);
    if (featureName && !shouldIncludeFeature(featureName, includeFeatures)) {
      console.log(`[feature-pack] removed package metadata: ${key}`);
      continue;
    }
    next[key] = value;
  }

  return next;
}

function rewriteJsonIfExists(
  jsonPath: string,
  rewriter: (json: Record<string, any>) => Record<string, any>
) {
  if (!fs.existsSync(jsonPath)) return;
  const json = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));
  fs.writeFileSync(jsonPath, `${JSON.stringify(rewriter(json), null, 2)}\n`);
}

function prunePackageJsonFiles(packageRoot: string, includeFeatures: string[]) {
  rewriteJsonIfExists(path.join(packageRoot, 'oh-package.json5'), (json) => {
    json.dependencies = filterObjectEntries(
      json.dependencies,
      includeFeatures,
      (dependencyName) => featureNameFromSo(dependencyName)
    );
    return json;
  });

  rewriteJsonIfExists(path.join(packageRoot, 'oh-package-lock.json5'), (json) => {
    json.specifiers = filterObjectEntries(
      json.specifiers,
      includeFeatures,
      (specifierName) => featureNameFromSo(specifierName.split('@')[0])
    );

    json.packages = filterObjectEntries(
      json.packages,
      includeFeatures,
      (packageName, packageValue) => {
        const rawName = (packageValue && packageValue.name) || packageName.split('@')[0];
        return featureNameFromSo(rawName);
      }
    );

    return json;
  });
}

function pruneHarByIncludeFeatures(modulePath: string, includeFeatures: string[]) {
  const harFile = path.join(modulePath, 'build/default/outputs/default/hm_metricx_cj.har');
  if (!fs.existsSync(harFile)) {
    console.warn('[feature-pack] HAR not found, skip pruning');
    return;
  }

  const tempRoot = path.join(modulePath, 'build/default/.har_include_prune');
  const packageRoot = path.join(tempRoot, 'package');

  safeRemove(tempRoot);
  ensureDir(tempRoot);

  try {
    execFileSync('tar', ['-xzf', harFile, '-C', tempRoot], { stdio: 'pipe' });

    removeExcludedFeatureSos(packageRoot, includeFeatures);
    copyRuntimeDiffLibsToRuntime(packageRoot);
    slimHarSources(packageRoot, includeFeatures);
    prunePackageJsonFiles(packageRoot, includeFeatures);

    execFileSync('tar', ['-czf', harFile, '-C', tempRoot, 'package'], { stdio: 'pipe' });
    console.log(`[feature-pack] HAR pruned by INCLUDE_FEATURES: ${includeFeatures.join(', ') || '(empty)'}`);
  } catch (err) {
    throw new Error(`[feature-pack] failed to prune HAR: ${String(err)}`);
  } finally {
    safeRemove(tempRoot);
  }
}

hvigor.nodesEvaluated(() => {
  const includeFeatures = validateIncludeFeatures(INCLUDE_FEATURES);
  const root = hvigor.getRootNode();

  const hmNode = getNodeByName(root, 'hm_metricx_cj');

  if (hmNode) {
    const pkgHarTask = hmNode.getTaskByName('default@PackageHar');
    hookAfterRun(pkgHarTask, () => {
      console.log(`[feature-pack] after PackageHar: include=${includeFeatures.join(', ') || '(empty)'}`);
      pruneHarByIncludeFeatures(hmNode.getNodePath(), includeFeatures);
    });
  } else {
    console.warn('[feature-pack] hm_metricx_cj node not found');
  }
});

export default {
  system: harTasks,
  plugins: [],
};
