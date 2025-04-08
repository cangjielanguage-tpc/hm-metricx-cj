//
// Created on 2025/4/1.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "crash.h"
#include "common.h"
#include <signal.h>
#include <malloc.h>
#include <string.h>
#include <pthread.h>
#include <sys/eventfd.h>
#include <unistd.h>
#include <syscall.h>
#include <stdlib.h>
#include <stdexcept>
#include <hilog/log.h>
#include <string>
#include <iostream>
#include <filesystem>
#include <bundle/native_interface_bundle.h>

typedef struct {
    int sigNum;
    struct sigaction oldact;
} SignalCrashInfo;

static pthread_mutex_t signalHandlerMutex = PTHREAD_MUTEX_INITIALIZER;

static sig_atomic_t inCrash = 0;

int initSuccess = 0;

typedef const char *(*CollectCrashInfo)();

CollectCrashInfo cjCollectCrashInfo;

typedef void (*ReportCrashInfo)(const char *);

ReportCrashInfo cjReportCrashInfo;

typedef void (*Callback)(const char *, const char *, CollectCrashInfo, ReportCrashInfo, const char *, char *);

Callback cjcb;

char *persistentFilePath;

char *cjLimits;

static SignalCrashInfo signalCrashInfo[] =
        {
                {.sigNum = SIGABRT},
                {.sigNum = SIGBUS},
                {.sigNum = SIGFPE},
                {.sigNum = SIGILL},
                {.sigNum = SIGSEGV},
                {.sigNum = SIGTRAP},
                {.sigNum = SIGSYS},
                {.sigNum = SIGSTKFLT}
        };

int RemoveSignalHandler()
{
    int r = SUCCESS;
    size_t i;
    for (i = 0; i < sizeof(signalCrashInfo) / sizeof(signalCrashInfo[0]); i++) {
        if (0 != sigaction(signalCrashInfo[i].sigNum, &(signalCrashInfo[i].oldact), NULL)) {
            r = FAIL;
        }
    }
    return r;
}

static void CrashSignalHandler(int sig, siginfo_t *si, void *context)
{
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
        for (auto& entry : std::__fs::filesystem::directory_iterator("/proc/self/fd")) {
            auto path = entry.path();
            fds += path.string() + ",";
            try {
                fds += std::__fs::filesystem::canonical(path).string() + ",";
            } catch (const std::__fs::filesystem::filesystem_error& e) {
                fds += "unknown,";
            }
        }
    }
    cjcb(persistentFilePath, cjLimits, cjCollectCrashInfo, cjReportCrashInfo, fds.c_str(), OH_NativeBundle_GetCurrentApplicationInfo().bundleName);
    RemoveSignalHandler();
    pthread_mutex_unlock(&signalHandlerMutex);
    signalCrashInfo[sig].oldact.sa_sigaction(sig, si, context);
}

extern "C" {
int8_t InitNativeSignalHandler(const char *pFilePath, const char *limits, CollectCrashInfo collectCrashInfo, ReportCrashInfo reportCrashInfo, Callback cb)
{
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
    persistentFilePath = new char[strlen(pFilePath) + 1];
    strcpy(persistentFilePath, pFilePath);
    cjLimits = new char[strlen(limits) + 1];
    strcpy(cjLimits, limits);
    cjCollectCrashInfo = collectCrashInfo;
    cjReportCrashInfo = reportCrashInfo;
    cjcb = cb;
    return SUCCESS;
}
}
