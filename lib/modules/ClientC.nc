
#include <Timer.h>
#include "../../includes/CommandMsg.h"
#include "../includes/packet.h"
#include "../includes/socket.h"

configuration ClientC {
    provides interface Client;
}

implementation {
    components ClientP;
    Client = ClientP;

    components new SimpleSendC(AM_PACK);
    ClientP.Sender -> SimpleSendC;

    components new TimerMilliC() as ClientTimer;
    ClientP.ClientTimer -> ClientTimer;

    components RandomC as Random;
    ClientP.Random -> Random;

    components TransportC as Transport;
    ClientP.Transport -> Transport;

    components new HashmapC(uint8_t, 20);
    ClientP.ConnectionMap -> HashmapC;
}