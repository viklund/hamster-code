#!/usr/bin/env perl
use strict;
use warnings;

use feature qw/ say /;
use Time::Piece;

use List::Util qw/ sum /;

my $CUTOFF = 0.34; # Valley from stats

my @times = ();
my @current = ();

for my $file (glob("logs/*.log")) {
    open my $HAMSTER, '<', $file or die "Could not open $file: $!, $?";
    while (my $date = <$HAMSTER>) {
        chomp($date);

        if ( ! @current ) {
            push @current, $date;
            next;
        }
        if ( $date - $current[$#current] <= $CUTOFF ) {
            push @current, $date;
            next;
        }
        if ( @current ) {
            if ( @current > 1 ) {
                my $diff = $current[-1] - $current[0];
                $current[0] += $diff/2;
            }
            push @times, $current[0];
            @current = ($date);
        }
    }
}
if ( @current ) {
    if ( @current > 1 ) {
        my $diff = $current[-1] - $current[0];
        $current[0] += $diff/2;
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
    my $cdiff = $t - $current[-1];
    if ( $cdiff <= $SESSION_CUTOFF ) {
        push @current, $t;
        $prev = $t;
        next;
    }
    elsif ( $cdiff > $DAY_CUTOFF ) {
        my $hours = int($tot_seconds/3600);
        printf "%6.2f km (%5d %2d:%2d)  |  %s -- %s\n",
            $tot_laps * 3.14 * 0.2 / 1000,
            $tot_laps, $hours, ($tot_seconds-$hours*3600)/60,
            Time::Piece->strptime(int($start), '%s')->datetime,
            Time::Piece->strptime(int($prev), '%s')->datetime
            if $tot_laps > 1;
        $tot_laps = 0;
        $tot_seconds = 0;
        $start = $t;
    }
    elsif ( @current > 1 ) {
        my $laps = @current - 0.5;
        $tot_laps += $laps;
        my $s = $current[$#current] - $current[0];
        $tot_seconds += $s;
    }
    @current = ($t);
    $prev = $t;
}

my $hours = int($tot_seconds/3600);
printf "%6.2f km (%5d %2d:%2d)  |  %s -- %s\n",
    $tot_laps * 3.14 * 0.2 / 1000,
    $tot_laps, $hours, ($tot_seconds-$hours*3600)/60,
    Time::Piece->strptime(int($start), '%s')->datetime,
    Time::Piece->strptime(int($prev), '%s')->datetime
