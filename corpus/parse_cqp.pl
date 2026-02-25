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

#script for parsing a corpora into a format compatible with CQP
# Usage for ISO-8859-1 data:
#  ./parse.pl input.cg > output
#
# Usage for UTF-8 data:
# PERL_UNICODE=SDA ./parse.pl input.cg | u2i > output
#
#example:     er      [være]      <mv>       V      PR AKT         @FMV      barelgazel
#meaning:     ordet   grundform    ?         ordklasse   Morfologi   Funktion  Tekst-kilde
#attr-name:   word    lex         extra       pos      morph            func      src
#
#Sentences are marked with <s> and </s>
#
#Special characters as , and . appears as a normal word, but with all the fields empty (except src)
#                   in the input, special characters are thos that is after $
#


my $line = 1;     #counter to hold the current line number

#HACK - end sequence to mark the en of a word.
# this string MUST NOT be anywhere else in the input
my $end_seq = "_End!_";

my $fs_func = '';

#Read all lines from the file(s) given as argument and parse them
while (defined(my $input = <>)) {
   my ($dself, $dparent) = (0, 0);

   # skip <s> tags so they don't get mangled
   if ($input =~ m@^<s@) {
      print $input;
      print "¤\t¤\t\tPU\t\tSTART\t\t0\t0\t$end_seq\n";
      next;
   }
   if ($input =~ m@^</s@) {
      print $input;
      next;
   }
   # remove paragraph signs
   if ($input =~ /^\$¶.*/) {
      next;
   }

   $input =~ s/[\x{7F}-\x{9F}]+//g;
   $input =~ s/§ARG[0-9]& //g;

   # Extract semantic roles
   my $role = '';
   while ($input =~ s/\s+[§%](\S+)//) {
      $role .= "$1 ";
   }
   $role =~ s/\s+$//g;

   #   print "--$input";
   while ($input =~ s/ £([^ ]+)//) { # dangram --onto input
      my $sem = $1;
      if ($input !~ /<\Q$sem\E>/) {
         $input =~ s/ (N|PROP|NUM|ADJ) / <$sem> $1 /;
      }
   }
   $input =~ s/ [\£&][^ \n]+//g;
   $input =~ s/ <((fr?|se):[^>]*|Rare[^>]*?|\'[^>]*?\'|exdem|\+[^>]*?|[0-9]+)>//g; # frequency, translation etc.
   # dependency
   if ($input =~ s/\s+#(\d+)(?:->|\x{2192})(\d+)//) {
      ($dself,$dparent) = (int($1), int($2));
   }
   $input =~ s/\x{a0}/ /g; # ASCII 00A0, wrong space from Brazio-dos (Raquel)
   $input =~ s/^< *\n//; # isolated < lines from wiki
   $input =~ s/(\t *[^\t]+).*/$1/; # removes all but one morph-reading
   $input =~ s/ KC( .*)(<adv>)+/ $2 KC$1/g; # midlertidig K2000 lap, nu klaret i remove_secondary.dansk
#   $input =~ s/<ext /<s_/;
   $input =~ s/\] +(.*[A-Z] ) *((<[^>\@ ]+> )+)/\] $2 $1/g; # <..> left of word class
