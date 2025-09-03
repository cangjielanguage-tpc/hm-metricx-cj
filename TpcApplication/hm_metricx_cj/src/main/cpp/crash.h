//
// Created on 2025/4/1.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef TPCAPPLICATION_CRASH_H
#define TPCAPPLICATION_CRASH_H
#include "stdint.h"

extern "C"{
    int8_t writeSystemLog(const char *pFilePath);
    int8_t persistMemeoryData(const char *mapPath, const char *allocRecordsPath, const char *parsedAddrPath);
    
}

#endif //TPCAPPLICATION_CRASH_H
