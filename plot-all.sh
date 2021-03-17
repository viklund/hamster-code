#!/bin/bash

for F in days/speed*.log; do
    [ -f $F ] || continue
    [ -s $F ] || continue

    echo "Processing $F"
    D=$(echo $F | sed 's/days\/speed-\([0-9]\+\).log/\1/')
    gnuplot -e "date='$D'" gnuplot.script
done
