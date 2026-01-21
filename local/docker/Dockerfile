FROM amd64/ubuntu:24.04
ENV PYTHON_VERSION=3.12

LABEL vendor="GrammarSoft ApS" \
	maintainer="Tino Didriksen <mail@tinodidriksen.com>"

ENV LANG=C.UTF-8 \
	LC_ALL=C.UTF-8 \
	DEBIAN_FRONTEND=noninteractive \
	DEBCONF_NONINTERACTIVE_SEEN=true \
	PERL_UNICODE=SDA \
	PYTHONPATH="/usr/local/manatee/lib/python${PYTHON_VERSION}/site-packages" \
	PYTHONHASHSEED=42 \
	MANATEE_REGISTRY="/home/manatee/storage/registry/" \
	PATH="${PATH}:/usr/local/manatee/bin"

RUN apt-get -qy update && apt-get install -qfy --no-install-recommends apt-utils
RUN apt-get -qy update && apt-get -qfy dist-upgrade
RUN apt-get -qy update && apt-get install -qfy --no-install-recommends wget ca-certificates php-sqlite3 php-mbstring php-cli php-intl sqlite3 coreutils icu-devtools python3 autoconf automake build-essential libtool autoconf-archive bison libpcre3 libpcre3-dev python3-dev python3-gensim swig zstd apache2 libapache2-mod-php

RUN wget https://corpora.fi.muni.cz/noske/current/src/manatee-open-2.225.8.tar.gz \
	&& tar -zxvf manatee-open-2.225.8.tar.gz \
	&& cd manatee-open-2.225.8 \
	&& autoreconf -fvi \
	&& ./configure --with-pcre --prefix=/usr/local/manatee \
	&& make -j8 \
	&& make install

RUN apt-get remove -qfy wget apt-utils autoconf automake build-essential libtool autoconf-archive bison python3-dev swig
RUN apt-get autoremove -qfy
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd -o --gid $USER_GID manatee && useradd -o --uid $USER_UID --no-log-init -m -g manatee manatee

RUN echo 'export APACHE_RUN_USER=manatee' >> /etc/apache2/envvars && \
	echo 'export APACHE_RUN_GROUP=manatee' >> /etc/apache2/envvars && \
	a2dismod -f negotiation && \
	a2enmod vhost_alias && \
	a2enmod rewrite && \
	a2enmod access_compat

COPY apache.conf /etc/apache2/sites-enabled/000-default.conf

EXPOSE 80
ENTRYPOINT ["/usr/sbin/apachectl", "-DFOREGROUND"]