#   print "her: $input __\n";
   if ($input =~ /<ext/) {
      $input =~ s/ cad=\"(.*?)\".*sec=\"(.*?)\".*?>/-$1-$2>/; # folha
      $input =~ s/ sec=(.*?) .*sem=(.*?)>/-$1-$2>/; # publico
   }
   $input =~ s/^\$¤.*START.*\n//g; # now automated for all corpora through parse_new.pl

   ### next lines only for Portuguese??
   $input =~ s/( [A-Z]+) +(\@[\#&])/$1 \@X $2/g; # add @ function where missing in Portuguese (que, quem ...)
   $input =~ s/([A-Z]) +(<?[A-Z\-]+[><]?) *$/$1 \@$2/; # missing @ in function symbol (e.g. N<)
   #$input =~ s/\] *\t+ */\] /; # erroneous tab after base form
   $input =~ s/(\s\[[^ \]]+) /$1\] /; # missing right ] after base form
   $input =~ s/<poss +([^<>]+)>/<poss-$1>/g; # <poss 1P>
   if ($input =~ /(<(rel|inter+|int)>| KS )/ && $input =~ /\@[\#\&]?FS-/) {
      $input =~ s/ \@[\#&]?FS-([A-Z<>]+)//g;
      $fs_func =$1; # pt: save fs-clause function from complementizer
   }
   elsif ($input =~ /\@F(MV|AUX)/ && $fs_func) {
      my $verb =$1; # pt and es
      $input =~ s/\]/\] <fcl> <\L$verb>/g;
      $input =~ s/\@/\@$fs_func \@/; # pt: add fs-clause function from complementizer
      $fs_func ="";
      $input =~ s/ \@[IF](MV|AUX)//g;
   }
   elsif ($input =~ s/\](.*?)\@[\#\&]?([FIA])(S|CL)-/\] <\l$2cl>$1\@/g) { # so e.g. relative clauses can be searched as VFIN pos and N< function
      $input =~ s/\@[\#&]?(FS|ICL|AS)-/\@/g;
      if ($input =~ / \@[IF](MV|AUX)/) { # sub clause
         my $verb =$1; # pt and es
         $input =~ s/\]/\] <\L$verb>/g;
         $input =~ s/ \@[IF](MV|AUX)//g;
      }
   }
   if ($input =~ / \@[IF](MV|AUX)/) { # main clause (STA)
      my $verb ="\L$1"; # pt and es
      if (! $input =~ /<$verb>/) {$input =~ s/\]/\] <$verb>/g;}
      $input =~ s/ \@[IF](MV|AUX)/ \@STA/g;
   }
#   $input =~ s/ <[^ ]+>//g; # remove secondary so cqp doesn't get too complex

   $input =~ s/(PR|PAST|IMPF|AUXMOD) (VFIN)/$1 SP $2/g; # Engcg "do" and AUUXMOD

   $input =~ s/ (&[A-Za-z\-]*|VFIN|CENTRAL) / /g; # bnc
#   $input =~ s/(id=|ID=)[a-zA-Z]+([0-9]+)/$1$2/; # korpus90/2000 complexity reduction
   $input =~ s/<pound-sign>/£/g;
   if ($input =~ /Not Enklish/ || $input =~ /\s\[\]/ || $input =~ /\s\[laid back\]/) {
      # engcg: !) etc.
      # engcg: rare special characters, removed, yield empty [] base forms
      # engcg: rare special characters
      $input = '';
   }
