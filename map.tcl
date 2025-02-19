set val(chan)           Channel/WirelessChannel    ;# channel type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         150                        ;# max packet in ifq
set val(nn)             200                        ;# number of mobilenodes
set val(rp)             SMA2AODV                       ;# routing protocol
set val(rate) 		 0.5
set val(size) 		 512
set opt(x)		 5000
set opt(y) 		 3400
set val(cstop) 	 199.99 ;#time of connections end
set val(stop) 		 200 ;#time of simulation end

Mac/802_11 set basicRate_ 1Mb
Mac/802_11 set dataRate_ 11Mb
Mac/802_11 set bandwidth_ 11Mb

# ======================================================================
# Main Program
# ======================================================================


#
# Initialize Global Variables
#
set ns_		[new Simulator]
set tracefd     	[open map.tr w]
set namf 		[open map.nam w]
$ns_ trace-all $tracefd
$ns_ namtrace-all-wireless $namf $opt(x) $opt(y)

# set up topography object
set topo       	[new Topography]
$topo load_flatgrid $namf $opt(x) $opt(y)

# Create God
create-god $val(nn)

# Create channel #1 and #2
set chan_1_ [new $val(chan)]
set chan_2_ [new $val(chan)]

# configure node
        $ns_ node-config -adhocRouting $val(rp) \
			 -llType $val(ll) \
			 -macType $val(mac) \
			 -ifqType $val(ifq) \
			 -ifqLen $val(ifqlen) \
			 -antType $val(ant) \
			 -propType $val(prop) \
			 -phyType $val(netif) \
			 -channelType $val(chan) \
			 -topoInstance $topo \
			 -agentTrace ON \
			 -routerTrace ON \
			 -macTrace OFF \
			 -movementTrace ON		
			 
	for {set i 0} {$i < $val(nn) } {incr i} {
		set node_($i) [$ns_ node]	
		$node_($i) random-motion 0		;# disable random motion
		$ns_ initial_node_pos $node_($i) 40
	}

source mobility.tcl 

# Setup traffic flow between nodes
# TCP connections between node_(0) and node_(1)

set tcp [new Agent/TCP]
$tcp set class_ 2
set sink [new Agent/TCPSink]
$ns_ attach-agent $node_(0) $tcp
$ns_ attach-agent $node_(22) $sink
$ns_ connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns_ at 10.0 "$ftp start" 

#
# Tell nodes when the simulation ends
#
for {set i 0} {$i < $val(nn) } {incr i} {
    $ns_ at 150.0 "$node_($i) reset";
}
$ns_ at 150.0 "stop"
$ns_ at 150.01 "puts \"NS EXITING...\" ; $ns_ halt"
proc stop {} {
    global ns_ tracefd
    $ns_ flush-trace
    close $tracefd
}

puts "Starting Simulation..."
$ns_ run

