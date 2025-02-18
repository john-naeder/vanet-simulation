# Proc tạo flood attack dựa trên TCP cho AODV với thời gian bắt đầu, khoảng cách gửi và thời gian kết thúc
proc floodAttack {targetNode attackerNodes packetSize startTime intervalTime endTime} {
    global ns_ ftps

    # Tạo TCP agents và TCP sink
    set tcpAgents {}
    set sink [new Agent/TCPSink]

    # Gán TCP sink cho targetNode (chỉ cần gán một lần)
    $ns_ attach-agent $targetNode $sink

    foreach attackerNode $attackerNodes {
        set tcp [new Agent/TCP]
        lappend tcpAgents $tcp
        $ns_ attach-agent $attackerNode $tcp
        $ns_ connect $tcp $sink
    }

    # Tạo FTP ứng dụng cho mỗi TCP agent (dùng để tạo lưu lượng tấn công)
    set ftps {}
    foreach tcp $tcpAgents {
        set ftp [new Application/FTP]
        $ftp attach-agent $tcp
        # Nếu cần set kích thước gói tin, ví dụ:
        # $ftp set packetSize_ $packetSize
        lappend ftps $ftp
    }

    # Lên lịch các lần gửi theo chu kỳ từ startTime đến endTime với khoảng cách intervalTime
    for {set t $startTime} {$t < $endTime} {set t [expr {$t + $intervalTime}]} {
        $ns_ at $t {foreach ftp $ftps { $ftp start }}
    }

    # Dừng flood attack tại endTime
    $ns_ at $endTime {foreach ftp $ftps { $ftp stop }}
}