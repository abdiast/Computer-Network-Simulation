from TOSSIM import Mote
from TestSim import TestSim

def main():
    # Get simulation ready to run.
    s = TestSim();
    # hello
    # Before we do anything, lets simulate the network off.
    s.runTime(1);

    # Load the the layout of the network.
    s.loadTopo("e1.topo");

    # Add a noise model to all of the motes.
    s.loadNoise("no_noise.txt");

    # Turn on all of the sensors.
    s.bootAll();

    # Add the main channels. These channels are declared in includes/channels.h
    #s.addChannel(s.COMMAND_CHANNEL);
    s.addChannel(s.GENERAL_CHANNEL);
    
    #ADDING OTHER CHANNELS
    #s.addChannel(s.FLOODING_CHANNEL);
    #s.addChannel(s.NEIGHBOR_CHANNEL);
    s.addChannel(s.ROUTING_CHANNEL);
    # After sending a ping, simulate a little to prevent collision.

    s.runTime(50)
    for i in range(1, 21):
        s.routeDMP(i)
        s.runTime(20)
       #s.ping(i, 10, "Hi!");
       # s.neighborDMP(i)
        #s.runTime(10)
    #s.ping(1, 8, "Hi!");
       #s.neighborDMP(i)

    s.ping(9, 8, "Hello, World");
    s.runTime(5);

    
    
    #s.ping(1,2 , "Hi!");
    #s.runTime(1);

if __name__ == '__main__':
    main()
