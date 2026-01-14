#!/bin/bash
DIR="$(cd $(dirname $0);pwd)"
USER_UID=$(id -u)
USER_GID=$(id -g)

cd "$DIR"
pushd docker
sudo docker build --pull --build-arg USER_UID=$USER_UID --build-arg USER_GID=$USER_GID -t gs-manatee .
popd

mkdir -pv tmp/storage
pushd tmp
if [ ! -d "public_html" ]; then
	git clone git@github.com:GrammarSoft/corp-ui.git public_html/
fi

pushd public_html
git up
composer upgrade
popd

pushd storage
rsync -avzPHAXx '--exclude=cache/**' '--include=*/' '--exclude=*.sqlite' '--exclude=corpora/*/*.*' manatee@corp2.visl.dk:./storage/ ./
popd
