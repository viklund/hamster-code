#!/usr/bin/env perl
use strict;
use warnings;

use feature qw/ say /;
use Data::Dumper;
use DateTime;

use List::Util qw/ sum /;

open my $HAMSTER, '<', 'hamster-spinner.log' or die;

my $CUTOFF = 0.34; # Valley from stats

my @times = ();
my @current = ();
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
        time_zone => 'floating',
    );

    if ( ! @current ) {
        push @current, $date;
        next;
    }
    if ( cdiff( $date, $current[$#current] ) <= $CUTOFF ) {
        push @current, $date;
        next;
    }
    if ( @current ) {
        if ( @current > 1 ) {
            my $diff = $current[-1] - $current[0];
            my @d =  $diff->in_units('days', 'minutes', 'nanoseconds');
            $current[0]->add(days => $d[0]/2, minutes => $d[1]/2, nanoseconds => $d[2]/2);
        }
        push @times, $current[0];
        #say $current[0]->strftime('%FT%T.%N');
        @current = ($date);
    }
} 
if ( @current ) {
    if ( @current > 1 ) {
        my $diff = $current[-1] - $current[0];
        my @d =  $diff->in_units('days', 'minutes', 'nanoseconds');
        $current[0]->add(days => $d[0]/2, minutes => $d[1]/2, nanoseconds => $d[2]/2);
    }
    push @times, $current[0];
    @current = ();
}

### Since it most probably starts with the weight down, the first instance is a
### half lap. So we need to detect every "session" and then for every session
### remove 0.5.
my $DAY_CUTOFF = 3600;
my $SESSION_CUTOFF = 1;

my $tot_laps = 0;
my $tot_seconds = 0;
@current = ();
my ($prev, $start);
for my $t (@times) {
    if ( ! @current ) {
        @current = ($t);
        $prev = $start = $t;
        next;
    }
    my $cdiff = cdiff( $t, $current[-1] );
    if ( $cdiff <= $SESSION_CUTOFF ) {
        push @current, $t;
        $prev = $t;
        next;
    }
    elsif ( $cdiff > $DAY_CUTOFF ) {
        printf "Runner: %6.2f km (%5d %5.2f) %s -- %s\n",
            $tot_laps * 3.14 * 0.2 / 1000,
            $tot_laps, $tot_seconds/3600,
            $start->iso8601, $prev->iso8601;
        $tot_laps = 0;
        $tot_seconds = 0;
        $start = $t;
    }
    elsif ( @current > 1 ) {
        my $laps = @current - 0.5;
        $tot_laps += $laps;
        my $s = cdiff($current[$#current], $current[0]);
        $tot_seconds += $s;
    }
    @current = ($t);
    $prev = $t;
}

printf "Runner: %6.2f km (%5d %5.2f) %s -- %s\n",
    $tot_laps * 3.14 * 0.2 / 1000,
    $tot_laps, $tot_seconds/3600,
    $start->iso8601, $prev->iso8601;
#printf "Naive calculation: %6.2f km\n", scalar(@times) * 3.14 * 0.2 / 1000;
#printf "Smart calculation: %6.2f km\n", $tot_laps * 3.14 * 0.2 / 1000;

#say $tot_laps;
#say $tot_seconds;
#say $tot_laps / $tot_seconds;

sub cdiff {
    my ($dt1, $dt2) = @_;
    my $diff = $dt1 - $dt2;
    my @diff = $diff->in_units('days', 'minutes', 'nanoseconds');
    my @weight = (60*60*24, 60, 10**-9);
    my $seconds = sum map { $diff[$_]*$weight[$_] } 0..$#diff;
    return $seconds;
}

for my $t ( @times ) {

}
