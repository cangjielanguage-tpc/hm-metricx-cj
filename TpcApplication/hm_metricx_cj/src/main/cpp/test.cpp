//
// Created on 2025/6/19.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "test.h"
#include <cstdint>


extern "C" {
int *ptr = nullptr;
int64_t subCppCrash() {
    *ptr = 10;
    return 0;
}

void func() { func(); }
int64_t cppCrash() {
//    *ptr = 10;
//    subCppCrash();
//    *ptr = 11;
    func();
    return 10;
}
}
