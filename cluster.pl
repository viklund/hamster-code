#!/usr/bin/env perl
use strict;
use warnings;

use feature qw/ say state /;
use Time::Piece;

use List::Util qw/ sum /;

open my $HAMSTER, '<', 'hamster-spinner.log' or die;

my $CUTOFF = 0.34; # Valley from stats

my @times = ();
my @current = ();
<$HAMSTER>;
while (<$HAMSTER>) {
    # 2021-03-04 06:32:28.177878  35520   
    #my ($time, $millis, $count) = /^([^.]+)\.(\d+)\s+(\d+)\s*$/;
    my ($time, $millis) = unpack("A19xA6",$_);

    #my $date = Time::Piece->strptime($time, '%Y-%m-%d %H:%M:%S')->epoch + $millis/1_000_000;
    my $date = my_epoch_parser( $time ) + $millis/1_000_000;

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
        printf "Runner: %6.2f km (%5d %5.2f) %s -- %s\n",
            $tot_laps * 3.14 * 0.2 / 1000,
            $tot_laps, $tot_seconds/3600,
            Time::Piece->strptime(int($start), '%s')->datetime,
            Time::Piece->strptime(int($prev), '%s')->datetime;
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

printf "Runner: %6.2f km (%5d %5.2f) %s -- %s\n",
    $tot_laps * 3.14 * 0.2 / 1000,
    $tot_laps, $tot_seconds/3600,
    Time::Piece->strptime(int($start), '%s')->datetime,
    Time::Piece->strptime(int($prev), '%s')->datetime;



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
