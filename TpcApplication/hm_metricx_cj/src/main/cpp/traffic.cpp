//
// Created on 2025/8/20.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "common.h"
#include "traffic.h"
#include "traffic/hook.h"
#include "traffic/data.h"
#include <cstdint>
#include <string>

extern "C" {
int8_t InitTrafficNativeHandler() {
    return hookSocket();
}

std::string urlData = "";
const char *getTrafficNativeData() {
    urlData = TrafficData::get().toString();
    return urlData.c_str();
}

int8_t clearTrafficNativeData() {
    TrafficData::get().clear();
    return SUCCESS;
}

}