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

    my $tidx = 0;
    my $tp = $time->epoch;
    my $end = ($time + ONE_DAY)->epoch;

    my @speed;

    while ( $tp < $end ) {
        my $n = 0;

        my $from = $tidx;
        $n++ while --$from >= 0 && abs($times[$from] - $tp) < $WINDOW;
        $from++;
        $from = $from > $#times ? $#times : $from;

        my $to = $tidx;
        $n++ while ++$to <= $#times && abs($times[$to] - $tp) < $WINDOW;
        $to--;
        $to = $to > $#times ? $#times : $to;

        my $speed = 0;
        if ( $from != $to ) {
            $speed = $n / ($times[$to] - $times[$from]);
            $speed *= ONE_MINUTE;
        }

        push @speed, [ $tp, $speed ];

        $tidx++ while $tidx <= $#times && $times[$tidx] < $tp;
        $tp++;
    }
    return \@speed;
}
