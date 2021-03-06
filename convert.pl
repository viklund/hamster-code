#!/usr/bin/env perl
use strict;
use warnings;

use feature qw/ say state /;
use Time::Piece;

use List::Util qw/ sum /;

my $CUTOFF = 0.34; # Valley from stats

open my $HAMSTER, '<', 'hamster-spinner.log' or die;
while (<$HAMSTER>) {
    # 2021-03-04 06:32:28.177878  35520   
    #my ($time, $millis, $count) = /^([^.]+)\.(\d+)\s+(\d+)\s*$/;
    my ($time, $millis) = unpack("A19xA6",$_);

    #my $date = Time::Piece->strptime($time, '%Y-%m-%d %H:%M:%S')->epoch + $millis/1_000_000;
    my $date = my_epoch_parser( $time ) + $millis/1_000_000;
    say $date;
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
