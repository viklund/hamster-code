#!/usr/bin/env perl
use strict;
use warnings;

use feature qw/ say state /;
use Time::Piece;

use List::Util qw/ sum /;

my %counts;

my @times = ();
my $last;
for my $file (glob("logs/*.log")) {
    open my $HAMSTER, '<', $file or die "Could not open $file: $!, $?";
    while (my $date = <$HAMSTER>) {
        chomp($date);

        push @times, $date;
        if ( $last ) {
            my $seconds = $date - $last;
            $counts{ sprintf("%.02f", $seconds) }++;
        }
        $last = $date;
    } 
}

for my $diff ( sort { $a <=> $b } keys %counts ) {
    last if $diff > 3; # If time is more than 10 seconds, skip
    last if $counts{$diff} < 5 && $diff > 0.5;
    printf "%5d  %8.2f\n", $counts{$diff}, $diff;
}

sub my_epoch_parser {
    my $time = shift;
    state $epoch_base;
    #my ($year, $month, $day, $hour, $minute, $second) = $time =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)$/;
    my ($year, $month, $day, $hour, $minute, $second) = unpack("A4xA2xA2xA2xA2xA2",$time);

    if ( !ref($epoch_base) || $epoch_base->{month} != $month) {
        my $start = Time::Piece->strptime("$year-$month-01 00:00:00", '%Y-%m-%d %H:%M:%S');
        $epoch_base = {
            year => $year,
            month => $month,
            base => $start->epoch,
        }
    }
    return $epoch_base->{base} + ($day-1)*86400 + $hour*3600 + $minute*60 + $second;
}
