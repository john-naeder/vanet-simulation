# ======================================================================
# Define options
# ======================================================================
set val(chan)           Channel/WirelessChannel    ;# channel type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         100                        ;# max packet in ifq
set val(nn)             118                        ;# number of mobilenodes
set val(rp)             AODV                       ;# routing protocol
set packetSize 			1024        			   
set FloodStart 			100.0         			   ;# Start time of flooding attack
set FloodInterval 		0.1         			   ;# Time interval between two consecutive messages
set FloodEnd 			150.0         			   ;# End time of flooding attack
set simulationTime 		300.0         			   ;# Simulation time
set opt(x) 				4774
set opt(y) 				1659
set MESSAGE_PORT		1234
set BROADCAST_ADDR      -1
# ======================================================================
# Main Program
# ======================================================================


#
# Initialize Global Variables
#

#trace
set ns_		[new Simulator]
set tracefd     [open traces/flooding_attack_sim.tr w]
$ns_ trace-all $tracefd

#nam
set namf [open nams/flooding_attack_sim.nam w]
$ns_ namtrace-all-wireless $namf $opt(x) $opt(y)

# set up topography object
set topo       [new Topography]

$topo load_flatgrid $opt(x) $opt(y)

#
# Create God
#
create-god $val(nn)

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
			 -macTrace ON \
			 -movementTrace ON	
	$ns_ node-config -size 20		

# flood simulation
Class Agent/MessagePassing/Flooding -superclass Agent/MessagePassing

Agent/MessagePassing/Flooding instproc recv {source sport size data} {
    $self instvar messages_seen node_
    global ns_ BROADCAST_ADDR 

    # extract message ID from message
    set message_id [lindex [split $data ":"] 0]
    puts "\nNode [$node_ node-addr] got message $message_id\n"

    if {[lsearch $messages_seen $message_id] == -1} {
	lappend messages_seen $message_id
        $ns_ trace-annotate "[$node_ node-addr] received {$data} from $source"
        $ns_ trace-annotate "[$node_ node-addr] sending message $message_id"
	$self sendto $size $data $BROADCAST_ADDR $sport
    } else {
        $ns_ trace-annotate "[$node_ node-addr] received redundant message $message_id from $source"
    }
}

Agent/MessagePassing/Flooding instproc send_message {size message_id data port} {
    $self instvar messages_seen node_
    global ns_ MESSAGE_PORT BROADCAST_ADDR

    lappend messages_seen $message_id
    $ns_ trace-annotate "[$node_ node-addr] sending message $message_id"
    $self sendto $size "$message_id:$data" $BROADCAST_ADDR $port
}


# attach a new Agent/MessagePassing/Flooding to each node on port $MESSAGE_PORT
for {set i 0} {$i < $val(nn) } {incr i} {
    set node_($i) [$ns_ node]	
    $node_($i) random-motion 0		;# disable random motion

    set a($i) [new Agent/MessagePassing/Flooding]
    $node_($i) attach  $a($i) $MESSAGE_PORT
    $a($i) set messages_seen {}
}


# mobility
source mobility.tcl 

$node_(0) shape box
$node_(0) color blue
$node_(22) shape box
$node_(22) color green

for {set i 1} {$i <= 1} {incr i 29} {
    $node_($i) shape circle
    $node_($i) color red
}

$ns_ at 0.0 "$node_(0) color blue"
$ns_ at 0.0 "$node_(22) color green"

for {set i 1} {$i <= 1} {incr i 29} {
    $ns_ at 90.0 "$node_($i) color red"
}
set currentAttackTime $FloodStart
for {set time 0.1} {$currentAttackTime <= $FloodEnd} {set time [expr $time + 0.2]} {
    set currentAttackTime [expr $FloodStart + $time]
    for {set i 1} {$i <= 1} {incr i 29} {
        set send_time [expr $FloodStart + $time]
        $ns_ at $send_time "$a($i) send_message $packetSize 1 {first message} $MESSAGE_PORT"

        set send_time [expr $FloodStart + $time + 0.4]
        $ns_ at $send_time "$a([expr $val(nn)/2]) send_message $packetSize 2 {some message} $MESSAGE_PORT"

        set send_time [expr $FloodStart + $time + 0.7]
        $ns_ at $send_time "$a([expr $val(nn)-2]) send_message $packetSize 3 {another one} $MESSAGE_PORT"
    }
}

# # Setup traffic flow between nodes
# set tcp [new Agent/TCP]
# $tcp set class_ 2
# set sink [new Agent/TCPSink]
# $ns_ attach-agent $node_(0) $tcp
# $ns_ attach-agent $node_(22) $sink
# $ns_ connect $tcp $sink
# set ftp [new Application/FTP]
# $ftp attach-agent $tcp
# $ns_ at 90.0 "$ftp start" 

# Tell nodes when the simulation ends
#
for {set i 0} {$i < $val(nn) } {incr i} {
    $ns_ at $simulationTime "$node_($i) reset";
}

$ns_ at $simulationTime "stop"
set timePrintEndMessage [expr $simulationTime + 0.01]
$ns_ at $timePrintEndMessage "puts \"NS EXITING...\" ; $ns_ halt"
proc stop {} {
    global ns_ tracefd
    $ns_ flush-trace
    close $tracefd

    exec nam nams/flooding_attack_sim.nam & 
    exit 0
}

puts "Starting Simulation..."
$ns_ run

