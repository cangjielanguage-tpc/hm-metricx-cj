import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { hvigor } from '@ohos/hvigor';
import * as fs from 'fs';
import * as path from 'path';

const FINAL_HAP_MODULE = 'entry';
const EXCLUDE_FEATURES = ['crash','cpu'];  // 要排除的特性列表，空表示不排除任何特性

const SO_PREFIX = 'libohos_app_cangjie_hm_metricx_cj.';

function isHmMetricxFeatureSo(file: string): boolean {
    return file.startsWith(SO_PREFIX) && file.endsWith('.so');
}

function featureNameFromSo(file: string): string | null {
    if (!isHmMetricxFeatureSo(file)) return null;
    return file.slice(SO_PREFIX.length, file.length - 3);
}

function safeReadDir(dir: string): string[] {
    try {
        return fs.readdirSync(dir);
    } catch {
        return [];
    }
}

function findArm64Dirs(modulePath: string): string[] {
    // 只扫常见的几个"会产出/聚合 so 的目录"，避免全树遍历
    const bases = [
        path.join(modulePath, 'build', 'default', 'intermediates', 'stripped_native_libs'),
        path.join(modulePath, 'build', 'default', 'intermediates', 'merged_native_libs'),
        path.join(modulePath, 'build', 'default', 'intermediates', 'native_libs'),
    ];

    const out: string[] = [];

    for (const base of bases) {
        if (!fs.existsSync(base)) continue;

        // 通常目录结构是 stripped_native_libs/<variant>/<abi>
        // 所以这里最多走两层，避免递归扫整个 intermediates
        const level1 = safeReadDir(base);
        for (const a of level1) {
            const p1 = path.join(base, a);
            if (!fs.existsSync(p1) || !fs.statSync(p1).isDirectory()) continue;

            // 可能直接就是 arm64-v8a，也可能还有一层
            const maybeAbi = path.join(p1, 'arm64-v8a');
            if (fs.existsSync(maybeAbi) && fs.statSync(maybeAbi).isDirectory()) {
                out.push(maybeAbi);
                continue;
            }

            const level2 = safeReadDir(p1);
            for (const b of level2) {
                const p2 = path.join(p1, b);
                if (!fs.existsSync(p2) || !fs.statSync(p2).isDirectory()) continue;

                const abiDir = path.join(p2, 'arm64-v8a');
                if (fs.existsSync(abiDir) && fs.statSync(abiDir).isDirectory()) {
                    out.push(abiDir);
                }
            }
        }
    }

    // 去重
    return Array.from(new Set(out));
}

function cleanArm64FeatureSos(modulePath: string, exclude: string[]) {
    const excludeSet = new Set(exclude);

    const arm64Dirs = findArm64Dirs(modulePath);
    if (arm64Dirs.length === 0) {
        console.warn(`[feature-pack] no arm64-v8a dirs found under known intermediates paths`);
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

            if (excludeSet.has(feat)) {
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
        `[feature-pack] cleaned: scannedDirs=${scannedDirs}, kept=${kept}, removed=${removed}, exclude=${exclude.join(',')}`
    );
}

hvigor.nodesEvaluated(() => {

    const root = hvigor.getRootNode();

    let finalNode: any = null;
    root.subNodes(n => {
        if (n.getNodeName() === FINAL_HAP_MODULE) finalNode = n;
    });

    if (!finalNode) {
        console.warn(`[feature-pack] cannot find final hap module: ${FINAL_HAP_MODULE}`);
        return;
    }

    const modulePath = finalNode.getNodePath();
    const pkg = finalNode.getTaskByName('default@PackageHap');

    if (pkg && typeof (pkg as any).beforeRun === 'function') {
        (pkg as any).beforeRun(() => {
            console.log(`[feature-pack] mode=select: exclude ${EXCLUDE_FEATURES.join(', ') || 'none'} (before PackageHap)`);
            cleanArm64FeatureSos(modulePath, EXCLUDE_FEATURES);
        });
    } else {
        // 兜底：如果 beforeRun 不可用，就直接清一次（但不要挂多个 task）
        console.log(`[feature-pack] mode=select: exclude ${EXCLUDE_FEATURES.join(', ') || 'none'} (fallback clean)`);
        cleanArm64FeatureSos(modulePath, EXCLUDE_FEATURES);
    }
});

export default {
    system: appTasks,
};
