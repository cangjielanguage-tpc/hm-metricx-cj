import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { hvigor } from '@ohos/hvigor';
import * as fs from 'fs';

hvigor.nodesEvaluated(() => {
  const root = hvigor.getRootNode();
  root.subNodes(node => {
    if (node.getNodeName() === 'hm_metricx_cj') {
      const task = node.getTaskByName('default@CacheNativeLibs');
      task.afterRun(() => {
        const libsDir = node.getNodePath() + '/build/default/intermediates/stripped_native_libs/default/arm64-v8a';
        // if (fs.existsSync(libsDir + '/libc++_shared.so')) {
        //   fs.rmSync(libsDir + '/libc++_shared.so');
        // }
        const cjbins = libsDir + '/cjbins/ohos_app_cangjie_hm_metricx_cj';
        if (fs.existsSync(cjbins)) {
          for (const entry of fs.readdirSync(cjbins)) {
            const fullpath = cjbins + '/' + entry;
            if (entry.endsWith('.cjo')) {
              fs.rmSync(fullpath);
            }
          }
        }
        const ohosDir = libsDir + '/ohos';
        for (const entry of fs.readdirSync(ohosDir)) {
          const fullpath = ohosDir + '/' + entry;
          if (entry !== 'libark_interop_diff.z.so' && entry !== 'libcangjie-runtime_diff.z.so') {
            fs.rmSync(fullpath);
          }
        }
        const typesDir = node.getNodePath() + '/src/main/cangjie/types';
        for (const entry of fs.readdirSync(typesDir)) {
          const fullpath = typesDir + '/' + entry;
          if (entry.startsWith('libohos_app_cangjie_hm_metricx_cj_')) {
            fs.rmSync(fullpath, {recursive: true});
          }
        }
      });
    }
  });
});


export default {
  system: appTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: []       /* Custom plugin to extend the functionality of Hvigor. */
}

