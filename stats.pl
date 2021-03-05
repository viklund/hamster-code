#!/usr/bin/env perl
use strict;
use warnings;

use feature qw/ say /;
use Data::Dumper;
use DateTime;

use List::Util qw/ sum /;

open my $HAMSTER, '<', 'hamster-spinner.log' or die;

my %counts;

my @times = ();
my $last;
while (<$HAMSTER>) {
    # 2021-03-04 06:32:28.177878  35520   
    next if /^READY/;
    my ($year, $month, $day, $hour, $minute, $second, $millis, $count) = /^(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)\.(\d+)\s+(\d+)\s*$/;

    my $date = DateTime->new(
        year => $year,
        month => $month,
        day => $day,
        hour => $hour,
        minute => $minute,
        second => $second,
        nanosecond => $millis*1000,
    );

    push @times, $date;
    if ( $last ) {
        my $diff = $date - $last;
        my @diff = $diff->in_units('days', 'minutes', 'nanoseconds');
        my @weight = (60*60*24, 60, 10**-9);
        my $seconds = sum map { $diff[$_]*$weight[$_] } 0..$#diff;
        $counts{ sprintf("%.02f", $seconds) }++;
    }
    $last = $date;
} 

for my $diff ( sort { $a <=> $b } keys %counts ) {
    last if $diff > 3; # If time is more than 10 seconds, skip
    printf "%5d  %8.2f\n", $counts{$diff}, $diff;
}