#   $input =~ s/^.*\[.* .*\]*\n//g; # engcg: rare special characters
   $input =~ s/^¤\t¤ PU /\$¤\t\[¤\] PU /g;
   $input =~ s/^\$\[/\$\{/g; # [ not tolerateted by parse.pl or cqp?
   $input =~ s/^\$\]/\$\}/g; # ] not tolerateted by parse.pl or cq
   $input =~ s/^\$+ *\n/USD\t\[USD\] N NOM P \@>N\n/g; # empty $ in bnc (also as a substitute for &, therefor best in corpfilter.bnc)
   $input =~ s/^([\$<]) *$/\$$1/g; # stray $ and <
   $input =~ s/^([0-9]+[A-Za-z]*).*&\?\?.*$/$1\t\[$1\] NUM P \@N</g; # March 721X
   $input =~ s/--prozent/%\t[%] N NEU P \@X/g;
   $input =~ s/ &&\S+/ /g; # &&SUBJ
   $input =~ s/\@\#/\@/g; # fejl from older version of engrun.corpus

   $input =~ s/ (NOM|ACC|AKK|DAT|GEN|PIV)\// $1 /g; # slash leads to java-program bug that does not include slash in \w (I suppose) and creates an extra field - the tags will be shown under the word form in the concordance
   $input =~ s/([0-3 ])SG?\/PL?/$1SP/g; # general 0123S/P
   $input =~ s/M\/F/MF/g; # general 0123S/P
   $input =~ s/([0-3]+)\/([0-3]+)([SP])[GL]?/$1$2$3/g; # general 1/3S
   $input =~ s/([0-3]+)\/([0-3]+)([SP])[GL]?/$1$2$3/g; # general 1/3S, has to be repeated due to Portuguese 0/1/3S
   $input =~ s/([SP])[GL]?1\/3/13$1/g;

   if ($input !~ m@^</@) {
      # Don't eat </s> lines
#      $input =~ s@/@~u2044@g; # Unicode U+2044 Fraction Slash
   }
   $input =~ s/\'/´/g;
   if (! ($input =~ /[\[]/)) {
      $input =~ s/^ *([^<\$ \t\n])/\$$1/; # one of the worst problems: tokens without readings, but which are not recognized as punctuation (--vi, unknown English etc.) --- here parse.pl somehow fails to put \n after _End!_ in the .out files, which complete freezes the cqp-calling cgi, if a search hits that sentence
   }


   remove_tags($input);
   clean_numbers($input);
   #clean_delimiters($input);

   #remove_comments($input)

   #Skip empty lines
#   if(! ($input =~ /.+/) ) {
#   print "--her: $input...";
   if(! ($input =~ /.+/) || $input =~ /^\$?[ \t]/) {
      next;
   }

   # Extract word
   $input =~ s/^([^\t]+?)\s+//;
   my $word = $1;
   make_spaces($word);

   # Extract lemma
   $input =~ s/^\[(.+?)\]\s+/ /; # Leave initial space for next parts
   my $lex = $1;
   make_spaces($lex);

   # Extract secondary tags
   my $extra = '';
   while ($input =~ s/\s+<(\S*)>//) {
      $extra .= "$1 ";
   }
   # ...and relation ID
   while ($input =~ s/\s+(ID:\S*)//) {
      $extra .= "$1 ";
   }
   # ...and relation labels
   while ($input =~ s/\s+(R:\S*)//) {
      $extra .= "$1 ";
   }
   $extra =~ s/\s+$//g;

   # Extract syntactic functions
   my $func = '';
   while ($input =~ s/\s+\@(\S*)//) {
      $func .= "$1 ";
   }
   $func =~ s/\s+$//g;

   # Extract POS
   $input =~ s/\s+([A-Z]\S*)//;
   my $pos = $1 || 'X';

   # Extract morph
   my $morph = '';
   while ($input =~ s/\s+([a-zA-Z0-9]\S*)//) {
      $morph .= "$1 ";
      $morph =~ s/([A-Z])\/([A-Z])/$1 $2/g; # general / -> space
   }
   $morph =~ s/\s+$//g;

   if (!$word) {
      next;
   }

   print "$word\t$lex\t$extra\t$pos\t$morph\t$func\t$role\t$dself\t$dparent\t$end_seq\n";

   $line++;
   slut:
}


sub clean_numbers {
   $_[0] =~ s/^\$(.*\s*\[)/$1/;
   #print "$_[0]";
   #$_[0] = "";
}

sub clean_delimiters {
   if($_[0] =~ /^\$./) {
      $_[0] =~ s/^\$(\S).*$/$1\t\t\t\t\t\t\t$end_seq/;
#      $_[0] =~ s/ +\t/\t/g;
      print "$_[0]";
      $_[0] = "";
   }
}

#removes all lines starting with < except "<s.*" and "</.*"
sub remove_tags {
   $_[0] =~ s@^<[^s/].*$@@;
}

#Function for removing comments
#Comments is all lines beginning with $
sub remove_comments {
   if($_[0] =~ /^[\$|<].*/) {
      print STDERR "Warning: Ignoring comment (L$line): $[0]\n";
      $_[0] =~ s/^[\$|<].*//;
   }
   #$_[0] =~ s/^[\$].*//;
}

sub make_spaces {
   $_[0] =~ s/^_//; # _'d from I _'d
   $_[0] =~ s/_$//; # _'d from I_ 'd
   my $l = '';
   my $t = '';
   if ($_[0] =~ s@^(=+)@@) {
      $l = $1;
   }
   if ($_[0] =~ s@(=+)$@@) {
      $t = $1;
   }
   $_[0] =~ s/[=|_]/ /g;
   $_[0] = $l.$_[0].$t;
}
