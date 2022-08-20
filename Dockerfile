FROM ghcr.io/linuxserver/baseimage-alpine-nginx:arm32v7-3.15

# set version label
ARG BUILD_DATE
ARG VERSION
ARG COPS_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chbmb"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --upgrade --virtual=build-dependencies \
    curl \
    tar && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache --upgrade \
    php8-ctype \
    php8-dom \
    php8-gd \
    php8-intl \
    php8-mbstring \
    php8-opcache \
    php8-openssl \
    php8-phar \
    php8-pdo_sqlite \
    php8-zip \
    php8-zlib && \
  echo "**** install cops ****" && \
  curl \
    -sS https://getcomposer.org/installer \
    | php -- --install-dir=/usr/bin --filename=composer --version=1.10.26 && \
  composer \
    global require "fxp/composer-asset-plugin:~1.1" && \
  if [ -z ${COPS_RELEASE+x} ]; then \
    COPS_RELEASE=$(curl -sX GET "https://api.github.com/repos/seblucas/cops/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /tmp/cops.tar.gz -L \
    "https://github.com/seblucas/cops/archive/${COPS_RELEASE}.tar.gz" && \
  mkdir -p \
    /app/www/public && \
  tar xf /tmp/cops.tar.gz -C \
    /app/www/public --strip-components=1 && \
  cd /app/www/public && \
  composer \
    install --no-dev --optimize-autoloader && \
  sed -i 's|^[[:space:]]*return[[:space:]]@create_function[[:space:]]'\(''\''\$it'\'',[[:space:]]\$func'\)';|        return function \(\$it\) use \(\$func\) \{\n            return eval\(\$func\);\n            \};|' vendor/seblucas/dot-php/doT.php && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.composer \
    /tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 80 443
