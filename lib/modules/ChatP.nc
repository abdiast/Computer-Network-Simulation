//after this class, the people who know this code is me and god. soon to be just god
// hour wastes: 37

#include <string.h>
#include <Timer.h>
#include "../../includes/CommandMsg.h"
#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/socket.h"
#include "../../includes/tcpacket.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"
//#include "../../includes/chat.h"

#define CHAT_USERNAME_MAX_LENGTH 128
#define CHAT_MAX_CONS 5
#define BUFFER_SIZE 256
#define SERVER_NODE 1
#define CHAT_S_PORT 50
#define CHAT_MAX_USER 1024

module ChatP{
    provides interface Chat;

    uses interface SimpleSend as Sender;
    uses interface Random;
    uses interface Timer<TMilli> as ChatTimer;
    uses interface Transport;
    uses interface Hashmap<uint8_t> as connections;
}

implementation{

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
        char sendBuffer[BUFFER_SIZE];
        uint8_t RRead;
        uint8_t RWritten;
        char message[BUFFER_SIZE];
        char username[CHAT_USERNAME_MAX_LENGTH];
    } chat_conn_t;

    typedef struct chat_app_t {
        enum conn_type state;
        uint8_t numOfConns;
        uint8_t listenSockFd;
        chat_conn_t connections[CHAT_MAX_CONS];
    } chat_app_t;

    chat_app_t chatApp;
    //functions
    //uint32_t min(uint32_t a, uint32_t b);
    bool startsWith(char* a, char* b);
    void getCommand(uint8_t index);
    uint16_t getRBufferAvailable(uint8_t i);
    uint16_t getRBufferOccupied(uint8_t i);
    uint16_t getSBufferAvailable(uint8_t i);
    uint16_t getSBufferOccupied(uint8_t i);
    // uint8_t consAvailable();
    void sendHello(uint8_t clientPort);

   
    //interface commands/event

    event void ChatTimer.fired() {
        uint8_t i;
        uint8_t newReadFd, bytes;
        socket_addr_t addr;
        // If chatApp.state == SERVER
        if(chatApp.state == SERVER) {
            // Accept new connections
            newReadFd = call Transport.accept(chatApp.listenSockFd);
            if(newReadFd > 0) {
                for(i = 0; i < CHAT_MAX_CONS; i++) {
                    if(chatApp.connections[i].readFd == 0) {
                        chatApp.connections[i].readFd = newReadFd;
                        chatApp.connections[i].writeFd = call Transport.socket();
                        if(chatApp.connections[i].writeFd == 0) {
                            // Error
                            dbg(CHAT_CHANNEL, "Can't obtain socket. RIP!");
                            break;
                        }
                        addr.addr = TOS_NODE_ID;
                        addr.port = 100+i;
                        if(call Transport.bind(chatApp.connections[i].writeFd, &addr) == FAIL) {
                            dbg(CHAT_CHANNEL, "Can't bind socket. RIP!");
                            break;
                        }
                        // Get connection info and open a connection to the client
                        addr.addr = call Transport.getConnectionDest(newReadFd);
                        addr.port = CHAT_S_PORT;
                        // dbg(CHAT_CHANNEL, "newReadFd %u\n", newReadFd);
                        dbg(CHAT_CHANNEL, "Connecting back to client %u\n", addr.addr);
                        if(call Transport.connect(chatApp.connections[i].writeFd, &addr) == FAIL) {
                            dbg(CHAT_CHANNEL, "Can't connect to Server. RIP!");
                            break;
                        }
                        chatApp.connections[i].sendRead = 0;
                        chatApp.connections[i].sendWritten = 0;
                        break;
                    }
                }
            }
            // Read on file descriptors
            for(i = 0; i < CHAT_MAX_CONS; i++) {
                if(chatApp.connections[i].readFd != 0) {
                    // Read and check for \r\n
                    bytes = 1;
                    while(getRBufferAvailable(i) > 0 && bytes > 0) {
                        bytes = call Transport.read(chatApp.connections[i].readFd, &chatApp.connections[i].message[chatApp.connections[i].RWritten % BUFFER_SIZE], 1);
                        // call process command if \r\n
                        if(chatApp.connections[i].message[chatApp.connections[i].RWritten % BUFFER_SIZE] == '\n' && chatApp.connections[i].message[(chatApp.connections[i].RWritten-1) % BUFFER_SIZE] == '\r') {
                            chatApp.connections[i].message[chatApp.connections[i].RWritten+1 % BUFFER_SIZE] = '\0';
                            // dbg(CHAT_CHANNEL, "Processing %s", (char*)&chatApp.connections[i].message[chatApp.connections[i].RRead%BUFFER_SIZE]);
                            getCommand(i);
                        }
                        chatApp.connections[i].RWritten += bytes;
                    }
                }
                // Write to fd!
                if(chatApp.connections[i].writeFd != 0) {
                    bytes = 1;
                    while(getSBufferOccupied(i) > 0 && bytes > 0) {
                        bytes = call Transport.write(chatApp.connections[i].writeFd, &chatApp.connections[i].sendBuffer[chatApp.connections[i].sendRead % BUFFER_SIZE], 1);
                        // if(bytes > 0)
                        //     dbg(CHAT_CHANNEL, "SERVER: Writing %d to socket\n", chatApp.connections[i].sendBuffer[chatApp.connections[i].sendRead % BUFFER_SIZE]);
                        chatApp.connections[i].sendRead += bytes;
                    }
                }
            }
        // Else chatApp.state == CLIENT
        } else {
            // Accept new connections
            newReadFd = call Transport.accept(chatApp.listenSockFd);
            if(newReadFd > 0 && chatApp.connections[0].readFd == 0) {
                dbg(CHAT_CHANNEL, "CLIENT: server return connection is set up with socket %u\n", newReadFd);
                chatApp.connections[0].readFd = newReadFd;
                chatApp.connections[0].RRead = 0;
                chatApp.connections[0].RWritten = 0;
            } else {
                // Write to writeFd from sendBuffer
                if(getSBufferOccupied(0) > 0) {
                    // dbg(CHAT_CHANNEL, "CLIENT node %u: writing to fd, %u\n", TOS_NODE_ID, getSBufferOccupied(0));
                    bytes = call Transport.write(chatApp.connections[0].writeFd, &chatApp.connections[0].sendBuffer[chatApp.connections[0].sendRead % BUFFER_SIZE], getSBufferOccupied(0));
                    chatApp.connections[0].sendRead += bytes;
                }
                //check for termination \r\n
                bytes = 1;
                while(getRBufferAvailable(0) > 0 && bytes > 0) {
                    bytes = call Transport.read(chatApp.connections[0].readFd, &chatApp.connections[0].message[chatApp.connections[0].RWritten % BUFFER_SIZE], 1);
                    // Print message if end
                    if(chatApp.connections[0].message[chatApp.connections[0].RWritten % BUFFER_SIZE] == '\n' && chatApp.connections[0].message[(chatApp.connections[0].RWritten-1) % BUFFER_SIZE] == '\r') {
                        chatApp.connections[0].message[chatApp.connections[0].RWritten % BUFFER_SIZE] = '\0';
                        dbg(CHAT_CHANNEL, "CLIENT: %s\n", &chatApp.connections[0].message[chatApp.connections[0].RRead % BUFFER_SIZE]);
                        chatApp.connections[0].RRead = chatApp.connections[0].RWritten + 1;
                    }
                    chatApp.connections[0].RWritten += bytes;                    
                }
            }
        }
    }

    command void Chat.startChatServer() {
        uint8_t i;
        socket_addr_t addr;
        if(chatApp.state == CLIENT || chatApp.listenSockFd > 0) {
            dbg(CHAT_CHANNEL, "RIP Server\n");
            return;
        }
        chatApp.state = SERVER;
        chatApp.listenSockFd = call Transport.socket();
        if(chatApp.listenSockFd > 0) {
            // Listen on port 50
            addr.addr = TOS_NODE_ID;
            addr.port = CHAT_S_PORT;
            // Bind the socket to the src address
            if(call Transport.bind(chatApp.listenSockFd, &addr) == SUCCESS) {
                // Listen on the port and start a timer if needed
                if(call Transport.listen(chatApp.listenSockFd) == SUCCESS && !(call ChatTimer.isRunning())) {
                    call ChatTimer.startPeriodic(1024 + (uint16_t) (call Random.rand16()%1000));
                }
            }
        }
    }
    
    

    command void Chat.chat(char* message) {
        uint16_t len = strlen(message);
        uint8_t i = len-3;
        uint8_t port = 0;
        uint8_t count = 1;

        dbg(CHAT_CHANNEL, "CLIENT: Sending %s", message);
        if(message[len-1] != '\n' || message[len-2] != '\r') {
            dbg(CHAT_CHANNEL, "Chat message: incorrectly ended RIP\n");
            return;
        }
        if(startsWith(message, "hello ")) {
            if(len < 12) {
                dbg(CHAT_CHANNEL, "Chat message: hello too short\n");
                return;
            }
            dbg(CHAT_CHANNEL, "Sending hello! to Server\n");
            // String to int to get port
            while(message[i] != ' ') {
                if(message[i] < '0' || message[i] > '9') {
                    dbg(CHAT_CHANNEL, "Chat message: ports is not a number RIP\n");
                    return;
                }
                port += (message[i]-'0') * (count);
                count *= 10;
                i--;
            }
            sendHello(port);
            // Truncate msg to exclude port
            message[i] = '\r';
            message[i+1] = '\n';
            len = i+1;
            i = 0;
            while(i <= len) {
                memcpy(&chatApp.connections[0].sendBuffer[chatApp.connections[0].sendWritten++ % BUFFER_SIZE], message+i, 1);
                i++;
            }
        } else if(startsWith(message, "msg ") || startsWith(message, "whisper ") || startsWith(message, "listusr\r\n")) {
            if(chatApp.state != CLIENT) {
                dbg(CHAT_CHANNEL, "Chat message: say hello first or RIP\n");
                return;
            }
            i = 0;
            while(i <= len-1) {                
                memcpy(&chatApp.connections[0].sendBuffer[chatApp.connections[0].sendWritten++ % BUFFER_SIZE], message+i, 1);
                // dbg(CHAT_CHANNEL, "Char written: %d\n", chatApp.connections[0].sendBuffer[(chatApp.connections[0].sendWritten-1) % BUFFER_SIZE]);
                i++;
            }
        } else {
            dbg(CHAT_CHANNEL, "Chat message: RIP command format\n");
        }
    } 

    // SERVER
    bool startsWith(char* a, char* b) {
        // uint8_t i = 0;
        uint8_t len = strlen(b);
        // for ( i = len -1; i>0; i--) {
        //     if(a[len] != b[len]) {
        //         return FALSE;
        //     }
        // }
        while(len-- != 0) {
            if(a[len] != b[len]) {
                return FALSE;
            }
        }
        return TRUE;
    }

    // SERVER
    // % prevent overflow
    void getCommand(uint8_t index) {
        char usrList[CHAT_MAX_USER];
        uint8_t i, j;        
        // If HELLO
        if(startsWith(&chatApp.connections[index].message[chatApp.connections[index].RRead % BUFFER_SIZE], "hello ")) {
            i = 0;
            while(chatApp.connections[index].message[(chatApp.connections[index].RRead + 6 + i) % BUFFER_SIZE] != '\r') {
                chatApp.connections[index].username[i] = chatApp.connections[index].message[(chatApp.connections[index].RRead + 6 + i) % BUFFER_SIZE];
                i++;
            }
            chatApp.connections[index].username[i] = '\0';
            dbg(CHAT_CHANNEL, "SERVER: Received hello from %s\n", chatApp.connections[index].username);
            chatApp.connections[index].RRead += 6 + i + 2;
        //MSG
        }
        else if(startsWith(&chatApp.connections[index].message[chatApp.connections[index].RRead % BUFFER_SIZE], "msg ")) {
            // Broadcasting
            dbg(CHAT_CHANNEL, "SERVER: Received msg from %s\n", chatApp.connections[index].username);
            for(i = 0; i < CHAT_MAX_CONS; i++) {
                if(chatApp.connections[i].writeFd > 0 && index != i) {
                    j = 0;
                    while(1) {
                        chatApp.connections[i].sendBuffer[(chatApp.connections[i].sendWritten++)%BUFFER_SIZE] = chatApp.connections[index].message[(chatApp.connections[index].RRead+j)%BUFFER_SIZE];
                        if(j > 0 && chatApp.connections[index].message[(chatApp.connections[index].RRead+j)%BUFFER_SIZE] == '\n' && chatApp.connections[index].message[(chatApp.connections[index].RRead+j-1)%BUFFER_SIZE] == '\r') {
                            break;
                        }
                        j++;
                    }
                    dbg(CHAT_CHANNEL, "SERVER: Broadcasting to %s\n", &chatApp.connections[i].username);
                }
            }
            chatApp.connections[index].RRead += j + 1;
        //WHISPER
        } else if(startsWith(&chatApp.connections[index].message[chatApp.connections[index].RRead%BUFFER_SIZE], "whisper ")) {
            dbg(CHAT_CHANNEL, "SERVER: Received whisper from %s\n", chatApp.connections[index].username);
            //Unicasting 
            for(i = 0; i < CHAT_MAX_CONS; i++) {                
                if(chatApp.connections[i].writeFd > 0 && startsWith(&chatApp.connections[index].message[(chatApp.connections[index].RRead+8)%BUFFER_SIZE], &chatApp.connections[i].username)) {
                    dbg(CHAT_CHANNEL, "SERVER: Found user %s\n", chatApp.connections[i].username);
                    j = 0;
                    while(TRUE) {
                        chatApp.connections[i].sendBuffer[(chatApp.connections[i].sendWritten++)%BUFFER_SIZE] = chatApp.connections[index].message[(chatApp.connections[index].RRead+j)%BUFFER_SIZE];
                        if(j > 0 && chatApp.connections[index].message[(chatApp.connections[index].RRead+j)%BUFFER_SIZE] == '\n' && chatApp.connections[index].message[(chatApp.connections[index].RRead+j-1)%BUFFER_SIZE] == '\r') {
                            break;
                        }
                        j++;
                    }
                }
            }
            chatApp.connections[index].RRead += j + 1;
        //LISTUSR
        } else if(startsWith(&chatApp.connections[index].message[chatApp.connections[index].RRead%BUFFER_SIZE], "listusr\r\n")) {
            dbg(CHAT_CHANNEL, "SERVER: Received listusr from %s\n", chatApp.connections[index].username);
            usrList[0] = NULL;
            strcat(usrList, "usrListReply");
            //print users
            for(i = 0; i < CHAT_MAX_CONS; i++) {
                if(chatApp.connections[i].readFd > 0 && chatApp.connections[i].username[0] != NULL) {
                    strcat(usrList, " ");
                    strcat(usrList, chatApp.connections[i].username);
                }
            }
            // users + termination
            strcat(usrList, "\r\n");
            j = 0;
            while(j < strlen(usrList)) {
                chatApp.connections[index].sendBuffer[(chatApp.connections[index].sendWritten++)%BUFFER_SIZE] = usrList[j++];
            }
            chatApp.connections[index].RRead += 9;
        }
    }

    uint16_t getRBufferAvailable(uint8_t i) {
        if(chatApp.connections[i].RRead <= chatApp.connections[i].RWritten)
            return BUFFER_SIZE - (chatApp.connections[i].RWritten%BUFFER_SIZE) + (chatApp.connections[i].RRead%BUFFER_SIZE) - 1;
        else
            return (chatApp.connections[i].RRead%BUFFER_SIZE) - (chatApp.connections[i].RWritten%BUFFER_SIZE) - 1;
    }

    uint16_t getRBufferOccupied(uint8_t i) {
        if(chatApp.connections[i].RRead <= chatApp.connections[i].RWritten)
            return (chatApp.connections[i].RWritten%BUFFER_SIZE) - (chatApp.connections[i].RRead%BUFFER_SIZE);
        else
            return BUFFER_SIZE - (chatApp.connections[i].RRead%BUFFER_SIZE) + (chatApp.connections[i].RWritten%BUFFER_SIZE);
    }

    uint16_t getSBufferAvailable(uint8_t i) {
        if(chatApp.connections[i].sendRead <= chatApp.connections[i].sendWritten)
            return BUFFER_SIZE - (chatApp.connections[i].sendWritten%BUFFER_SIZE) + (chatApp.connections[i].sendRead%BUFFER_SIZE) - 1;
        else
            return (chatApp.connections[i].sendRead%BUFFER_SIZE) - (chatApp.connections[i].sendWritten%BUFFER_SIZE) - 1;
    }

    uint16_t getSBufferOccupied(uint8_t i) {
        if(chatApp.connections[i].sendRead <= chatApp.connections[i].sendWritten)
            return (chatApp.connections[i].sendWritten%BUFFER_SIZE) - (chatApp.connections[i].sendRead%BUFFER_SIZE);
        else
            return BUFFER_SIZE - (chatApp.connections[i].sendRead%BUFFER_SIZE) + (chatApp.connections[i].sendWritten%BUFFER_SIZE);
    }

    // CLIENT
    // supHandled
    void sendHello(uint8_t clientPort) {
        uint8_t i;
        socket_addr_t addr;
        if(chatApp.state != OFF || chatApp.listenSockFd > 0) {
            dbg(CHAT_CHANNEL, "Cannot start client\n");
            return;
        }
        // Listen on port 50
        chatApp.state = CLIENT;
        chatApp.listenSockFd = call Transport.socket();
        if(chatApp.listenSockFd > 0) {
                addr.addr = TOS_NODE_ID;
                addr.port = CHAT_S_PORT;
                // Bind the socket to the src address
                if(call Transport.bind(chatApp.listenSockFd, &addr) == SUCCESS) {
                    // Listen on the port and start a timer if needed
                    if(call Transport.listen(chatApp.listenSockFd) == SUCCESS && !(call ChatTimer.isRunning())) {
                        dbg(CHAT_CHANNEL, "Node %u listening on port 50\n", TOS_NODE_ID);
                        call ChatTimer.startPeriodic(1024 + (uint16_t) (call Random.rand16()%1000));
                    }
                } else {
                    dbg(CHAT_CHANNEL, "Can't blind socket\n");
                }
        } else {
            dbg(CHAT_CHANNEL, "Can't obtain socket\n");
        }
        // Start client connection to node 1 on port 50
        addr.port = clientPort;
        chatApp.connections[0].writeFd = call Transport.socket();
        if(chatApp.connections[0].writeFd == 0) {
            dbg(CHAT_CHANNEL, "No sockets?. why don't you go outside get some sockets RIP!");
            return;
        }
        // Bind the socket to the src address
        if(call Transport.bind(chatApp.connections[0].writeFd, &addr) == FAIL) {
            dbg(CHAT_CHANNEL, "Can't blind socket. RIP!");
            return;
        }
        addr.addr = SERVER_NODE;
        addr.port = CHAT_S_PORT;
        // Connect to the remote server
        if(call Transport.connect(chatApp.connections[0].writeFd, &addr) == FAIL) {
            dbg(CHAT_CHANNEL, "Can't connect to Server. RIP!");
            return;
        }
        chatApp.connections[0].sendRead = 0;
        chatApp.connections[0].sendWritten = 0;
        if(!(call ChatTimer.isRunning())) {
            call ChatTimer.startPeriodic(1024 + (uint16_t) (call Random.rand16()%1000));
        }
    }
    
    
}