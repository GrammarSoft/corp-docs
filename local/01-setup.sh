#!/bin/bash
DIR="$(cd $(dirname $0);pwd)"
USER_UID=$(id -u)
USER_GID=$(id -g)

if [ ! -s "/etc/apt/sources.list.d/docker.sources" ]; then
	echo "Installing Docker from https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository - if you don't want this, hit Ctrl-C within 10 seconds"
	echo ""
	sleep 10

	sudo apt-get remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
	sudo apt-get -qqy update
	sudo apt-get -qfy install ca-certificates curl
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc

	sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

	sudo apt-get -qfy install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

sudo apt-get -qqy update
sudo apt-get -qfy install --no-install-recommends composer

cd "$DIR"
pushd docker
	sudo docker build --pull --build-arg USER_UID=$USER_UID --build-arg USER_GID=$USER_GID -t gs-manatee .
popd

mkdir -pv tmp/storage/corpora tmp/public_html tmp/bin tmp/sources
cp -av ../corpus/word2vec tmp/bin/
pushd tmp

pushd public_html
	if [ -s "_inc/config.php" ]; then
		read -p "config.php already exists - next step will rsync and overwrite local changes. Hit Ctrl-C to stop here, or Y to continue: " Y
	fi
	if [ "$Y" != "y" ] && [ "$Y" != "Y" ]; then
		exit
	fi
	rsync -avzHAXx --inplace '--exclude=.vscode' manatee@corp2.visl.dk:./public_html/ ./
	git pull --all --rebase --autostash
	composer upgrade
popd

pushd storage
	pushd corpora
		ssh manatee@corp2.visl.dk 'cd storage/corpora; find . -type d -print0' | xargs -0r mkdir -pv
		ssh manatee@corp2.visl.dk 'cd storage/corpora; find . -type f -print0' | xargs -0r touch -a
	popd
	rsync -avzHAXx --inplace '--exclude=cache/**' '--include=*/' '--exclude=*.sqlite' '--exclude=corpora/*/*.*' manatee@corp2.visl.dk:./storage/ ./
popd
