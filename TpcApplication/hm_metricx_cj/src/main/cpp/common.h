//
// Created on 2025/4/2.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef TPCAPPLICATION_COMMON_H
#define TPCAPPLICATION_COMMON_H

#include <hilog/log.h>
#define SUCCESS (0)
#define FAIL (-1)

void registerHilogCallback(LogCallback logCallback);
#endif //TPCAPPLICATION_COMMON_H
