#!/usr/bin/awk -f
# AWK script phân tích file trace của ghaziabad.tcl (phiên bản trace mới).
# Hỗ trợ các sự kiện: di chuyển (M), gửi (s), nhận (r), và hủy (d).
#
# Các trace mẫu:
# M 10.00000 2 (1932.14, 611.44, 0.00), (1932.56, 611.51), 4.24
# s 10.000000000 _0_ AGT  --- 0 tcp 40 ... 
# r 10.000000000 _0_ AGT  --- 0 tcp 40 ...
# r 10.037569819 _41_ RTR  --- 0 SMA2AODV 48 ... (REQUEST)
# r 10.039374285 _105_ RTR  --- 0 SMA2AODV 44 ... (REPLY)
#
# Ghi chú:
#  - Với dữ liệu AGT/tcp tính số gói gửi, nhận, từ đó tính PDR.
#  - Gói định tuyến (SMA2AODV) tính riêng để ước tính NRL.
#  - Các sự kiện di chuyển (M) chỉ đếm.
#  - Thêm cả tính độ trễ End-to-End (EtE) theo thứ tự gửi – nhận.
#
BEGIN {
    sends = 0;
    recvs = 0;
    routing_packets = 0;
    droppedBytes = 0;
    droppedPackets = 0;
    mobility_count = 0;
    sumDelay = 0;
    delayCount = 0;
}

{
    # Loại bỏ các dấu ngoặc để tiện so sánh
    for(i=1; i<=NF; i++){
        gsub(/[(),]/,"",$i);
    }

    if($1=="M"){
        mobility_count++;
        next;
    }

    if($1=="s"){
        # Nếu layer AGT và giao thức tcp, tăng biến gửi
        if($4=="AGT" && $7=="tcp") {
            sends++;
            # Lưu thời gian gửi theo thứ tự
            sendTimes[sends] = $2+0;
        }
    }

    if($1=="r"){
        # Với sự kiện nhận:
        if($4=="AGT" && $7=="tcp"){
            recvs++;
            # Nếu có gói đã gửi chưa ghép nối (theo FIFO) thì tính độ trễ
            if(recvs <= sends) {
                delay = ($2+0) - sendTimes[recvs];
                sumDelay += delay;
                delayCount++;
            }
        }
        # Gói định tuyến SMA2AODV
        if($7=="SMA2AODV")
            routing_packets++;
    }

    if($1=="D"){
        # Sự kiện hủy: nếu giao thức tcp và có kích thước > 0
        if($7=="tcp" && ($8+0) > 0) {
            droppedBytes += ($8+0);
            droppedPackets++;
        }
    }
}

END {
    PDF = (sends > 0) ? (recvs/sends)*100 : 0;
    NRL = (recvs > 0) ? routing_packets/recvs : 0;
    avgDelay = (delayCount > 0) ? sumDelay/delayCount : 0;

    printf("Sent packets      = %.0f\n", sends);
    printf("Received packets  = %.0f\n", recvs);
    printf("Routing packets   = %.0f\n", routing_packets);
    printf("PDR (%%)           = %.2f\n", PDF);
    printf("NRL               = %.2f\n", NRL);
    printf("Dropped packets   = %d\n", droppedPackets);
    printf("Dropped bytes     = %d\n", droppedBytes);
    printf("Mobility events   = %d\n", mobility_count);
    printf("Avg End-to-End Delay (s) = %.2f\n", avgDelay);
}
