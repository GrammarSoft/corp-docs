# Corpus Encoding

## Tools
* `chunk-tag.pl` `[--tag s]` `[--size 100]` `[--out split]` <br>
  Splits input into chunks of `size` MiB each named `out-NNNNN.zst`, making sure `<tag>` structures are not split in the middle.
* `depcqp-append.pl` <br>
  Takes a dependency stream from `parse_cqp.pl` and appends each token's parent to itself.
* `encode.sh` <br>
  Example CWB/CQP encoding script for corpora that have dependency.
* `i2u`
  Converts a stream from ISO-8859-1 to UTF-8.
* `parse_cqp.pl` <br>
  Converts a VISL stream into CQP-compatible verticalized text.
* `split-year.pl` <br>
  Splits and reenumerates input into years, according to the `stamp="YYYY-MM-DD"` attribute. Assumes that the input is sorted by this timestamp.
* `u2h` <br>
  Converts a stream from UTF-8 to ISO-8859-1, but encodes unrepresentable characters as hexadecimal `\uNNNN` or `\UNNNNNNNN`.
* `u2i` <br>
  Converts a stream from UTF-8 to ISO-8859-1. Converts combining characters to NFD and strips remaining characters that are not representable.

## From VISL to UTF-8 verticalized text
Combined:
`zstdcat input.zst | perl -Mutf8 -wpne 's/<FN:([^>]+)&&([^>]+)>/<FN:$1> <FN:$2>/ig; s/<FN:([^>\/]+).*?>/<fn:$1>/ig; if (! / id=/) {s/^<s([ >])/<s id="0"$1/;}' | perl -Mutf8 -we 'my $s=""; my $nf=0; while (<STDIN>) { if (/^<s /) {$s=$_;} if (/ #1->/) { if ($nf) { print "</s>\n$s"; } else { $nf=1; } } print; }' | parse_cqp.pl | depcqp-append.pl | perl -Mutf8 -we 'my $i=0; while(<STDIN>) { if (/^<s /) {++$i; s/^<s id="([^"]+)"/<s id="$i"/;} print;}' | zstd -15 -T0 -c >output.zst`

This yields a Manatee compatible file. This cannot be used with VISL's CQP setup, but instructions for that is below.

Pieces:
* `perl -Mutf8 -wpne 's/<FN:([^>]+)&&([^>]+)>/<FN:$1> <FN:$2>/ig; s/<FN:([^>\/]+).*?>/<fn:$1>/ig; if (! / id=/) {s/^<s([ >])/<s id="0"$1/;}'` turns complex frames into something manageable and ensures `<s>` tags have an id.
* `perl -Mutf8 -we 'my $s=""; my $nf=0; while (<STDIN>) { if (/^<s /) {$s=$_;} if (/ #1->/) { if ($nf) { print "</s>\n$s"; } else { $nf=1; } } print; }'` duplicates the `<s>` tags for each new actual sentence, as denoted by a cohort having 1 as its number. This only makes sense if there is a unique identifier to find the whole segment context again, such as `tweet="NNNNN"`.
* `perl -Mutf8 -we 'my $i=0; while(<STDIN>) { if (/^<s /) {++$i; s/^<s id="([^"]+)"/<s id="$i"/;} print;}'` reenumerates sentences

## From UTF-8 verticals to ISO-8859-1 hex verticalized text
Combined:
`zstdcat input.zst | perl -wpne 'if (/\t/) { s@/@~u2044@g;}' | u2h | PERL_UNICODE= LC_ALL=C perl -wpne 's@\\([uU])([0-9A-Fa-f]{4,8})@~$1$2@g;' | pigz -1c >output.gz`

This yields a VISL CQP compatible file.

Pieces:
* `PERL_UNICODE= LC_ALL=C perl -wpne 's@\\([uU])([0-9A-Fa-f]{4,8})@~$1$2@g;'` converts ICU's `\u` escapes to `~u` escapes.

## VISL CQP encoding
Adjust s-attributes and PATH in `encode.sh` and call it:
`./encode.sh /path/to/input.gz corpus_name`

Squash it to a minimal size:
`mksquashfs corpus_name corpus_name.squashfs -no-exports -no-xattrs -info -progress -comp zstd -Xcompression-level 15`

Transfer squashed file to `corp.hum.sdu.dk:/home/cwb/`, create folder and registry, adjust `/etc/rc.local` to mount it on boot, mount it, then adjust `/home/httpd/cgi-bin/cqp.cgi` with the new data.
