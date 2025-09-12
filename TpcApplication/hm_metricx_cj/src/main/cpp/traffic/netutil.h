//
// Created on 2025/8/28.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef TPCAPPLICATION_TRAFFIC_NETUTIL_H
#define TPCAPPLICATION_TRAFFIC_NETUTIL_H

#include <arpa/inet.h>

int parse_ip_port_from_sockaddr(const struct sockaddr *addr, char* ip, unsigned short* port);

#endif //TPCAPPLICATION_TRAFFIC_NETUTIL_H
