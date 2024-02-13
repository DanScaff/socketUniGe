#!/bin/bash

set -e

if [[ $# != 1 ]] ; then printf "specificy the graph type: [median/overall] of throughput\n" ; exit 1; fi

readonly graphType=$1
columnIndex=2
if [[ $graphType != "median" && $graphType != "overall" ]] ; then printf "wrong graph type\n" ; exit 1; fi

if [[ $graphType == "overall" ]] ; then
    columnIndex=3
fi

declare -a protocols=("tcp" "udp")

for protocol in "${protocols[@]}" ; do

    #in dimMin e dimMax salvo la dimensione minima e massima dei pacchetti presi dai file di throughput
    dimMin=$(head -n 1 ../data/${protocol}_throughput.dat | cut -d ' ' -f 1)
    dimMax=$(tail -n 1 ../data/${protocol}_throughput.dat | cut -d ' ' -f 1)
    #uso awk per trasformare i numeri da notazione scientifica a decimale
    thrMin=$(head -n 1 ../data/${protocol}_throughput.dat | cut -d ' ' -f $columnIndex | awk -F"[eE]" '{print $1 * (10 ^ $2)}')
    thrMax=$(tail -n 1 ../data/${protocol}_throughput.dat | cut -d ' ' -f $columnIndex | awk -F"[eE]" '{print $1 * (10 ^ $2)}')

    Dmin=$(echo "scale=10; $dimMin/$thrMin" | bc -l)
    Dmax=$(echo "scale=10; $dimMax/$thrMax" | bc -l)
    B=$(echo "scale=10; (-$dimMin+$dimMax)/($Dmax-$Dmin)" | bc -l)
    L0=$(echo "scale=10; $Dmin-$dimMin/$B" | bc -l)

	gnuplot <<-eNDgNUPLOTcOMMAND
		set term png size 900, 700
        set output "../data/${protocol}_latency_bandwidth.png"
        set logscale x 2
        set logscale y 10
        set xlabel "msg size(s)"
        set ylabel "throughput (KB/s)"
        lbf(x) = x / ( $L0 + x / $B )
        plot "../data/${protocol}_throughput.dat" using 1:${columnIndex} title "${protocol} ping-pong Throughput" with linespoints, \
                lbf(x) title "$graphType Latency-Bandwidth model with L=$L0 and B=$B" with linespoints

        clear
	eNDgNUPLOTcOMMAND
    
done