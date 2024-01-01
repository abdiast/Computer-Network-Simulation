#include "../../includes/packet.h"

interface NeighborDiscovery {
   command error_t start();
   command void handleNeighbor(pack* myMsg);
   command void printNeighbors();
   command uint32_t* Neighbors_list();
   command uint16_t Neighbors_num();

}
