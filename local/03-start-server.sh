#/bin/bash
DIR="$(cd $(dirname $0);pwd)"

cd "$DIR"
sudo docker run -it -v "$DIR/tmp:/home/manatee" -p 7080:80 gs-manatee
