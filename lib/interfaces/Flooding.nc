#include "../../includes/packet.h"

interface Flooding {
    //command void ping(pack* msg);
    //command void nextnode(pack* msg);
    //event uint16_t getSequence();
    command error_t send(pack msg, uint16_t dest );
}
