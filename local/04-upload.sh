#!/bin/bash
DIR="$(cd $(dirname $0);pwd)"
cd "$DIR"

C=""
if [ -s "tmp/storage/corpora/$1/meta/stats.sqlite" ]; then
	C="$1"
else
	read -p "Corpus name, e.g. eng_wikipedia: " C
	if [ ! -s "tmp/storage/registry/$C" ]; then
		echo "ERROR: No such file $DIR/storage/registry/$C !"
		exit
	fi
	if [ ! -s "tmp/storage/corpora/$C/meta/stats.sqlite" ]; then
		echo "ERROR: No such file $DIR/storage/corpora/$C/meta/stats.sqlite !"
		exit
	fi
fi

pushd tmp/public_html
	echo "git diff:"
	git diff
	echo ""
	echo "git status:"
	git status
	echo ""

	read -p "If the above git diff and git status show uncommitted changes that you want to keep, enter the folder '$DIR/tmp/public_html/' and commit + push them before continuing. Uncommitted changes will be lost after this step! Hit Ctrl-C to stop here, or Y to continue: " Y
	if [ "$Y" != "y" ] && [ "$Y" != "Y" ]; then
		exit
	fi
	echo ""

	git reflog expire --expire=now --all
	git repack -ad
	git prune
	git clean -f -d
	git reset --hard HEAD
	echo ""

	rsync -avzHAXx --inplace manatee@corp2.visl.dk:./public_html/_inc/config.php "/tmp/corp-$$.config"
	rsync -avzHAXx --inplace manatee@corp2.visl.dk:./public_html/_inc/auth-impl.php "/tmp/corp-$$.auth"
	echo ""

	if [ "/tmp/corp-$$.config" -nt "_inc/config.php" ]; then
		read -p "Server has newer config.php - someone has potentially made conflicting changes! Next step will rsync and overwrite those changes. Hit Ctrl-C to stop here, or Y to continue: " Y
	fi
	if [ "$Y" != "y" ] && [ "$Y" != "Y" ]; then
		exit
	fi
	if [ "/tmp/corp-$$.auth" -nt "_inc/auth-impl.php" ]; then
		read -p "Server has newer auth-impl.php - someone has potentially made conflicting changes! Next step will rsync and overwrite those changes. Hit Ctrl-C to stop here, or Y to continue: " Y
	fi
	if [ "$Y" != "y" ] && [ "$Y" != "Y" ]; then
		exit
	fi
popd

pushd tmp
	pushd storage
		rsync -avzHAXx --inplace registry/$C manatee@corp2.visl.dk:./storage/registry/
		rsync -avzHAXx --inplace corpora/$C manatee@corp2.visl.dk:./storage/corpora/
		if [ -d "word2vec/$C" ]; then
			rsync -avzHAXx --inplace word2vec/$C manatee@backends.gramtrans.com:./storage/word2vec/
		fi
	popd

	rsync -avzHAXx --inplace --delete --exclude=dev public_html manatee@corp2.visl.dk:./
popd
