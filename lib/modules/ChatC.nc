#include <Timer.h>
#include "../../includes/CommandMsg.h"
#include "../includes/packet.h"
#include "../includes/socket.h"

configuration ChatC {
    provides interface Chat;
}

implementation {
    components ChatP;
    Chat = ChatP;

    components new SimpleSendC(AM_PACK);
    ChatP.Sender -> SimpleSendC;

    components new TimerMilliC() as ChatTimer;
    ChatP.ChatTimer -> ChatTimer;

    components RandomC as Random;
    ChatP.Random -> Random;

    components TransportC as Transport;
    ChatP.Transport -> Transport;

    components new HashmapC(uint8_t, 20);
    ChatP.connections -> HashmapC;
}