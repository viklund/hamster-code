#!/usr/bin/perl

use strict;
use warnings;

use Time::Piece;
use feature qw/ say /;

use File::Copy qw( copy );

my $hugo_base = $ENV{HOME} . '/hamster/hamster-hugo';
my $hugo_dir  = $hugo_base . '/content/weeks';
my $hugo_stat = $hugo_base . '/static';

unless ( -d $hugo_dir ) {
    mkdir $hugo_dir;
}

my %index_for;

for my $plot (glob "plots/*.png") {
    # plots/speed-20210306.png
    my ($date) = $plot =~ m{ - (\d+) \. png $}x;
    my $time = Time::Piece->strptime($date, "%Y%m%d");

    my $week = $time->week;
    my $target_file = sprintf "%s/%02d.md", $hugo_dir, $week;

    push @{$index_for{$target_file}}, $plot;

    my $destination_img_file = sprintf "%s/%s", $hugo_stat, $plot;
    copy($plot, $destination_img_file);
}

for my $file ( keys %index_for ) {
    say STDERR "Writing file $file";
    my ($week) = $file =~ m{ / (\d+)\.md $ }x;
    open my $FH, '>', $file or die;
    print $FH <<__END__;
+++
title = "Plots for week $week"
+++

__END__
    # plots/speed-20210314.png
    for my $img ( @{ $index_for{$file} } ) {
        printf $FH qq[{{< figure src="/%s" class="plot" >}}\n], $img;
    }
}
