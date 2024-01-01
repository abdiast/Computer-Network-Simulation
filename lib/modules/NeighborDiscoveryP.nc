#include <Timer.h>
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"
#include "../../includes/channels.h"

#define ND_TTL  5

module NeighborDiscoveryP {
    provides interface NeighborDiscovery;
    uses interface Timer<TMilli> as NeighborDiscoveryTimer;
    uses interface Random as Random;
    uses interface SimpleSend as Sender;
    uses interface Hashmap<uint32_t> as Neighbors;
    uses interface DistanceVectorRouting as DistanceVectorRouting;
    //uses interface Flooding as Sender;
}

implementation {
    // Number of missed replies before dropping a neighbor
    pack sendPackage;
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

    command error_t NeighborDiscovery.start() {
        call NeighborDiscoveryTimer.startPeriodic(10000 + (uint16_t) (call Random.rand16()%1000));
        dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery Started on node %u!\n", TOS_NODE_ID);
    }

    command void NeighborDiscovery.handleNeighbor(pack* myMsg) {
        // Neighbor Discovery packet received
        if(myMsg->protocol == PROTOCOL_PING && myMsg->TTL > 0) {
            myMsg->TTL -= 1;
            myMsg->src = TOS_NODE_ID;
            myMsg->protocol = PROTOCOL_PINGREPLY;
            call Sender.send(*myMsg, AM_BROADCAST_ADDR);
            dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery PING!\n");
        } else if(myMsg->protocol == PROTOCOL_PINGREPLY && myMsg->dest == 0) {
            dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery PINGREPLY! Found Neighbor %d\n", myMsg->src);
            if(!call Neighbors.contains(myMsg->src)) {
                call Neighbors.insert(myMsg->src, ND_TTL);
                call DistanceVectorRouting.handleNeighborFound();
            } else {
                call Neighbors.insert(myMsg->src, ND_TTL);
            }
        }
    }

    event void NeighborDiscoveryTimer.fired() {
        uint16_t i = 0;
        uint8_t payload = 0;
        uint32_t* keys = call Neighbors.getKeys();
        call NeighborDiscovery.printNeighbors();
        // Remove old neighbors
        for(; i < call Neighbors.size(); i++) {
            if(keys[i] == 0) {
                continue;
            }
            if(call Neighbors.get(keys[i]) == 0) {
                dbg(NEIGHBOR_CHANNEL, "Removing Neighbor %d\n", keys[i]);
                call DistanceVectorRouting.handleNeighborLost(keys[i]);
                call Neighbors.remove(keys[i]);
            } else {
                call Neighbors.insert(keys[i], call Neighbors.get(keys[i])-1);
            }
        }
        // Send out a new neighbor discovery ping
        makePack(&sendPackage, TOS_NODE_ID, 0, 1, PROTOCOL_PING, 0, &payload, PACKET_MAX_PAYLOAD_SIZE);
        call Sender.send(sendPackage, AM_BROADCAST_ADDR);
    }

    //Returns list of neighbors.
    command uint32_t* NeighborDiscovery.Neighbors_list() {
        return call Neighbors.getKeys();
    }
    //return number of neighbors
    command uint16_t NeighborDiscovery.Neighbors_num() {
        return call Neighbors.size();
    }
    //prints list of neighbors at node n
    command void NeighborDiscovery.printNeighbors() {
        uint16_t i;
        uint32_t* neighbors = call NeighborDiscovery.Neighbors_list();

        dbg(NEIGHBOR_CHANNEL, "---Listing Neighbors of Node %d---\n", TOS_NODE_ID);
        for (i = 0; i < call NeighborDiscovery.Neighbors_num(); i++) {
            if(neighbors[i] != TOS_NODE_ID)
			{
				dbg(NEIGHBOR_CHANNEL, "%d\n", neighbors[i]);
			}
           
        }
        dbg(NEIGHBOR_CHANNEL, "----------------------------------\n");
    }
     void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length) {
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }
}
// uses pingTest.py to run it in tinyos