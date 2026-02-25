#!/usr/bin/env perl
# -*- mode: cperl; indent-tabs-mode: nil; tab-width: 3; cperl-indent-level: 3; -*-
use strict;
use warnings;
use utf8;
BEGIN {
	$| = 1;
	binmode(STDIN, ':encoding(UTF-8)');
	binmode(STDOUT, ':encoding(UTF-8)');
}
use open qw( :encoding(UTF-8) :std );
use feature 'unicode_strings';

my %fs = (
   'word' => 0,
   'lex' => 1,
   'extra' => 2,
   'pos' => 3,
   'morph' => 4,
   'func' => 5,
   'role' => 6,
   'dself' => 7,
   'dparent' => 8,
   'endmark' => 9,
   );

my @lines = ();
my %deps = ();

sub process {
   if (!scalar(@lines)) {
      return;
   }

   for my $line (@lines) {
      print join("\t", @$line);
      if (@{$line}[$fs{'dself'}] == 0) {
         print "\t\t\t\t\t\t\t\t\t\t";
      }
      elsif (@{$line}[$fs{'dparent'}] == 0) {
         print "\t¤\t¤\t\tPU\t\tSTART\t\t0\t0\t_End!_";
      }
      elsif (@{$line}[$fs{'dparent'}] && exists($deps{@{$line}[$fs{'dparent'}]}) && @{$deps{@{$line}[$fs{'dparent'}]}}) {
         print "\t".join("\t", @{$deps{@{$line}[$fs{'dparent'}]}});
      }
      print "\n";
   }

   @lines = ();
   %deps = ();
}

while (<STDIN>) {
   chomp;
   my @line = split(m@\t@);

   if (m@^</?s@ || /^<STREAMCMD:FLUSH>/) {
      process();
      print "$_\n";
   }

   if (!exists $line[$fs{'dself'}]) {
      next;
   }
   if ($line[$fs{'dself'}] == 1) {
      process();
   }

   push(@lines, [@line]);

   my $s = int($line[$fs{'dself'}]);
   my $p = int($line[$fs{'dparent'}]);
   if ($s) {
      $deps{$s} = [@line];
   }
   if ($p && !defined $deps{$p}) {
      $deps{$p} = [];
   }
}

process();
