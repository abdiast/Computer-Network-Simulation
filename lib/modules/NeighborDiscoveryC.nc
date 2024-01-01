#include "../../includes/packet.h"
#include <Timer.h>
#include "../../includes/CommandMsg.h"

configuration NeighborDiscoveryC {
    provides interface NeighborDiscovery;
}

implementation {
    components NeighborDiscoveryP;
    NeighborDiscovery = NeighborDiscoveryP;

    components new SimpleSendC(AM_PACK);
    NeighborDiscoveryP.Sender -> SimpleSendC;

    components new HashmapC(uint32_t, 20) as Neighbors;
    NeighborDiscoveryP.Neighbors-> Neighbors;

    components new TimerMilliC() as NeighborDiscoveryTimer;
    NeighborDiscoveryP.NeighborDiscoveryTimer -> NeighborDiscoveryTimer;

    components DistanceVectorRoutingC;
    NeighborDiscoveryP.DistanceVectorRouting -> DistanceVectorRoutingC;

    components RandomC as Random;
    NeighborDiscoveryP.Random -> Random;
}
