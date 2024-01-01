// #define MAX_ROUTES      128     /* maximum size of routing			
//                                      table */
//   #define MAX_TTL         120     /* time (in seconds) until
//                                      route expires */

//   typedef struct {
//       NodeAddr  Destination;    /* address of destination */
//       NodeAddr  NextHop;        /* address of next hop */
//       int        dist;          /* distance metric */
//       u_short   TTL;            /* time to live */
//   } Route;

//   int      numRoutes = 0;
//   Route    routingTable[MAX_ROUTES];
// The routine that updates the local node's routing table based on a new route is given by mergeRoute. Although not shown, a timer function periodically scans the list of routes in the node's routing table, decrements the TTL (time to live) field of each route, and discards any routes that have a time to live of 0. Note, however, that the TTL field is reset to MAX_TTL any time the route is reconfirmed by an update message from a neighboring node.

//   void			
//   mergeRoute (Route *new)
//   {
//       int i;

//       for (i = 0; i < numRoutes; ++i)
//       {
//           if (new->Destination == routingTable[i].Destination)
//           {
//               if (new->dist + 1 < routingTable[i].dist)
//               {
//                   /* found a better route: */
//                   break;
//               } else if (new->NextHop ==
//                          routingTable[i].NextHop) {
//                   /* metric for current next-hop may have
//                      changed: */
//                   break;
//               } else {
//                   /* route is uninteresting---just ignore it */
//                   return;
//               }
//           }
//       }
//       if (i == numRoutes)
//       {
//           /* this is a completely new route; is there room
//              for it? */
//           if (numRoutes < MAXROUTES)
//           {
//               ++numRoutes;
//           } else {
//               /* can{`t fit this route in table so give up */}
//               return;
//           }
//       }
//       routingTable[i] = *new;
//       /* reset TTL */
//       routingTable[i].TTL = MAX_TTL;
//       /* account for hop to get to next node */
//       ++routingTable[i].dist;
//   }

// Finally, the procedure updateRoutingTable is the main routine that calls mergeRoute to incorporate all the routes contained in a routing update that is received from a neighboring node.

//   void			
//   updateRoutingTable (Route *newRoute, int numNewRoutes)
//   {
//       int i;

//       for (i=0; i < numNewRoutes; ++i)
//       {
//           mergeRoute(&newRoute[i]);
//       }
//   }
//-------------------Route Calculation
// M = {s }

// for each n in N - {s }

//  C(n) = l(s,n)

// while (N != M)

//  M = M + {w } such that C(w) is the minimum for all w in (N -M)

//  for each n in (N -M)

//  C(n) = MIN(C(n), C(w)+l(w,n))

//---------------------------------References from the book---------------------------------------------------------------------------------------------------------


// event message_t *Receiver.receive(message_t * msg, void *payload, uint8_t len)
// 	{
// 		uint16_t num =1;
//     	uint32_t* neighbors = call NeighborDiscovery.Neighbors_list();
// 		if (len == sizeof(pack))
// 		{
// 			pack *contents = (pack *)payload;
// 			//call DistanceVectorRouting.route(contents);
// 			//call DistanceVectorRouting.route(contents);
// 			if (contents->dest == AM_BROADCAST_ADDR) {
//                 call NeighborDiscovery.recieve(contents);
//                 return msg;
//             }
// 			else if (contents->protocol == PROTOCOL_DV) {
//                 //call DistanceVectorRouting.DVR(contents);
// 				//call DistanceVectorRouting.ping(contents->dest, payload);
// 				//call DistanceVectorRouting.route(contents);
// 				//call Routing.send(contents);
// 				//call DistanceVectorRouting.route(contents);
// 				//return msg;
// 			}
// 			else if(contents->TTL >= 0){
// 				//call DistanceVectorRouting.route(contents);
// 			}
			
