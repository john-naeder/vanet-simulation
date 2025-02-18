set val(chan)           Channel/WirelessChannel    ;# channel type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         150                        ;# max packet in ifq
set val(nn)             363                        ;# number of mobilenodes
set val(rp)             AODV                       ;# routing protocol
set val(rate) 		    0.5
set val(size) 		    512
set opt(x)              6640
set opt(y)              6068
set opt(min-x)          1.72
set opt(min-y)          2.23
set opt(start)          0.0
set opt(stop)           399.99999999999994         ;#time of connections end
set val(stop) 		    4400                       ;#time of simulation end
# set val(cp)             "CaoLanhCity.topo"       ;#Topology Pattern
# set val(cb)             "Data.cbr"               ;#CBR Data 
set val(connect)        40                         ;#UDP connections
set namefile $val(rp)_$val(connect)_$val(stop)_$val(rate)

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

# configure node (fixed - use -channel instead of -channelType)
$ns_ node-config -adhocRouting $val(rp) \
    -llType $val(ll) \
    -macType $val(mac) \
    -ifqType $val(ifq) \
    -ifqLen $val(ifqlen) \
    -antType $val(ant) \
    -propType $val(prop) \
    -phyType $val(netif) \
    -channel $chan_1_ \
    -topoInstance $topo \
    -agentTrace ON \
    -routerTrace ON \
    -macTrace ON \
    -movementTrace ON		



#===================== Node Creation =====================
# Initialize the list xListHead
set xListHead {}

for {set i 0} {$i < $val(nn) } {incr i} {
    set node_($i) [$ns_ node]	
    $node_($i) random-motion 0		;# disable random motion
    $ns_ initial_node_pos $node_($i) 20
}
#=========================================================

#===================== Malicious Node =====================
# After node creation, designate node_(X) as malicious (e.g., node_(0)):
set malicious_node $node_(0)

# Source the flood attack script
source flood_attack.tcl

# Schedule the flood attack: start at time 5.0, lasting 30 seconds, sending an RREQ every 0.1 sec
floodAttack $malicious_node $ns_ 5.0 30.0 0.1
#=========================================================

source mobility.tcl

# Setup traffic flow between nodes
# TCP connections between node_(0) and node_(1)


#=Create a TCP connection between node_(0) and node_(22)==
set tcp [new Agent/TCP]
$tcp set class_ 2
set sink [new Agent/TCPSink]
$ns_ attach-agent $node_(0) $tcp
$ns_ attach-agent $node_(22) $sink
$ns_ connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns_ at 10.0 "$ftp start" 
#========================================================

#===================== CBR Traffic =======================
# Tell nodes when the simulation ends

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
#=========================================================


puts "Starting Simulation..."
$ns_ run


