#!/bin/bash
DIR="$(cd $(dirname $0);pwd)"
cd "$DIR"

echo "1) Move or copy the corpus to a zstd-compressed file in $DIR/tmp/sources/ named as e.g. eng_wikipedia.zst"
echo "2) Create corpus registry file in $DIR/tmp/storage/registry/ e.g. eng_wikipedia"
echo "3) Add the corpus to $DIR/tmp/public_html/_inc/config.php with correct group_by and word2vec arrays if corpus should support those"
echo "4) Optionally limit access by editing $DIR/tmp/public_html/_inc/auth-impl.php"
echo ""

C=""
if [ -s "tmp/sources/$1.zst" ]; then
	C="$1"
else
	read -p "Corpus name, e.g. eng_wikipedia: " C
	if [ ! -s "tmp/sources/$C.zst" ]; then
		echo "ERROR: No such file $DIR/tmp/sources/$C.zst !"
		exit
	fi
fi

sudo docker run -it --rm -v "$DIR/tmp:/home/manatee" --entrypoint /home/manatee/public_html/_bin/encode-corpus gs-manatee "$C"
