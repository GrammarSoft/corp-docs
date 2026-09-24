#!/usr/bin/env perl
# -*- mode: cperl; indent-tabs-mode: nil; tab-width: 3; cperl-indent-level: 3; -*-
use warnings;
use strict;
use bytes;
no utf8;
BEGIN {
   $| = 1;
   binmode(STDIN);
   binmode(STDOUT);
}

my $tag = 's';
my $chunk = 100;
my $outname = 'split';

use Getopt::Long;
Getopt::Long::Configure('no_ignore_case');
my $rop = GetOptions(
   'tag|t=s' => \$tag,
   'size|s=s' => \$chunk,
   'out|o=s' => \$outname,
   );

print STDERR "Splitting on <${tag}> into ${chunk} MiB chunks.\n";

$chunk *= 1024 * 1024;

my $cur = 0;
my $outfile = $outname.'-'.sprintf('%05d', $cur).'.zst';
open(my $zo, '|-', "zstd -8 -T0 >$outfile");
binmode($zo);

my $cz = 0;
my $outbuf = '';
while (my $line = <STDIN>) {
   if ($cz >= $chunk && $line =~ m@^<\Q$tag\E[^>]*>@) {
      print STDERR "Limit for output file $outfile reached, opening ";
      print $zo $outbuf;
      close($zo);
      ++$cur;
      $outfile = $outname.'-'.sprintf('%05d', $cur).'.zst';
      print STDERR "$outfile ...\n";
      open($zo, '|-', "zstd -8 -T0 >$outfile");
      binmode($zo);
      $cz = 0;
      $outbuf = '';
   }

   $cz += length($line);
   $outbuf .= $line;
   if (length($outbuf) >= 268435456) {
      print $zo $outbuf;
      $outbuf = '';
   }
}

print $zo $outbuf;
close($zo);
