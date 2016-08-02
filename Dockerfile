FROM alpine:3.4
RUN set -x && apk --no-cache add alpine-sdk coreutils tini openssl-dev perl-dev pcre-dev\
    automake autoconf libtool python-dev boost-dev cmake\
  && echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
  && mkdir /packages
COPY /abuilder /bin/
COPY /docker-entrypoint.sh /
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]
CMD ["abuilder", "-r"]
WORKDIR /home/builder/package
ENV RSA_PRIVATE_KEY_NAME ssh.rsa
ENV PACKAGER_PRIVKEY /home/builder/${RSA_PRIVATE_KEY_NAME}
ENV REPODEST /packages
ENV RUID 1000
ENV RGID 1000
