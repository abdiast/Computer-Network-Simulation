/*
//  * ANDES Lab - University of California, Merced
//  * This class provides the basic functions of a network node.
//  *
//  * @author UCM ANDES Lab
//  * @date   2013/09/03
//  *
//  */
// #include <Timer.h>
// #include "includes/command.h"
// #include "includes/packet.h"
// #include "includes/CommandMsg.h"
// #include "includes/sendInfo.h"
// #include "includes/channels.h"

// module Node{
//    uses interface Boot;

//    uses interface SplitControl as AMControl;
//    uses interface Receive;

//    uses interface SimpleSend as Sender;

//    uses interface CommandHandler;

//    // adding 
//    uses interface Flooding;
//    uses interface NeighborDiscovery as NeighborDiscovery;
// }

// implementation{
//    pack sendPackage;

//    // Prototypes
//    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

//    event void Boot.booted(){
//       call AMControl.start();

//       dbg(GENERAL_CHANNEL, "Booted\n");
//    }

//    event void AMControl.startDone(error_t err){
//       if(err == SUCCESS){
//          dbg(GENERAL_CHANNEL, "Radio On\n");
//       }else{
//          //Retry until successful
//          call AMControl.start();
//       }
//    }

//    event void AMControl.stopDone(error_t err){}

//    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
//       dbg(GENERAL_CHANNEL, "Packet Received\n");
//       if(len==sizeof(pack)){
//          pack* myMsg=(pack*) payload;
//          dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
//          return msg;
//       }
//       dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
//       return msg;
//    }


//    event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
//       dbg(GENERAL_CHANNEL, "PING EVENT \n");
//       makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
//       call Sender.send(sendPackage, destination);
//    }

//    event void CommandHandler.printNeighbors(){}

//    event void CommandHandler.printRouteTable(){}

//    event void CommandHandler.printLinkState(){}

//    event void CommandHandler.printDistanceVector(){}

//    event void CommandHandler.setTestServer(){}

//    event void CommandHandler.setTestClient(){}

//    event void CommandHandler.setAppServer(){}

//    event void CommandHandler.setAppClient(){}

//    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
//       Package->src = src;
//       Package->dest = dest;
//       Package->TTL = TTL;
//       Package->seq = seq;
//       Package->protocol = protocol;
//       memcpy(Package->payload, payload, length);
//    }
// }
// commented out to be saved as a back up




/*
* ANDES Lab - University of California, Merced
* This class provides the basic functions of a network node.
*
* @author UCM ANDES Lab
* @date   2013/09/03
*
*/
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{
    uses interface Boot;
    uses interface SplitControl as AMControl;
    uses interface Receive;

    uses interface SimpleSend as Sender;

    uses interface Random as Random;

    uses interface CommandHandler;

    //uses interface Flooding as Sender;

    uses interface NeighborDiscovery;

    //uses interface Timer<TMilli> as RoutingTimer;
    uses interface DistanceVectorRouting as DistanceVectorRouting;
    uses interface Transport;
    uses interface Client;
    uses interface Chat;
    //uses interface Routing;
    

}

implementation{
    event void Boot.booted(){
        call AMControl.start();        
        dbg(GENERAL_CHANNEL, "Booted\n");
        call NeighborDiscovery.start();
        call DistanceVectorRouting.start();
        call Transport.start();
        if(TOS_NODE_ID == 1)
            call Chat.startChatServer();
    }

     // Starts radio, called during boot
    event void AMControl.startDone(error_t err){
        if (err == SUCCESS) {
            dbg(GENERAL_CHANNEL, "Radio On\n");
        } else {
            //Retry until successful
            call AMControl.start();
        }
    }
    event void AMControl.stopDone(error_t err){}
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        pack* myMsg = (pack*) payload;
        if(len!=sizeof(pack)) {
            dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
        } else if(myMsg->protocol == PROTOCOL_DV) {
            call DistanceVectorRouting.handleDV(myMsg);
        } else if(myMsg->dest == 0) {
            call NeighborDiscovery.handleNeighbor(myMsg);
        } else {
            call DistanceVectorRouting.routePacket(myMsg);
        }
        return msg;
    }
    

    

    
    event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
        dbg(GENERAL_CHANNEL, "PING EVENT \n");
        //makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, current_seq++, payload, PACKET_MAX_PAYLOAD_SIZE);
        //call Flooding.ping(&sendPackage);
        //call Flooding.send(sendPackage, destination);
        //call Sender.send(sendPackage, destination);
        call DistanceVectorRouting.ping(destination, payload);
        //call DistanceVectorRouting.route(payload);
        //call Routing.send(&sendPackage);
        //dbg(FLOODING_CHANNEL, "Flooding finished\n");
    }

    
     //command to print the list of neighbors
    event void CommandHandler.printNeighbors() {
        call NeighborDiscovery.printNeighbors();
    }
   event void CommandHandler.printDistanceVector(){
   }
   event void CommandHandler.printRouteTable(){
       call DistanceVectorRouting.printRouteTable();
   }
   event void CommandHandler.printLinkState(){}
   event void CommandHandler.setTestServer(uint8_t port) {
        call Client.startServer(port);
        dbg(TRANSPORT_CHANNEL, "Node %u listening on port %u\n", TOS_NODE_ID, port);
    }

    event void CommandHandler.setTestClient(uint8_t dest, uint8_t srcPort, uint8_t destPort, uint16_t transfer) {
        call Client.startClient(dest, srcPort, destPort, transfer);
        dbg(TRANSPORT_CHANNEL, "Creating connection from port %u to port %u on node %u. bytes: %u\n", srcPort, destPort, dest, transfer);
    }

    event void CommandHandler.setClientClose(uint8_t dest, uint8_t srcPort, uint8_t destPort) {
        dbg(TRANSPORT_CHANNEL, "Closing connection from port %u to port %u on node %u.\n", srcPort, destPort, dest);
        call Client.closeClient(dest, srcPort, destPort);
    }
    event void CommandHandler.startChatServer() {
        call Chat.startChatServer();
    }

    event void CommandHandler.chat(char* msg) {
        call Chat.chat(msg);
    }
    
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }
   
    
}