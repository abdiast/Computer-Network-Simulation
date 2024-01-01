#include "../../includes/am_types.h"

generic configuration FloodingC(int channel){
   provides interface Flooding;
}

implementation{
   components new FloodingP();
   Flooding = FloodingP.Flooding;

   components new SimpleSendC(channel);
   FloodingP.Sender -> SimpleSendC;

   components new AMSenderC(channel);
   FloodingP.Packet -> AMSenderC;
   FloodingP.AMSend -> AMSenderC;

   components NeighborDiscoveryC;
   FloodingP.NeighborDiscovery -> NeighborDiscoveryC;
   //components RoutingC;
   //FloodingP.Routing ->RoutingC;

   components new AMReceiverC(AM_PACK) as GeneralReceive;
   FloodingP.Receiver -> GeneralReceive;
   components new HashmapC(uint16_t, 256) as cach;
   FloodingP.cach-> cach;

   components new ListC(pack, 200) as knowpacks;
   FloodingP.knowpacks -> knowpacks;
}
