#!/usr/bin/env perl

use strict;
use warnings;

use feature qw/ say /;

use Time::Piece;
use Time::Seconds;

my $FILE_FORMAT = 'days/speed-%Y%m%d.log';


for my $file (glob('days/counter*.log')) {
    open my $FILE, '<', $file or die "Could not read $file: $!, $?";
    my ($date) = $file =~ m{^ days/ [^0-9]+ (\d+) \.log $}x;
    my $time = Time::Piece->strptime($date, "%Y%m%d") + ONE_DAY/2;
    my $stats = calculate($time, $FILE, 30);

    say STDERR "Processing $file";

    open my $OUT, '>', $time->strftime( $FILE_FORMAT ) or die "Could not write file $file: $!, $?";
    printf $OUT "%s %s\n", @$_ for @$stats;
    close $OUT;
}


sub calculate {
    my $time = shift;
    my $FH = shift;
    my $WINDOW = shift // 1;

    my @times;
    my ($prev, $start);
    while (my $t = <$FH>) {
        chomp($t);
        push @times, $t;
    }

    return [] unless @times;

    my $tidx = 0;
    my $tp = $time->epoch;
    my $end = ($time + ONE_DAY)->epoch;

    my @speed = ([$tp, 0]);
    my @cluster = (0,0);

    while ( $tp < $end ) {
        ### Far to the future for next entry
        if ( $times[$tidx] - $tp > $WINDOW+1 && ($tidx==0 || ($tp - $times[$tidx-1] > $WINDOW+1)) ) {
            $tp = int( $times[$tidx] - $WINDOW );
            @cluster = ($tidx,$tidx);
        }

        $cluster[0]++ while $cluster[0] >= 0 && $cluster[0] < $#times && $times[$cluster[0]] < $tp - $WINDOW;
        $cluster[1]++ while $cluster[1] >= 0 && $cluster[1] < $#times && $times[$cluster[1]] < $tp + $WINDOW;
        $cluster[0]-- while $cluster[0]>0 && $times[$cluster[0]] > $tp+$WINDOW;
        $cluster[1]-- while $cluster[1]>0 && $times[$cluster[1]] > $tp+$WINDOW;

        my $speed = 0;
        if ( $tp > $times[$cluster[0]]-1 && $tp < $times[$cluster[1]]+1 && $cluster[0] != $cluster[1] ) {
            $speed = ($cluster[1] - $cluster[0])/($times[$cluster[1]] - $times[$cluster[0]]);
            $speed *= ONE_MINUTE;
            $speed = sprintf "%.0f", $speed;
        }
        if ( @speed>1 && $speed == $speed[-1][1] && $speed == $speed[-2][1] ) {
            $speed[-1][0] = $tp;
        }
        else {
            push @speed, [$tp, $speed];
        }
        $tidx++ while $tidx < $#times && $times[$tidx] < $tp;
        $tp++;

        if ($tidx == $#times && $tp > $times[$tidx] && $speed == 0) {
            push @speed, [$end, 0];
            last;
        }
    }
    return \@speed;
}
