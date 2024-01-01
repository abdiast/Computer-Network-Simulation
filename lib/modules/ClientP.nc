#include <Timer.h>
#include "../../includes/CommandMsg.h"
#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/socket.h"
#include "../../includes/tcpacket.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"

#define BUFFER_SIZE 1024
#define READ_SIZE 10

module ClientP{
    provides interface Client;
    uses interface SimpleSend as Sender;
    uses interface Random;
    uses interface Timer<TMilli> as ClientTimer;
    uses interface Transport;
    uses interface Hashmap<uint8_t> as ConnectionMap;
}

implementation{

    typedef struct server_t {
        uint8_t sockfd;
        uint8_t conns[MAX_NUM_OF_SOCKETS-1];
        uint8_t numConns;
        uint16_t bytesRead;
        uint16_t bytesWritten;
        uint8_t buffer[BUFFER_SIZE];
    } server_t;

    typedef struct client_t {
        uint8_t sockfd;
        uint16_t bytesWritten;
        uint16_t bytesTransferred;
        uint16_t counter;
        uint16_t transfer;
        uint8_t buffer[BUFFER_SIZE];
    } client_t;

    server_t server[MAX_NUM_OF_SOCKETS];
    client_t client[MAX_NUM_OF_SOCKETS];
    uint8_t numServers = 0;
    uint8_t numClients = 0;

    void handleServer();
    void handleClient();
    uint16_t serverOccupied(uint8_t x);
    uint16_t serverAvailable(uint8_t x);
    uint16_t clientOccupied(uint8_t x);
    uint16_t clientAvailable(uint8_t x);
    void zeroClient(uint8_t x);
    void zeroServer(uint8_t x);
    uint16_t min(uint16_t a, uint16_t b);

    command void Client.startServer(uint8_t port) {
        uint8_t i;
        uint32_t connId;
        socket_addr_t addr;
        if(numServers >= MAX_NUM_OF_SOCKETS) {
            dbg(TRANSPORT_CHANNEL, "Cannot start server\n");
            return;
        }
        for(i = 0; i < MAX_NUM_OF_SOCKETS; i++) {
            if(server[i].sockfd != 0)
                continue;
            server[i].sockfd = call Transport.socket();
            if(server[i].sockfd > 0) {
                // Set up
                addr.addr = TOS_NODE_ID;
                addr.port = port;
                // Bind the socket 
                if(call Transport.bind(server[i].sockfd, &addr) == SUCCESS) {
                    connId = ((uint32_t)addr.addr << 24) | ((uint32_t)addr.port << 16);
                    call ConnectionMap.insert(connId, i+1);
                    server[i].bytesRead = 0;
                    server[i].bytesWritten = 0;
                    server[i].numConns = 0;
                    if(call Transport.listen(server[i].sockfd) == SUCCESS && !(call ClientTimer.isRunning())) {
                        call ClientTimer.startPeriodic(1024 + (uint16_t) (call Random.rand16()%1000));
                    }
                    numServers++;
                    return;
                }
            }
        }
    }

    command void Client.startClient(uint8_t dest, uint8_t srcPort, uint8_t destPort, uint16_t transfer) {
        uint8_t i;
        uint32_t connId;
        socket_addr_t clientAddr;
        socket_addr_t serverAddr;
        // Check available space
        if(numClients >= MAX_NUM_OF_SOCKETS) {
            dbg(TRANSPORT_CHANNEL, "Cannot start client\n");
            return;
        }
        // Set up
        clientAddr.addr = TOS_NODE_ID;
        clientAddr.port = srcPort;
        serverAddr.addr = dest;
        serverAddr.port = destPort;
        for(i = 0; i < MAX_NUM_OF_SOCKETS; i++) {
            if(client[i].sockfd != 0) {
                continue;
            }
            client[i].sockfd = call Transport.socket();
            if(client[i].sockfd == 0) {
                dbg(TRANSPORT_CHANNEL, "No available sockets. Exiting!");
                return;
            }
            // Bind the socket 
            if(call Transport.bind(client[i].sockfd, &clientAddr) == FAIL) {
                dbg(TRANSPORT_CHANNEL, "Failed to bind sockets. Exiting!");
                return;
            }

            connId = ((uint32_t)TOS_NODE_ID << 24) | ((uint32_t)srcPort << 16);
            call ConnectionMap.insert(connId, i+1);
            // Connect to server
            if(call Transport.connect(client[i].sockfd, &serverAddr) == FAIL) {
                dbg(TRANSPORT_CHANNEL, "Failed to connect to server. Exiting!");
                return;
            }
            // Remove old connection
            call ConnectionMap.remove(connId);
            connId = ((uint32_t)TOS_NODE_ID << 24) | ((uint32_t)srcPort << 16) | ((uint32_t)dest << 16) | ((uint32_t)destPort << 16);
            call ConnectionMap.insert(connId, i+1);
            // Set up  for connection
            client[i].transfer = transfer;
            client[i].counter = 0;
            client[i].bytesWritten = 0;
            client[i].bytesTransferred = 0;

            if(!(call ClientTimer.isRunning())) {
                call ClientTimer.startPeriodic(1024 + (uint16_t) (call Random.rand16()%1000));
            }
            numClients++;
            return;
        }
    }

    command void Client.closeClient(uint8_t srcPort, uint8_t destPort, uint8_t dest) {
        uint32_t sockx, connId;
        connId = ((uint32_t)TOS_NODE_ID << 24) | ((uint32_t)srcPort << 16) | ((uint32_t)dest << 16) | ((uint32_t)destPort << 16);
        sockx = call ConnectionMap.get(connId);
        if(sockx == 0) {
            dbg(TRANSPORT_CHANNEL, "Client not found\n");
            return;
        }
        call Transport.close(client[sockx-1].sockfd);
        zeroClient(sockx-1);
        numClients--;
    }

    event void ClientTimer.fired() {
        handleServer();
        handleClient();
    }

    void handleServer() {
        uint8_t i, j, counter = 10, bytes = 0;
        uint8_t newFd;
        uint16_t data, length;
        bool isRead = FALSE;
        for(i = 0; i < numServers; i++) {
            if(server[i].sockfd == 0) {
                continue;
            }
            // Accept new connections
            newFd = call Transport.accept(server[i].sockfd);
            if(newFd > 0) {
                if(server[i].numConns < MAX_NUM_OF_SOCKETS-1) {
                    server[i].conns[server[i].numConns++] = newFd;
                }
            }
            for(j = 0; j < server[i].numConns; j++) {
                if(server[i].conns[j] != 0) {
                    if(serverAvailable(i) > 0) {
                        length = min((BUFFER_SIZE - server[i].bytesWritten), READ_SIZE);
                        bytes += call Transport.read(server[i].conns[j], &server[i].buffer[server[i].bytesWritten], length);
                        server[i].bytesWritten += bytes;
                        if(server[i].bytesWritten == BUFFER_SIZE) {
                            server[i].bytesWritten = 0;
                        }
                    }
                }
            }
            // Print data
            while(serverOccupied(i) >= 2) {
                if(!isRead) {
                    dbg(TRANSPORT_CHANNEL, "Reading ACK Data at %u: ", server[i].bytesRead);
                    isRead = TRUE;
                }
                if(server[i].bytesRead == BUFFER_SIZE) {
                    server[i].bytesRead = 0;
                }
                data = (((uint16_t)server[i].buffer[server[i].bytesRead+1]) << 8) | (uint16_t)server[i].buffer[server[i].bytesRead];
                printf("%u,", data);
                server[i].bytesRead += 2;
            }
            if(isRead)
                printf("\n");
        }
    }

    void handleClient() {
        uint8_t i;
        uint8_t counter = 10;
        uint16_t bytesTransferred, bytesToTransfer;
        for(i = 0; i < MAX_NUM_OF_SOCKETS; i++) {
            if(client[i].sockfd == 0)
                continue;
            // Writing to buffer
            while(clientAvailable(i) > 0 && client[i].counter < client[i].transfer) {
                if(client[i].bytesWritten == BUFFER_SIZE) {
                    client[i].bytesWritten = 0;
                }
                if((client[i].bytesWritten & 1) == 0) {
                    client[i].buffer[client[i].bytesWritten] = client[i].counter & 0xFF;
                } else {
                    client[i].buffer[client[i].bytesWritten] = client[i].counter >> 8;
                    client[i].counter++;
                }
                client[i].bytesWritten++;
            }
            // Writing to socket
            if(clientOccupied(i) > 0) {
                bytesToTransfer = min((BUFFER_SIZE - client[i].bytesTransferred), (client[i].bytesWritten - client[i].bytesTransferred));
                bytesTransferred = call Transport.write(client[i].sockfd, &client[i].buffer[client[i].bytesTransferred], bytesToTransfer);
                client[i].bytesTransferred += bytesTransferred;
            }
            if(client[i].bytesTransferred == BUFFER_SIZE)
                client[i].bytesTransferred = 0;
        }
    }

    void zeroClient(uint8_t x) {
        client[x].sockfd = 0;
        client[x].bytesWritten = 0;
        client[x].bytesTransferred = 0;
        client[x].counter = 0;
        client[x].transfer = 0;
    }

    void zeroServer(uint8_t x) {
        uint8_t i;
        server[x].sockfd = 0;
        server[x].bytesRead = 0;
        server[x].bytesWritten = 0;
        server[x].numConns = 0;
        for(i = 0; i < MAX_NUM_OF_SOCKETS-1; i++) {
            server[x].conns[i] = 0;
        }
    }

    uint16_t serverOccupied(uint8_t x) {
        if(server[x].bytesRead == server[x].bytesWritten) {
            return 0;
        } else if(server[x].bytesRead < server[x].bytesWritten) {
            return server[x].bytesWritten - server[x].bytesRead;
        } else {
            return (BUFFER_SIZE - server[x].bytesRead) + server[x].bytesWritten;
        }
    }

    uint16_t serverAvailable(uint8_t x) {
        return BUFFER_SIZE - serverOccupied(x) - 1;
    }


    uint16_t clientOccupied(uint8_t x) {
        if(client[x].bytesTransferred == client[x].bytesWritten) {
            return 0;
        } else if(client[x].bytesTransferred < client[x].bytesWritten) {
            return client[x].bytesWritten - client[x].bytesTransferred;
        } else {
            return (BUFFER_SIZE - client[x].bytesTransferred) + client[x].bytesWritten;
        }
    }

    uint16_t clientAvailable(uint8_t x) {
        return BUFFER_SIZE - clientOccupied(x) - 1;
    }

    uint16_t min(uint16_t a, uint16_t b) {
        if(a <= b)
            return a;
        else
            return b;
    }

}