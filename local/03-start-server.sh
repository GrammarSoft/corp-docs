#/bin/bash
DIR="$(cd $(dirname $0);pwd)"

echo "Starting local server at http://localhost:7080/"
echo "Open it in a browser to test that the corpus is working as expected. Server can be closed with Ctrl-C"
echo "Only the locally encoded corpus exists. The rest are skeleton files."
echo ""

cd "$DIR"
sudo docker run -it --rm --name gs-manatee -v "$DIR/tmp:/home/manatee" -p 7080:80 gs-manatee
