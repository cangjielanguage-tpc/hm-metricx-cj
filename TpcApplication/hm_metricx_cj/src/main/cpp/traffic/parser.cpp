//
// Created on 2025/9/4.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "parser.h"
#include "common.h"
#include "http_parser/http_parser.h"
#include <iostream>

int on_message_begin(http_parser *_) {
    (void)_;
    OH_LOG_Print(LOG_APP, LOG_WARN, 0x00008, "http_parser", "message begin");
    return 0;
}

int on_url(http_parser *_, const char *at, size_t length) {
    (void)_;
    std::string url = std::string(at, length);
    OH_LOG_Print(LOG_APP, LOG_WARN, 0x00008, "http_parser", "url: %{public}s", url.c_str());
    return 0;
}

int on_status(http_parser *_, const char *at, size_t length) {
    (void)_;
    std::string url = std::string(at, length);
    OH_LOG_Print(LOG_APP, LOG_WARN, 0x00008, "http_parser", "status: %{public}s", url.c_str());
    return 0;
}

int on_header_field(http_parser *_, const char *at, size_t length) {
    (void)_;
    std::string field = std::string(at, length);
    OH_LOG_Print(LOG_APP, LOG_WARN, 0x00008, "http_parser", "header_field: %{public}s", field.c_str());
    return 0;
}

int on_header_value(http_parser *_, const char *at, size_t length) {
    (void)_;
    std::string value = std::string(at, length);
    OH_LOG_Print(LOG_APP, LOG_WARN, 0x00008, "http_parser", "header_value: %{public}s", value.c_str());
    return 0;
}

int on_headers_complete(http_parser *_) {
    (void)_;
    OH_LOG_Print(LOG_APP, LOG_WARN, 0x00008, "http_parser", "headers complete");
    return 0;
}

int on_body(http_parser *_, const char *at, size_t length) {
    (void)_;
    std::string body = std::string(at, length);
    OH_LOG_Print(LOG_APP, LOG_WARN, 0x00008, "http_parser", "body: %{public}s", body.c_str());
    return 0;
}

int on_message_complete(http_parser *_) {
    (void)_;
    OH_LOG_Print(LOG_APP, LOG_WARN, 0x00008, "hm_metricx_cj", "http_parser: message complete");
    return 0;
}

int on_chunk_header(http_parser *_) {
    (void)_;
    OH_LOG_Print(LOG_APP, LOG_WARN, 0x00008, "http_parser", "chunk_header");
    return 0;
}

int on_chunk_complete(http_parser *_) {
    (void)_;
    OH_LOG_Print(LOG_APP, LOG_WARN, 0x00008, "http_parser", "chunk_complete");
    return 0;
}

void testHttpParser() {
    std::string strHttpReq;
    size_t http_ret;
//    strHttpReq += "POST /http-parser HTTP/1.1\r\n";
//    strHttpReq += "Host: 127.0.0.1:10010\r\n";
//    strHttpReq += "Accept: */*\r\n";
//    strHttpReq += "Content-Type: application/json\r\n";
//    strHttpReq += "Content-Length: 25\r\n";
//    strHttpReq += "\r\n";
//    strHttpReq += "{\"reqmsg\": \"Hello World\"}";
    
    strHttpReq += "GET /hello HTTP/1.1\r\n";
    strHttpReq += "host: example.com:80\r\n";
    strHttpReq += "user-agent: CANGJIEUSERAGENT_1_10\r\n";
    strHttpReq += "connection: keep-alive\r\n";
    strHttpReq += "content-length: 0\r\n";
    strHttpReq += "\r\n";
    
    http_ret = parser_data(strHttpReq.c_str(), strHttpReq.size());
    
    strHttpReq = "";
//    strHttpReq += "GET /hello HTTP/1.1\r\n";
//    strHttpReq += "Host: example.com\r\n";
//    strHttpReq += "User-Agent: libcurl-agent/1.0\r\n";
//    strHttpReq += "Accept: */*\r\n";
//    strHttpReq += "Accept-Encoding: deflate, gzip, br\r\n";
//    strHttpReq += "\r\n";
    
    strHttpReq += "GET /hello HTTP/1.1\r\n";
    strHttpReq += "host: example.com:80\r\n";
    strHttpReq += "user-agent: CANGJIEUSERAGENT_1_10\r\n";
    strHttpReq += "connection: keep-alive\r\n";
    strHttpReq += "content-length: 0\r\n";
    strHttpReq += "\r\n";

    http_ret = parser_data(strHttpReq.c_str(), strHttpReq.size());
    
    OH_LOG_Print(LOG_APP, LOG_WARN, 0x00008, "http_parser", 
                 "parser tese done"
                 );
    return;
}

static http_parser *parser = nullptr;
static http_parser_settings settings;

size_t parser_data(const void *data, size_t len) {
    size_t parsed;
    parsed = http_parser_execute(parser, &settings, (char *)data, len); // 执行解析过程
    OH_LOG_Print(LOG_APP, LOG_WARN, 0x00008, "http_parser",
                 "parser_len: %{public}d, method: %{public}d, status_code: %{public}d, http_errno: %{public}d", 
                 parsed, parser->method, parser->status_code, parser->http_errno);
    if (parsed == 0) {
        enum http_errno err = HTTP_PARSER_ERRNO(parser);
        OH_LOG_Print(LOG_APP, LOG_WARN, 0x00008, "http_parser", "error: %{public}s: %{public}s",
                     http_errno_name(err), http_errno_description(err));
    } else {
        OH_LOG_Print(LOG_APP, LOG_WARN, 0x00008, "http_parser", "success");
    }
    char empty_buf[0];
    http_parser_execute(parser, &settings, empty_buf, 0);            // 信息读取完毕
    http_parser_init(parser, HTTP_BOTH);
    return parsed;
}

int initHttpParser() {
    parser = (http_parser *)malloc(sizeof(http_parser)); // 分配一个http_parser

    http_parser_init(parser, HTTP_BOTH);
    http_parser_settings_init(&settings);

    settings.on_message_begin = on_message_begin;
    settings.on_url = on_url;
    settings.on_status = on_status;
    settings.on_header_field = on_header_field;
    settings.on_header_value = on_header_value;
    settings.on_headers_complete = on_headers_complete;
    settings.on_body = on_body;
    settings.on_message_complete = on_message_complete;
    settings.on_chunk_header = on_chunk_header;
    settings.on_chunk_complete = on_chunk_complete;
    testHttpParser();
    return 0;
}
