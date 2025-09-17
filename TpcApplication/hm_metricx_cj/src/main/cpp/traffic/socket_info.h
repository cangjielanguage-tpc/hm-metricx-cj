//
// Created on 2025/8/29.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef TPCAPPLICATION_TRAFFIC_SOCKET_INFO_H
#define TPCAPPLICATION_TRAFFIC_SOCKET_INFO_H

#include <string>

class SocketInfo {
public:
    SocketInfo(int fd);
    void onSend(int fd, size_t len);
    void onRecv(int fd, size_t len);
    void setHost(const std::string &host);
    void setIp(const char *ip);
    void setPort(unsigned short por);
    const std::string& getHost() const;
    const std::string& getIp() const;
    unsigned short getPort() const;
    int getFd() const;
    size_t getTx() const;
    size_t getRx() const;
    size_t getSum() const;
    std::string toString() const;
private:
    std::string host;
    std::string ip;
    unsigned short port;
    int fd;
    size_t tx;
    size_t rx;
};

#endif //TPCAPPLICATION_TRAFFIC_SOCKET_INFO_H
