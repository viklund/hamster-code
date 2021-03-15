#!/usr/bin/env perl
use strict;
use warnings;

use feature qw/ say /;
use List::Util qw/ sum /;

use Time::Piece;
use Time::Seconds;

my $CUTOFF = 0.40; # Valley from stats
my $FILE_FORMAT = 'days/counter-%Y%m%d.log';

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

my $start_day = localtime($times[0])->truncate(to => 'day')->epoch - ONE_DAY/2;
my $next_day = $start_day + ONE_DAY;

if ( $times[0] > $next_day ) {
    ($start_day, $next_day) = ($next_day, $next_day+ONE_DAY);
}

open my $OUT, '>', localtime($start_day)->strftime($FILE_FORMAT);

for my $t (@times) {
    if ( $t > $next_day ) {
        ($start_day, $next_day) = ($next_day, $next_day+ONE_DAY);
        close $OUT;
        open $OUT, '>', localtime($start_day)->strftime($FILE_FORMAT);
    }
    say $OUT $t;
}

my $now = localtime;
my $today_file = $now->strftime($FILE_FORMAT);

if ( $now->hour >= 12 && ! -f $today_file ) {
    system('touch', $today_file);
}
