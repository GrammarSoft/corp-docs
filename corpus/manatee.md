# Manatee

## Build Manatee
```
# Ideally build in a container or chroot and then export the result
apt-get install autoconf automake build-essential libtool autoconf-archive bison libpcre2-dev python3-dev swig
wget https://corpora.fi.muni.cz/noske/current/src/manatee-open-2.238.7.tar.gz
tar -zxvf manatee-open-2.238.7.tar.gz
cd manatee-open-2.238.7.tar.gz
autoreconf -fvi
./configure --with-pcre2 --prefix=/usr/local/manatee
make -j8
make install
```

## (alternatively) Docker image creation
```
docker run -it --rm --name manatee --hostname manatee -e LANG=en_US.UTF-8 -e LC_ALL=en_US.UTF-8 -v /home:/home -v /media:/media amd64/centos:7 /bin/bash

# Inside container
yum install epel-release
yum check-update
yum update
yum install python3 m4 parallel libtool-ltdl zstd
# At minimum:
# https://corpora.fi.muni.cz/noske/current/centos7/manatee-open/manatee-open-2.223.6-1.el7.x86_64.rpm
# https://corpora.fi.muni.cz/noske/current/centos7/manatee-open/manatee-open-python3-2.223.6-1.el7.x86_64.rpm
rpm -i /media/data/manatee*rpm

# In another shell
docker commit manatee manatee
echo 'FROM manatee' | docker build --squash -t manatee -
docker system prune -f

docker run -it --rm --name manatee --hostname manatee -e LANG=en_US.UTF-8 -e LC_ALL=en_US.UTF-8 -v /home:/home -v /media:/media manatee /bin/bash
```

# Encoding
* Copy `manatee.registry.txt` to a file named something like `corpus_name.reg` and edit it with the correct `NAME`, `PATH`, and adjust the `STRUCTURE` to the attributes present in the data.

```
export PYTHONPATH=/usr/local/manatee/lib/python3.10/site-packages "PATH=$PATH:/usr/local/manatee/bin"
zstdcat corpus.zst | encodevert -c /home/manatee/storage/registry/corpus_name.reg
```

* This will likely throw some errors at the end about not being able to generate the dynamic attributes, but those will be generated later so it's not a problem.

# Query
* Test that the corpus works by running a cmdline query.

```
export PYTHONPATH=/usr/local/manatee/lib/python3.10/site-packages "PATH=$PATH:/usr/local/manatee/bin"
corpquery /home/manatee/storage/registry/corpus_name.reg '[lex="musling"]' -a 'word,lex,pos' -s 's.id,s.tweet,s.stamp,s.lstamp'
```

# Upload and adjust
* Upload the corpus folder: `rsync -avzP --inplace corpus_name manatee@corp2.visl.dk:/home/manatee/storage/corpora/`
* Upload the corpus registry: `rsync -avzP --inplace corpus_name.reg manatee@corp2.visl.dk:/home/manatee/storage/registry/corpus_name`

* `ssh -Al manatee corp2.visl.dk` and then:
* Adjust `~/storage/registry/corpus_name` with the server-side `PATH`.
* `export PYTHONPATH=/usr/local/manatee/lib/python3.10/site-packages "PATH=$PATH:/usr/local/manatee/bin"`
* For each dynamic attribute, run `mkdynattr`. E.g., for `word_lc` run `mkdynattr ~/storage/registry/corpus_name word_lc`
* Continue in https://github.com/GrammarSoft/corp-ui/blob/main/README.md
