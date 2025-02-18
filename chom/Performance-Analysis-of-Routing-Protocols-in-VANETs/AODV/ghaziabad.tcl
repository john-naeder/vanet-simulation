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
set packetSize 			512        				   ;# Kích thước gói tin
set FloodStart 			10.0         			   ;# Thời gian bắt đầu tấn công (10 giây)
set FloodInterval 		0.1         			   ;# Khoảng cách gửi gói tin (0.1 giây)
set FloodEnd 			100.0         			   ;# Thời gian kết thúc tấn công (20 giây)
set opt(x) 				4774
set opt(y) 				1659
# ======================================================================
# Main Program
# ======================================================================


#
# Initialize Global Variables
#

#trace
set ns_		[new Simulator]
set tracefd     [open ghaziabad.tr w]
$ns_ trace-all $tracefd

#nam
set namf [open ghaziabad.nam w]
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
			 
	for {set i 0} {$i < $val(nn) } {incr i} {
		set node_($i) [$ns_ node]	
		$node_($i) random-motion 0		;# disable random motion
	}

# mobility
source mobility.tcl 
# flood simulation 
# source flood_attack.tcl

# # Set up attacker nodes and target node for flood attack
# set targetNode $node_(0)
# set attackerNodes [list $node_(1) $node_(2) $node_(3) $node_(4) $node_(5) $node_(6) $node_(7) $node_(8) $node_(11) $node_(12) $node_(13) $node_(14) $node_(15) $node_(16) $node_(17) $node_(18) $node_(21) $node_(22) $node_(23) $node_(24) $node_(25) $node_(26) $node_(27) $node_(28)];# Chọn các node tấn công
# floodAttack $targetNode $attackerNodes $packetSize $FloodStart $FloodInterval $FloodEnd

# Setup traffic flow between nodes
set tcp [new Agent/TCP]
$tcp set class_ 2
set sink [new Agent/TCPSink]
$ns_ attach-agent $node_(0) $tcp
$ns_ attach-agent $node_(50) $sink
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

