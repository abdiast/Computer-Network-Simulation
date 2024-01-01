#include <Timer.h>
#include "../../includes/command.h"
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"

generic module FloodingP()
{
	provides interface Flooding;
	uses interface SimpleSend as Sender;
	uses interface Receive as Receiver;

	uses interface Packet;
    uses interface AMSend;
	//Uses the Queue interface to determine if packet recieved has been seen before
	uses interface List<pack> as knowpacks;
	uses interface Hashmap<uint16_t> as cach;
	//uses interface Routing;
	uses interface NeighborDiscovery;
}

implementation
{
	pack sendPackage;
	uint8_t price = 0;
	uint16_t sequence=0;
	uint16_t i;
	// Prototypes
	void makePack(pack * Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t seq, uint16_t protocol, uint8_t * payload, uint8_t length);
	bool iflist(pack packet);
	bool prevlist(pack packet);
	event uint16_t NeighborDiscovery.getSequence(){}
	//event uint16_t Routing.getSequence(){}
	//send packet
	command error_t Flooding.send(pack msg, uint16_t dest)
	{
		//dbg(FLOODING_CHANNEL, "--------------------------------------------------\n");
		//dbg(FLOODING_CHANNEL, "Flooding to node destination: %d\n", dest);

		if (call Sender.send(msg, AM_BROADCAST_ADDR) == SUCCESS)
		{
			//call DistanceVectorRouting.ping(dest, &msg);
			return SUCCESS;
		}
		return FAIL;
	}

	// if node recieves a packet
	event message_t *Receiver.receive(message_t * msg, void *payload, uint8_t len)
	{
		uint16_t num =1;
    	uint32_t* neighbors = call NeighborDiscovery.Neighbors_list();
		if (len == sizeof(pack))
		{
			pack *contents = (pack *)payload;
			//call DistanceVectorRouting.route(contents);
			//call DistanceVectorRouting.route(contents);
			if (contents->dest == AM_BROADCAST_ADDR) {
                call NeighborDiscovery.recieve(contents);
                return msg;
            }
			else if (contents->protocol == PROTOCOL_DV) {
                //call DistanceVectorRouting.handleDV(contents);
				//call DistanceVectorRouting.ping(contents->dest, payload);
				//call DistanceVectorRouting.route(contents);
				//call Routing.send(contents);
				//call DistanceVectorRouting.route(contents);
				//return msg;
			}
			else if(contents->TTL >= 0){
				//call DistanceVectorRouting.route(contents);
			}
			
			//prevents infinit loop, since all nodes have a true value so we changed it to false so we won't use that one
			//call DistanceVectorRouting.route(contents);
			if ((contents->src == TOS_NODE_ID) || iflist(*contents))
			{
				//call DistanceVectorRouting.ping(contents->dest, contents);
				//if(num = TOS_NODE_ID)
				//{	
					//call knowpacks.pushback(*contents);
					//call DistanceVectorRouting.route(contents);
				//}
				//num++;
				return msg;
			}
			//Kill the packet if TTL is 0
			else if (contents->TTL == 0){
				return msg;
            }
			else
			{
				//call DistanceVectorRouting.route(contents);
				call knowpacks.pushback(*contents);
				price++;
				//call cost.pushback(price);
				//cach that has information about the nodes such nodeid, scr and future use for RouteTable
				call cach.insert(TOS_NODE_ID,contents->src);
				if(contents->dest == TOS_NODE_ID){
					// DistanceVectorRouting.ping(contents->dest, payload);
					//call DistanceVectorRouting.route(contents);
					call cach.insert(TOS_NODE_ID,contents->src);
					//dbg(ROUTING_CHANNEL, "Ping Received at node:%d from:%d\n", TOS_NODE_ID, contents->src);
					dbg(FLOODING_CHANNEL, "Ping Received at node:%d from:%d\n", TOS_NODE_ID, contents->src);
					dbg(FLOODING_CHANNEL, "Message:%s\n",contents->payload);
					dbg(FLOODING_CHANNEL, "Flooding finished at :%d\n", TOS_NODE_ID);
					dbg(FLOODING_CHANNEL, "--------------------------------------------------\n");
					return msg;
				}
				//resend with -1
				else
				{
					contents->TTL = contents->TTL - 1;
					//dbg(FLOODING_CHANNEL, "SENDING TO NEIGHBORS:\n");
					for (i = 0; i < call NeighborDiscovery.Neighbors_num(); i++) {
						//contents->TTL = contents->TTL - 1;
						//call Sender.send(*contents, neighbors[i]);

						// if(contents->dest > neighbors[i] ){
						// 	dbg(FLOODING_CHANNEL, "Sending from Flooding\n");
						// }
						//dbg(FLOODING_CHANNEL, "\tSend #%d to %d\n", i, neighbors[i]);

						//dbg(FLOODING_CHANNEL, "not ours sending to neighbor :%d\n", neighbors[i]);
        			}
					//call Sender.send(*contents,call DistanceVectorRouting.findNextHop(contents->dest));
					//call Sender.send(*contents, *call NeighborDiscovery.Neighbors_list());
					return msg;
				}
			}
		}
	}
	
	event void AMSend.sendDone(message_t* msg, error_t error){}
	bool iflist(pack packet){
		pack listpack;
		//uint16_t i;
        for (i = 0; i < call knowpacks.size(); i++) {
			listpack = call knowpacks.get(i);
			if(packet.src == listpack.src)
			{
				return TRUE;
			}
        }
		return FALSE;
	}
	bool prevlist(pack packet){
		pack listpack;
		pack listpack2;
		uint16_t j;
        for (i = 0; i < call knowpacks.size(); i++) {
			listpack = call knowpacks.get(i);
			for(j=0;j <call knowpacks.size();j++){
				listpack2 = call knowpacks.get(j);
				if(packet.src == listpack.src && listpack.src == listpack2.src && i != j)
				{
					return FALSE;
				}
			}
        }
		return TRUE;
	}
}
