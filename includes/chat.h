#ifndef __TCP_H__
#define __TCP_H__

#include "protocol.h"
#include "channels.h"

#define CHAT_USERNAME_MAX_LENGTH 128
#define CHAT_APP_MAX_CONNS 5
#define CHAT_APP_BUFFER_SIZE 256
#define CHAT_APP_SERVER_ID 1
#define CHAT_APP_SERVER_PORT 41

    enum conn_type {
        OFF,
        SERVER,
        CLIENT
    };

    enum msg_type {
        HELLO,
        MSG,
        WHISPER,
        LISTUSR
    };

    typedef struct chat_conn_t {
        uint8_t readFd;
        uint8_t writeFd;
        uint8_t sendRead;
        uint8_t sendWritten;
        char sendBuffer[CHAT_APP_BUFFER_SIZE];
        uint8_t rcvdRead;
        uint8_t rcvdWritten;
        char rcvdBuffer[CHAT_APP_BUFFER_SIZE];
        char username[CHAT_USERNAME_MAX_LENGTH];
    } chat_conn_t;

    typedef struct chat_app_t {
        enum conn_type type;
        uint8_t numOfConns;
        uint8_t listenSockFd;
        chat_conn_t connections[CHAT_APP_MAX_CONNS];
    } chat_app_t;
#endif