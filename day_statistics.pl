#!/usr/bin/env perl

use strict;
use warnings;

use feature qw/ say /;

### Since it most probably starts with the weight down, the first instance is a
### half lap. So we need to detect every "session" and then for every session
### remove 0.5.


for my $file (glob('days/counter-*.log')) {
    open my $FILE, '<', $file or die "Could not read $file: $!, $?";
    my ($date) = $file =~ m{^ days/ [^0-9]+ (\d+) \.log $}x;
    my $stats = calculate($FILE);
    display_stats($stats->{laps}, $stats->{seconds}, $date);
}


sub calculate {
    my $FH = shift;
    my $SESSION_CUTOFF = shift // 1;

    my $tot_laps = 0;
    my $tot_seconds = 0;
    my @current = ();

    my ($prev, $start);
    while (my $t = <$FH>) {
        #chomp($t);
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
        elsif ( @current > 1 ) {
            my $laps = @current - 0.5;
            $tot_laps += $laps;
            my $s = $current[$#current] - $current[0];
            $tot_seconds += $s;
        }
        @current = ($t);
        $prev = $t;
    }
    return {
        laps => $tot_laps,
        seconds => $tot_seconds,
    };
}

sub display_stats {
    my ($tot_laps, $tot_seconds, $date) = @_;
    my $hours = int($tot_seconds/3600);
    printf "%6.2f km (%5d %2d:%02d)  |  %s\n",
        $tot_laps * 3.14 * 0.2 / 1000,
        $tot_laps, $hours, ($tot_seconds-$hours*3600)/60,
        $date,
        #Time::Piece->strptime(, '%s')->datetime,
        #Time::Piece->strptime(int($prev), '%s')->datetime
        #if $tot_laps > 1
}
