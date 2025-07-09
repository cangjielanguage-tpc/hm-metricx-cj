//
// Created on 2025/4/1.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "crash.h"
#include "common.h"
#include <bundle/native_interface_bundle.h>
#include <filesystem>
#include <fstream>
#include <hilog/log.h>
#include <iostream>
#include <malloc.h>
#include <pthread.h>
#include <signal.h>
#include <stdexcept>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <sys/eventfd.h>
#include <syscall.h>
#include <unistd.h>
#include <sstream>

typedef struct {
    int sigNum;
    struct sigaction oldact;
} SignalCrashInfo;

static pthread_mutex_t signalHandlerMutex = PTHREAD_MUTEX_INITIALIZER;

static sig_atomic_t inCrash = 0;

int initSuccess = 0;

typedef const char *(*CollectCrashInfo)();

CollectCrashInfo cjCollectCrashInfo;

typedef void (*Callback)(const char *, const char *, CollectCrashInfo, const char *, const char *, const char *, char *);

Callback cjcb;

char *persistentFilePath;

char *cjLimits;

static SignalCrashInfo signalCrashInfo[] = {{.sigNum = SIGABRT}, {.sigNum = SIGBUS},   {.sigNum = SIGFPE},
                                            {.sigNum = SIGILL},  {.sigNum = SIGSEGV},  {.sigNum = SIGTRAP},
                                            {.sigNum = SIGSYS},  {.sigNum = SIGSTKFLT}};

int RemoveSignalHandler() {
    int r = SUCCESS;
    size_t i;
    for (i = 0; i < sizeof(signalCrashInfo) / sizeof(signalCrashInfo[0]); i++) {
        if (0 != sigaction(signalCrashInfo[i].sigNum, &(signalCrashInfo[i].oldact), NULL)) {
            r = FAIL;
        }
    }
    return r;
}

static std::string readFile(std::string filePath) {
    if (std::__fs::filesystem::exists(filePath)) {
        std::ifstream file(filePath);
        if (file.is_open()) {
            std::string content((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
            return content;
        }
    }
    return "";
}

static std::string getVss(const std::string& s, char delimiter) {
    std::string token;
    std::istringstream tokenStream(s);
    if (std::getline(tokenStream, token, delimiter)) {
        return std::to_string(std::stoi(token) * 4);
    }
    return "";
}

static void CrashSignalHandler(int sig, siginfo_t *si, void *context) {
    if (initSuccess == 0) {
        signalCrashInfo[sig].oldact.sa_sigaction(sig, si, context);
        return;
    }
    pthread_mutex_lock(&signalHandlerMutex);
    if (inCrash) {
        pthread_mutex_unlock(&signalHandlerMutex);
        signalCrashInfo[sig].oldact.sa_sigaction(sig, si, context);
        return;
    }
    inCrash = 1;
    std::string fds = "";
    if (std::__fs::filesystem::exists("/proc/self/fd")) {
        for (auto &entry : std::__fs::filesystem::directory_iterator("/proc/self/fd")) {
            auto path = entry.path();
            fds += path.string() + ",";
            try {
                fds += std::__fs::filesystem::canonical(path).string() + ",";
            } catch (const std::__fs::filesystem::filesystem_error &e) {
                fds += "unknown,";
            }
        }
    }
    std::string threads = readFile("/proc/self/tids");
    std::string smaps_rollup = readFile("/proc/self/smaps_rollup");
    std::string vss = "Vss:\t\t\t\t" + getVss(readFile("/proc/self/statm"), ' ') + " KB";
    std::string meminfo = smaps_rollup + "\n" + vss;
    cjcb(persistentFilePath, cjLimits, cjCollectCrashInfo, fds.c_str(), threads.c_str(), meminfo.c_str(),
         OH_NativeBundle_GetCurrentApplicationInfo().bundleName);
    RemoveSignalHandler();
    pthread_mutex_unlock(&signalHandlerMutex);
    signalCrashInfo[sig].oldact.sa_sigaction(sig, si, context);
}

extern "C" {
int8_t InitNativeSignalHandler(const char *pFilePath, const char *limits, CollectCrashInfo collectCrashInfo,
                               Callback cb) {
    struct sigaction act;
    memset(&act, 0, sizeof(act));
    sigfillset(&act.sa_mask);
    act.sa_sigaction = CrashSignalHandler;
    act.sa_flags = SA_RESTART | SA_SIGINFO | SA_ONSTACK;

    size_t i;
    for (i = 0; i < sizeof(signalCrashInfo) / sizeof(signalCrashInfo[0]); i++) {
        if (0 != sigaction(signalCrashInfo[i].sigNum, &act, &(signalCrashInfo[i].oldact))) {
            RemoveSignalHandler();
            return FAIL;
        }
    }
    initSuccess = 1;
    auto pFilePathLen = strlen(pFilePath);
    persistentFilePath = new char[pFilePathLen + 1];
    strncpy(persistentFilePath, pFilePath, pFilePathLen);
    persistentFilePath[pFilePathLen] = '\0';
    auto limitsLen = strlen(limits);
    cjLimits = new char[limitsLen + 1];
    strncpy(cjLimits, limits, limitsLen);
    cjLimits[limitsLen] = '\0';
    cjCollectCrashInfo = collectCrashInfo;
    cjcb = cb;
    return SUCCESS;
}
}