// 			//prevents infinit loop, since all nodes have a true value so we changed it to false so we won't use that one
// 			//call DistanceVectorRouting.route(contents);
// 			if ((contents->src == TOS_NODE_ID) || iflist(*contents))
// 			{
// 				//call DistanceVectorRouting.ping(contents->dest, contents);
// 				//if(num = TOS_NODE_ID)
// 				//{	
// 					//call knowpacks.pushback(*contents);
// 					//call DistanceVectorRouting.route(contents);
// 				//}
// 				//num++;
// 				return msg;
// 			}
// 			//Kill the packet if TTL is 0
// 			else if (contents->TTL == 0){
// 				return msg;
//             }
// 			else
// 			{
// 				//call DistanceVectorRouting.route(contents);
// 				call knowpacks.pushback(*contents);
// 				price++;
// 				//call dist.pushback(price);
// 				//cach that has information about the nodes such nodeid, scr and future use for RouteTable
// 				call cach.insert(TOS_NODE_ID,contents->src);
// 				if(contents->dest == TOS_NODE_ID){
// 					// DistanceVectorRouting.ping(contents->dest, payload);
// 					//call DistanceVectorRouting.route(contents);
// 					call cach.insert(TOS_NODE_ID,contents->src);
// 					//dbg(ROUTING_CHANNEL, "Ping Received at node:%d from:%d\n", TOS_NODE_ID, contents->src);
// 					dbg(FLOODING_CHANNEL, "Ping Received at node:%d from:%d\n", TOS_NODE_ID, contents->src);
// 					dbg(FLOODING_CHANNEL, "Message:%s\n",contents->payload);
// 					dbg(FLOODING_CHANNEL, "Flooding finished at :%d\n", TOS_NODE_ID);
// 					dbg(FLOODING_CHANNEL, "--------------------------------------------------\n");
// 					return msg;
// 				}
// 				//resend with -1
// 				else
// 				{
// 					contents->TTL = contents->TTL - 1;
// 					//dbg(FLOODING_CHANNEL, "SENDING TO NEIGHBORS:\n");
// 					for (i = 0; i < call NeighborDiscovery.Neighbors_num(); i++) {
// 						//contents->TTL = contents->TTL - 1;
// 						//call Sender.send(*contents, neighbors[i]);

// 						// if(contents->dest > neighbors[i] ){
// 						// 	dbg(FLOODING_CHANNEL, "Sending from Flooding\n");
// 						// }
// 						//dbg(FLOODING_CHANNEL, "\tSend #%d to %d\n", i, neighbors[i]);

// 						//dbg(FLOODING_CHANNEL, "not ours sending to neighbor :%d\n", neighbors[i]);
//         			}
// 					//call Sender.send(*contents,call DistanceVectorRouting.findNextHop(contents->dest));
// 					//call Sender.send(*contents, *call NeighborDiscovery.Neighbors_list());
// 					return msg;
// 				}
// 			}
// 		}
// 	}
	
// 	event void AMSend.sendDone(message_t* msg, error_t error){}
#include <Timer.h>
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"
#include "../../includes/command.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/sendInfo.h"

#define MAX_ROUTES             25
#define MAX_DIST               18
#define DV_TTL                  4
#define SLIP_HORIZON            0
#define POISON_REVERSE          1
#define RESET                   0
#define STRAT    POISON_REVERSE

module DistanceVectorRoutingP {
    provides interface DistanceVectorRouting;
    uses interface SimpleSend as Sender;
    uses interface NeighborDiscovery as NeighborDiscovery;
    uses interface Timer<TMilli> as DVRTimer;
    uses interface Random as Random;
    uses interface Transport;
}


