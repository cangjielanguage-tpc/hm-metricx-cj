//
// Created on 2025/9/4.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef TPCAPPLICATION_TRAFFIC_PARSER_H
#define TPCAPPLICATION_TRAFFIC_PARSER_H

#include "http_parser/http_parser.h"

int on_message_begin(http_parser *_);
int on_url(http_parser *_, const char *at, size_t length);
int on_status(http_parser *_, const char *at, size_t length);
int on_header_field(http_parser *_, const char *at, size_t length);
int on_header_value(http_parser *_, const char *at, size_t length);
int on_headers_complete(http_parser *_);
int on_body(http_parser *_, const char *at, size_t length);
int on_message_complete(http_parser *_);
int on_chunk_header(http_parser *_);
int on_chunk_complete(http_parser *_);

size_t parser_data(const void *data, size_t len);
int initHttpParser();

#endif //TPCAPPLICATION_TRAFFIC_PARSER_H
