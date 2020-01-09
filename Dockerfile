FROM consul:1.6.2

ARG gem_file

RUN apk add --no-cache jq build-base libc-dev linux-headers postgresql-dev libxml2-dev libxslt-dev ruby ruby-dev ruby-rdoc ruby-irb git openssh-client

COPY ./docker-entrypoint.sh /
COPY pkg/$gem_file /consul_kv_backup/

RUN cd /consul_kv_backup ; \
    gem install $gem_file

ENTRYPOINT ["/docker-entrypoint.sh"]