implementation {

    typedef struct {
        uint8_t dest;
        uint8_t nextHop;
        uint8_t dist;
        uint8_t ttl;
    } Route;
    
    uint16_t numRoutes = 0;
    Route routingTable[MAX_ROUTES];
    pack routePack;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, void *payload, uint8_t length);
    void initilizeRoutingTable();
    uint8_t findNextHop(uint8_t dest);
    void addRoute(uint8_t dest, uint8_t nextHop, uint8_t dist, uint8_t ttl);
    void removeRoute(uint8_t idx);
    void decrementTTLs();
    bool inputNeighbors();
    void triggerUpdate();
    
    command error_t DistanceVectorRouting.start() {
        initilizeRoutingTable();
        call DVRTimer.startOneShot(40000);
        dbg(ROUTING_CHANNEL, "Distance Vector Routing Started on node %u!\n", TOS_NODE_ID);
    }

    event void DVRTimer.fired() {
        if(call DVRTimer.isOneShot()) {
            call DVRTimer.startPeriodic(30000 + (uint16_t) (call Random.rand16()%5000));
        } else {
            // Decrement TTLs
            decrementTTLs();
            // Input neighbors into the routing table, if not there
            if(!inputNeighbors())
                // Send out routing table
                triggerUpdate();
        }
    }

    command void DistanceVectorRouting.ping(uint16_t destination, uint8_t *payload) {
        makePack(&routePack, TOS_NODE_ID, destination, 0, PROTOCOL_PING, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
        dbg(ROUTING_CHANNEL, "PING FROM %d TO %d\n", TOS_NODE_ID, destination);
        logPack(&routePack);
        call DistanceVectorRouting.routePacket(&routePack);
    }

    command void DistanceVectorRouting.routePacket(pack* myMsg) {
        uint8_t nextHop;
        if(myMsg->dest == TOS_NODE_ID && myMsg->protocol == PROTOCOL_PING) {
            dbg(ROUTING_CHANNEL, "PING Packet has reached destination %d!!!\n", TOS_NODE_ID);
            makePack(&routePack, myMsg->dest, myMsg->src, 0, PROTOCOL_PINGREPLY, 0,(uint8_t *) myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
            call DistanceVectorRouting.routePacket(&routePack);
            return;
        } else if(myMsg->dest == TOS_NODE_ID && myMsg->protocol == PROTOCOL_PINGREPLY) {
            dbg(ROUTING_CHANNEL, "PING_REPLY Packet has reached destination %d!!!\n", TOS_NODE_ID);
            return;
        } else if(myMsg->dest == TOS_NODE_ID && myMsg->protocol == PROTOCOL_TCP) {
            dbg(ROUTING_CHANNEL, "TCP Packet has reached destination %d!!!\n", TOS_NODE_ID);
            call Transport.receive(myMsg);
            return;
        }
        if((nextHop = findNextHop(myMsg->dest))) {
            dbg(ROUTING_CHANNEL, "Node %d routing packet through %d\n", TOS_NODE_ID, nextHop);
            //logPack(myMsg);
            call Sender.send(*myMsg, nextHop);
        } else {
            dbg(ROUTING_CHANNEL, "No route to destination. Dropping packet...\n");
            //logPack(myMsg);
        }
    }

    // Update the routing table if needed
    command void DistanceVectorRouting.handleDV(pack* myMsg) {
        uint16_t i, j;
        bool routePresent = FALSE, routesAdded = FALSE;
        Route* receivedRoutes = (Route*) myMsg->payload;
        // For each of up to 5 routes -> process the routes
        for(i = 0; i < 5; i++) {
            // Reached the last route -> stop
            if(receivedRoutes[i].dest == 0) { break; }
            // Process the route
            for(j = 0; j < numRoutes; j++) {
                if(receivedRoutes[i].dest == routingTable[j].dest) {
                    // If Split Horizon packet -> do nothing
                    // If sender is the source of table entry -> update
                    // If more optimal route found -> update
                    if(receivedRoutes[i].nextHop != 0) {
                        if(routingTable[j].nextHop == myMsg->src) {
                            routingTable[j].dist = (receivedRoutes[i].dist + 1 < MAX_DIST) ? receivedRoutes[i].dist + 1 : MAX_DIST;
                            routingTable[j].ttl = DV_TTL;
                            //dbg(ROUTING_CHANNEL, "Update to route: %d from neighbor: %d with new dist %d\n", routingTable[i].dest, routingTable[i].nextHop, routingTable[i].dist);
                        } else if(receivedRoutes[i].dist + 1 < MAX_DIST && receivedRoutes[i].dist + 1 < routingTable[j].dist) {
                            routingTable[j].nextHop = myMsg->src;
                            routingTable[j].dist = receivedRoutes[i].dist + 1;
                            routingTable[j].ttl = DV_TTL;
                            //dbg(ROUTING_CHANNEL, "More optimal route found to dest: %d through %d at dist %d\n", receivedRoutes[i].dest, receivedRoutes[i].nextHop, receivedRoutes[i].dist +1);
                        }
                    }
                    // If route is already present AND not unreachable -> update the TTL
                    if(routingTable[j].nextHop == receivedRoutes[i].nextHop && routingTable[j].dist == receivedRoutes[i].dist && routingTable[j].dist != MAX_DIST) {
                        routingTable[j].ttl = DV_TTL;
                    }
                    routePresent = TRUE;
                    break;
                }
            }
            // If route not in table AND there is space AND it is not a split horizon packet AND the route dist is not infinite -> add it
            if(!routePresent && numRoutes != MAX_ROUTES && receivedRoutes[i].nextHop != 0 && receivedRoutes[i].dist != MAX_DIST) {
                addRoute(receivedRoutes[i].dest, myMsg->src, receivedRoutes[i].dist + 1, DV_TTL);
                routesAdded = TRUE;
            }
            routePresent = FALSE;
        }
        if(routesAdded) {
            triggerUpdate();
        }
    }

    command void DistanceVectorRouting.handleNeighborLost(uint16_t lostNeighbor) {
        // Neighbor lost, update routing table and trigger DV update
        uint16_t i;
        if(lostNeighbor == 0)
            return;
        dbg(ROUTING_CHANNEL, "Neighbor discovery has lost neighbor %u. Distance is now infinite!\n", lostNeighbor);
        for(i = 1; i < numRoutes; i++) {
            if(routingTable[i].dest == lostNeighbor || routingTable[i].nextHop == lostNeighbor) {
                routingTable[i].dist = MAX_DIST;
            }
        }
        triggerUpdate();
    }

    command void DistanceVectorRouting.handleNeighborFound() {
        // Neighbor found, update routing table and trigger DV update
        inputNeighbors();
    }


    command void DistanceVectorRouting.printRouteTable() {
        uint16_t i;
        dbg(GENERAL_CHANNEL, "|\tRoutingTable of node:%d\t|\t\n", TOS_NODE_ID);
        dbg(GENERAL_CHANNEL, "|\tdest---next_hop----dist-|\t\n");
        for(i = 0; i < numRoutes; i++) {
            dbg(ROUTING_CHANNEL, "|   %4d|\t%5d|\t%6d\t|\t\n", routingTable[i].dest, routingTable[i].nextHop, routingTable[i].dist);
        }
        dbg(GENERAL_CHANNEL, "----------------------------\n");
    }

    uint8_t findNextHop(uint8_t dest) {
        uint16_t i;
        for(i = 1; i < numRoutes; i++) {
            if(routingTable[i].dest == dest) {
                if(routingTable[i].dist == MAX_DIST){
                    return 0;
                }else{
                    return routingTable[i].nextHop;
                }
            }
        }
        return 0;
    }
    
    void initilizeRoutingTable() {
        addRoute(TOS_NODE_ID, TOS_NODE_ID, 0, DV_TTL);
    }

    void addRoute(uint8_t dest, uint8_t nextHop, uint8_t dist, uint8_t ttl) {
        // Add route to the end of the current list
        if(numRoutes != MAX_ROUTES) {
            routingTable[numRoutes].dest = dest;
            routingTable[numRoutes].nextHop = nextHop;
            routingTable[numRoutes].dist = dist;
            routingTable[numRoutes].ttl = ttl;
            numRoutes++;
        }
        //dbg(ROUTING_CHANNEL, "Added entry in routing table for node: %u\n", dest);
    }

    void removeRoute(uint8_t idx) {
        uint8_t j;
        // Move other entries left
        for(j = idx+1; j < numRoutes; j++) {
            routingTable[j-1].dest = routingTable[j].dest;
            routingTable[j-1].nextHop = routingTable[j].nextHop;
            routingTable[j-1].dist = routingTable[j].dist;
            routingTable[j-1].ttl = routingTable[j].ttl;
        }
        // Zero the j-1 entry
        routingTable[j-1].dest = 0;
        routingTable[j-1].nextHop = 0;
        routingTable[j-1].dist = MAX_DIST;
        routingTable[j-1].ttl = 0;
        numRoutes--;        
    }

    void decrementTTLs() {
        uint8_t i, j;
        for(i = 1; i < numRoutes; i++) {
            // If valid entry in the routing table -> decrement the TTL
            if(routingTable[i].ttl != 0) {
                routingTable[i].ttl--;
            }
            // If TTL is zero -> remove the route
            if(routingTable[i].ttl == 0) {                
                dbg(ROUTING_CHANNEL, "Route stale, removing: %u\n", routingTable[i].dest);
                removeRoute(i);
                triggerUpdate();
            }
        }
    }

    bool inputNeighbors() {
        uint32_t* neighbors = call NeighborDiscovery.Neighbors_list();
        uint16_t neighborsListSize = call NeighborDiscovery.Neighbors_num();
        uint8_t i, j;
        bool routeFound = FALSE, newNeighborfound = FALSE;
        for(i = 0; i < neighborsListSize; i++) {
            for(j = 1; j < numRoutes; j++) {
                // If neighbor found in routing table -> update table entry
                if(neighbors[i] == routingTable[j].dest) {
                    routingTable[j].nextHop = neighbors[i];
                    routingTable[j].dist = 1;
                    routingTable[j].ttl = DV_TTL;
                    routeFound = TRUE;
                    break;
                }
            }
            // If neighbor not already in the list and there is room -> add new neighbor
            if(!routeFound && numRoutes != MAX_ROUTES) {
                addRoute(neighbors[i], neighbors[i], 1, DV_TTL);                
                newNeighborfound = TRUE;
            } else if(numRoutes == MAX_ROUTES) {
                dbg(ROUTING_CHANNEL, "Routing table full. Cannot add entry for node: %u\n", neighbors[i]);
            }
            routeFound = FALSE;
        }
        if(newNeighborfound) {
            triggerUpdate();
            return TRUE;        
        }
        return FALSE;
    }

    // Skip the route for split horizon
    // Alter route table for poison reverse, keeping values in temp vars
    // Copy route onto array
    // Restore original route
    // Send packet with copy of partial routing table
    void triggerUpdate() {
        // Send routes to all neighbors one at a time. Use split horizon, poison reverse
        uint32_t* neighbors = call NeighborDiscovery.Neighbors_list();
        uint16_t neighborsListSize = call NeighborDiscovery.Neighbors_num();
        uint8_t i = 0, j = 0, counter = 0;
        uint8_t temp;
        Route packetRoutes[5];
        bool isSwapped = FALSE;
        // Zero out the array
        for(i = 0; i < 5; i++) {
                packetRoutes[i].dest = 0;
                packetRoutes[i].nextHop = 0;
                packetRoutes[i].dist = 0;
                packetRoutes[i].ttl = 0;
        }
        // Send to every neighbor
        for(i = 0; i < neighborsListSize; i++) {
            while(j < numRoutes) {
                // Split Horizon/Poison Reverse
                if(neighbors[i] == routingTable[j].nextHop && STRAT == SLIP_HORIZON) {
                    temp = routingTable[j].nextHop;
                    routingTable[j].nextHop = 0;
                    isSwapped = TRUE;
                } else if(neighbors[i] == routingTable[j].nextHop && STRAT== POISON_REVERSE) {
                    temp = routingTable[j].dist;
                    routingTable[j].dist = MAX_DIST;
                    isSwapped = TRUE;
                }
                // Add route to array to be sent out
                packetRoutes[counter].dest = routingTable[j].dest;
                packetRoutes[counter].nextHop = routingTable[j].nextHop;
                packetRoutes[counter].dist = routingTable[j].dist;
                counter++;
                // If our array is full or we have added all routes -> send out packet with routes
                if(counter == 5 || j == numRoutes-1) {
                    // Send out packet
                    makePack(&routePack, TOS_NODE_ID, neighbors[i], 1, PROTOCOL_DV, 0, &packetRoutes, sizeof(packetRoutes));
                    call Sender.send(routePack, neighbors[i]);
                    // Zero out array
                    while(counter > 0) {
                        counter--;
                        packetRoutes[counter].dest = 0;
                        packetRoutes[counter].nextHop = 0;
                        packetRoutes[counter].dist = 0;
                    }
                }
                // Restore the table
                if(isSwapped && STRAT == SLIP_HORIZON) {
                    routingTable[j].nextHop = temp;
                } else if(isSwapped && STRAT== POISON_REVERSE) {
                    routingTable[j].dist = temp;
                }
                isSwapped = FALSE;
                j++;
            }
            j = 0;
        }
    }

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, void* payload, uint8_t length) {
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }    

}