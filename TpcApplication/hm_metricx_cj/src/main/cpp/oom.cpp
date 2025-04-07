//
// Created on 2025/4/2.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "oom.h"
#include "common.h"
#include <cstdio>
#include <dlfcn.h>
#include <fcntl.h>
#include <fstream>
#include <inttypes.h>
#include <iostream>
#include <link.h>
#include <stdarg.h>
#include <string.h>
#include <string>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <unistd.h>
#include <hilog/log.h>
#include <KOOM/kwai_linker/elf_reader.h>

#define PAGE_SHIFT 12
#define PAGE_SIZE (1UL << PAGE_SHIFT)
#define PAGE_MASK (~(PAGE_SIZE - 1))
#define PAGE_START(addr) ((addr) & PAGE_MASK)
#define PAGE_END(addr)   (PAGE_START(addr + sizeof(uintptr_t) - 1) + PAGE_SIZE)
#define PAGE_COVER(addr) (PAGE_END(addr) - PAGE_START(addr))

uintptr_t gBaseAddr = 0;

char *oomFile;

char *cjZlibFile;

FILE *gFp;

typedef bool (*CompressFile)(const char*, const char*);

CompressFile cjCompressFile;

class MutatorManager {
    public:
    MutatorManager() {}
    ~MutatorManager() {}
    
    MutatorManager(const MutatorManager &) = delete;
    MutatorManager(MutatorManager &&) = delete;
    MutatorManager &operator=(const MutatorManager &) = delete;
    MutatorManager &operator=(MutatorManager &&) = delete;
    
    static MutatorManager &Instance() noexcept;
    
    void StopTheWorld(bool syncGCPhase, uint8_t phase);
    void StartTheWorld() noexcept;
};

MutatorManager &(*initMutatorManager)();

void (*stopTheWorld)(MutatorManager *, bool, uint8_t);

void (*startTheWorld)(MutatorManager *);

static void Noop(bool syncGCPhase, uint8_t phase) {}

int replaceFunc(uintptr_t baseAddr, uintptr_t offset, void *newFunc)
{
    uintptr_t addr = baseAddr + offset;
    
    int res = mprotect((void *)PAGE_START(addr), PAGE_COVER(addr), PROT_READ | PROT_WRITE);
    
    if (res != 0) {
        return errno;
    }
    
    *(void **)addr = newFunc;
    
    __builtin___clear_cache((char *)PAGE_START(addr), (char *)PAGE_END(addr));
    
    return 0;
}

static FILE *Fopen(const char *filename, const char *mode)
{
    if (!oomFile || std::strcmp(oomFile, filename) != 0) {
        return fopen(filename, mode);
    }
    MutatorManager &mutatorManager = initMutatorManager();
    stopTheWorld(&mutatorManager, false, 1);
    pid_t pid = fork();
    if (pid == 0) {
        pid_t pid = getpid();
        replaceFunc(gBaseAddr, 0x12e940, (void *)Noop);
        FILE *fp = fopen(filename, mode);
        gFp = fp;
        return fp;
    } else {
        startTheWorld(&mutatorManager);
        return nullptr;
    }
}

static int Fclose(FILE *fp)
{
    int res = fclose(fp);
    if (gFp == fp) {
        cjCompressFile(oomFile, cjZlibFile);
    }
    return res;
}

extern "C" __attribute__((weak)) int dl_iterate_phdr(int (*)(struct dl_phdr_info *, size_t, void *), void *);

struct dl_iterate_data {
    dl_phdr_info info_;
};

int dl_iterate_phdr_wrapper(int (*__callback)(struct dl_phdr_info *, size_t, void *), void *__data)
{
    if (dl_iterate_phdr) {
        return dl_iterate_phdr(__callback, __data);
    }
    return 0;
}

static int dl_iterate_callback(dl_phdr_info *info, size_t size, void *data)
{
    auto target = reinterpret_cast<dl_iterate_data *>(data);
    if (info->dlpi_addr != 0 && strstr(info->dlpi_name, target->info_.dlpi_name)) {
        target->info_.dlpi_name = info->dlpi_name;
        target->info_.dlpi_addr = info->dlpi_addr;
        target->info_.dlpi_phdr = info->dlpi_phdr;
        target->info_.dlpi_phnum = info->dlpi_phnum;
        return 1;
    }
    return 0;
}

void *Dlopen(const char* libName, int flags)
{
    auto *data = new dl_iterate_data();
    data->info_.dlpi_name = libName;
    dl_iterate_phdr_wrapper(dl_iterate_callback, data);
    return data;
}

int Dlclose(void *handle)
{
    delete (dl_iterate_data *)handle;
    return 0;
}

void *Dlsym(void *handle, const char *name) {
    if (!handle) {
        return nullptr;
    }
    
    auto *data = (dl_iterate_data *)handle;
    if (!data->info_.dlpi_name || data->info_.dlpi_name[0] != '/') {
        return nullptr;
    }
    
    kwai::linker::ElfReader elf_reader(std::make_shared<kwai::linker::FileElfWrapper>(data->info_.dlpi_name));
    if (!elf_reader.Init()) {
        return nullptr;
    }
    return elf_reader.LookupSymbol(name, data->info_.dlpi_addr, true);
}

extern "C" {
int8_t InitOOMHandler(const char *targetFile, const char *zlibFile, CompressFile compressFile)
{
    char line[512];
    FILE *fp;
    uintptr_t baseAddr = 0;
    uintptr_t addr;
    
    if (NULL == (fp = fopen("/proc/self/maps", "r"))) {
        return FAIL;
    }
    
    while (fgets(line, sizeof(line), fp)) {
    if (NULL != strstr(line, "libcangjie-runtime.so") &&
        sscanf(line, "%" PRIxPTR "-%*lx %*4s 00000000", &baseAddr) == 1) {
            break;
        }
    }
    fclose(fp);
    
    if (0 == baseAddr) {
        return FAIL;
    }
    
    int res = replaceFunc(baseAddr, 0x12e8d8, (void *)Fopen);
    
    if (res != 0) {
        return FAIL;
    }
    
    res = replaceFunc(baseAddr, 0x12e908, (void *)Fclose);
    
    if (res != 0) {
        return FAIL;
    }
    
    void *handle = Dlopen("libcangjie-runtime.so", RTLD_NOW);
    if (!handle) {
        return FAIL;
    }
    
    stopTheWorld = (void (*)(MutatorManager *, bool, uint8_t))Dlsym(handle, 
        "_ZN12MapleRuntime14MutatorManager12StopTheWorldEbNS_7GCPhaseE");
    if (!stopTheWorld) {
        Dlclose(handle);
        return FAIL;
    }
    
    startTheWorld = (void (*)(MutatorManager *))Dlsym(handle, "_ZN12MapleRuntime14MutatorManager13StartTheWorldEv");
    if (!startTheWorld) {
        Dlclose(handle);
        return FAIL;
    }
    
    initMutatorManager = (MutatorManager & (*)())Dlsym(handle, "_ZN12MapleRuntime14MutatorManager8InstanceEv");
    if (!initMutatorManager) {
        Dlclose(handle);
        return FAIL;
    }
    
    gBaseAddr = baseAddr;
    oomFile = new char[strlen(targetFile) + 1];
    strcpy(oomFile, targetFile);
    cjZlibFile = new char[strlen(zlibFile) + 1];
    strcpy(cjZlibFile, zlibFile);
    cjCompressFile = compressFile;
    return SUCCESS;
}
}