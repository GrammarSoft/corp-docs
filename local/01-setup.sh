#!/bin/bash
DIR="$(cd $(dirname $0);pwd)"
USER_UID=$(id -u)
USER_GID=$(id -g)

sudo apt-get -qy update
sudo apt-get -qfy --no-install-recommends composer

cd "$DIR"
pushd docker
	sudo docker build --pull --build-arg USER_UID=$USER_UID --build-arg USER_GID=$USER_GID -t gs-manatee .
popd

mkdir -pv tmp/storage/corpora tmp/public_html tmp/bin tmp/sources
cp -av ../corpus/word2vec tmp/bin/
pushd tmp

pushd public_html
	if [ -s "_inc/config.php" ]; then
		read -p "config.php already exists - next step will rsync and overwrite local changes. Hit CTRL-C to stop here, or enter to continue with sync" SKIP
	fi
	rsync -avzHAXx --partial '--exclude=.vscode' manatee@corp2.visl.dk:./public_html/ ./
	git pull --all --rebase --autostash
	composer upgrade
popd

pushd storage
	pushd corpora
		ssh manatee@corp2.visl.dk 'cd storage/corpora; find . -type d -print0' | xargs -0r mkdir -pv
		ssh manatee@corp2.visl.dk 'cd storage/corpora; find . -type f -print0' | xargs -0r touch
	popd
	rsync -avzHAXx --partial '--exclude=cache/**' '--include=*/' '--exclude=*.sqlite' '--exclude=corpora/*/*.*' manatee@corp2.visl.dk:./storage/ ./
popd
