//
// Created on 2025/8/29.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "socket_info.h"

SocketInfo::SocketInfo(int fd) {
    this->fd = fd;
    this->host = "null";
    this->ip = "";
    this->port = 0;
    this->tx = 0;
    this->rx = 0;
}

void SocketInfo::onSend(int fd, size_t len) {
    if (len > 0) {
        this->tx += len;
    }
}

void SocketInfo::onRecv(int fd, size_t len) {
    if (len > 0) {
        this->rx += len;
    }
}

void SocketInfo::setHost(const std::string &host) {
    this->host = host;
}

void SocketInfo::setIp(const char *ip) {
    return;
}

void SocketInfo::setPort(unsigned short port) {
    this->port = port;
}

const std::string &SocketInfo::getHost() const { return this->host; }

const std::string &SocketInfo::getIp() const { return this->ip; }

unsigned short SocketInfo::getPort() const { return this->port; }

int SocketInfo::getFd() const { return this->fd; }

size_t SocketInfo::getTx() const { return this->tx; }

size_t SocketInfo::getRx() const { return this->rx; }

size_t SocketInfo::getSum() const { return this->rx + this->tx; }

std::string SocketInfo::toString() const {
    return this->host + "," + 
            std::to_string(this->tx) + "," + 
            std::to_string(this->rx);
}
