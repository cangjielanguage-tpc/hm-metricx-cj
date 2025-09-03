//
// Created on 2025/4/2.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef TPCAPPLICATION_COMMON_H
#define TPCAPPLICATION_COMMON_H

#include <hilog/log.h>
#include <string>
#define SUCCESS (0)
#define FAIL (-1)

void registerHilogCallback(LogCallback logCallback);
std::string getLastLineEfficient(const std::string &filePath, char targetChar);
int64_t parseHexAddress(const std::string &hexStr);
bool writeFile(const char *filename, std::string str);

#endif // TPCAPPLICATION_COMMON_H
