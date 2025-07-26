//
// Created on 2025/4/7.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "common.h"
#include "hidebug/hidebug.h"
#include "hilog/log.h"
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <ctime>
#include <string>
#include <vector>

typedef const char *(*CollectExtraFreezeInfo)();
CollectExtraFreezeInfo cjCollectExtraFreezeInfo;

FILE *cpuUsageFile = nullptr;
FILE *extraInfoFile = nullptr;

const int FREEZE_TYPE = 3;
const unsigned int FREEZE_DOMAIN = 218108688;
const char *FreezeTag = "AppDfr";
const std::vector<std::string> FreezeTagS = {"APP_INPUT_BLOCK", "NO_DRAW", "LIFECYCLE_TIMEOUT", "THREAD_BLOCK_6S",
                                             "SCREEN_ON_TIMEOUT", "SERVICE_TIMEOUT", "SERVICE_BLOCK"};

bool containFreezeTag(const std::vector<std::string> &msgTags, const std::string &msg)
{
    for (const std::string &tag : msgTags) {
        if (msg.find(tag) != std::string::npos) {
            return true;
        }
    }
    return false;
}

bool freezeCaught = false;
void FreezeHilogCallback(const LogType type, const LogLevel level, const unsigned int domain, const char *tag, const char *msg)
{
    if (freezeCaught) {
        return;
    }
    int typeValue = static_cast<int>(type);
    if (typeValue != FREEZE_TYPE) {
        return;
    }
    if (level != LOG_INFO) {
        return;
    }
    if (domain != FREEZE_DOMAIN) {
        return;
    }

    if(strcmp(tag, FreezeTag) != 0) {
        return;
    }

    std::string msgStr(msg);
    if (!containFreezeTag(FreezeTagS, msgStr)) {
        return;
    }
    
    freezeCaught = true;
    auto extraInfo = cjCollectExtraFreezeInfo();
    if (extraInfoFile != nullptr) {
        fwrite(extraInfo, sizeof(char), strlen(extraInfo), extraInfoFile);
        fflush(extraInfoFile);
    }
    std::string saveStr = "";
    HiDebug_ThreadCpuUsagePtr usagePtr = OH_HiDebug_GetAppThreadCpuUsage();
    while (usagePtr != nullptr) {
        saveStr += std::to_string(usagePtr->threadId) + "," + std::to_string(usagePtr->cpuUsage) + ",";
        usagePtr = usagePtr->next;
    }
        
    if (cpuUsageFile != nullptr) {
        fwrite(saveStr.c_str(), sizeof(char), saveStr.size(), cpuUsageFile);
        fflush(cpuUsageFile);
    }
}

extern "C" int8_t registerFreezeHilogCallback(const char * cpuUsageFilePath,
                                        const char * extraInfoFilePath, CollectExtraFreezeInfo collectExtraFreezeInfo)
{
    cpuUsageFile = std::fopen(cpuUsageFilePath, "w+");
    if (cpuUsageFile == NULL) {
        return FAIL;
    }
    extraInfoFile = std::fopen(extraInfoFilePath, "w+");
    if (cpuUsageFile == NULL) {
        return FAIL;
    }
    cjCollectExtraFreezeInfo = collectExtraFreezeInfo;
    registerHilogCallback(FreezeHilogCallback);
    return SUCCESS;
}
