#ifndef KOOM_NATIVE_OOM_SRC_MAIN_JNI_INCLUDE_CONSTANTS_H
#define KOOM_NATIVE_OOM_SRC_MAIN_JNI_INCLUDE_CONSTANTS_H

#define ALWAYS_INLINE __attribute__((always_inline))

const uint32_t kMaxBacktraceSize =12;
const uint32_t kDefaultAllocThreshold=1024;
const uint32_t kBacktraceSkipIndex=4;
#endif // KOOM_NATIVE_OOM_SRC_MAIN_JNI_INCLUDE_CONSTANTS_H