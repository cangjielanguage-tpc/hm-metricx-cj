//
// Created on 2025/7/26.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "common.h"
#include <mutex>
#include <vector>

bool isLogCallbackRegistered = false;
std::vector<LogCallback> logCallbacks;
std::mutex logCallbackMutex;

void HilogCallback(const LogType type, const LogLevel level, const unsigned int domain, const char *tag,
                   const char *msg) {
    std::lock_guard<std::mutex> lock(logCallbackMutex);
    for (const auto &callback : logCallbacks) {
        callback(type, level, domain, tag, msg);
    }
}

void registerHilogCallback(LogCallback logCallback) {
    std::lock_guard<std::mutex> lock(logCallbackMutex);
    logCallbacks.push_back(logCallback);
    if (isLogCallbackRegistered) {
        return;
    }
    isLogCallbackRegistered = true;
    OH_LOG_SetCallback(HilogCallback);
}
