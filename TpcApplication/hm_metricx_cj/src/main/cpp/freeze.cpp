//
// Created on 2025/4/7.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "hiappevent/hiappevent.h"
#include "hicollie/hicollie.h"
#include "hidebug/hidebug.h"
#include "hilog/log.h"
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <climits>
#include <cstring>
#include <ctime>
#include <string>
#include <vector>

typedef void (*HilogHandler)(void);
HilogHandler hilogHandler;

FILE *m_file = nullptr;
int32_t OpenFile(const char *logPath)
{
    std::string logStr(logPath);
    m_file = std::fopen(logStr.c_str(), "w+");
    if (m_file == nullptr) {
        return -1;
    }
    return 0;
}

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

bool ThreadCpuUsageGet = false;
void HilogCallback(const LogType type, const LogLevel level, const unsigned int domain, const char *tag, const char *msg)
{
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
    
    std::string saveStr = "";
    if(ThreadCpuUsageGet == false) {
        saveStr += "ThreadCpuUsage\n";
        HiDebug_ThreadCpuUsagePtr usagePtr = OH_HiDebug_GetAppThreadCpuUsage();
        while (usagePtr != nullptr)
        {
            saveStr += std::to_string(usagePtr->threadId) + "," + std::to_string(usagePtr->cpuUsage) + ",";
            usagePtr = usagePtr->next;
        }
        saveStr += "\n";
        
        if (m_file != nullptr) {
            fwrite(saveStr.c_str(), sizeof(char), saveStr.size(), m_file);
            fflush(m_file);
            ThreadCpuUsageGet = true;
        }
    }
    return;
}

extern "C" void registerHilogCallback(const char * logPath, HilogHandler handler)
{
    int32_t status = OpenFile(logPath);
    if(status == 0) {
        hilogHandler = handler;
        OH_LOG_SetCallback(HilogCallback);
    }
    return;
}
