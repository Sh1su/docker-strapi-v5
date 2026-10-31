# BASE
ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-alpine AS base-alpine
EXPOSE 1337

FROM base-alpine

ARG STRAPI_VERSION=latest

# Upgrade bundled npm (ships with vulnerable deps) to the latest 11.x
# and patch its bundled undici to the latest 6.x (semver-compatible for node-gyp)
ARG NPM_VERSION=11

# Force patched versions of vulnerable transitive deps of @strapi/strapi
ARG RESOLUTIONS='{"esbuild":"^0.28.2","webpack-dev-middleware":"^7.4.6"}'

# Pull OS security fixes not yet in the base image
RUN apk upgrade --no-cache

RUN npm install -g npm@${NPM_VERSION} \
  && cd /usr/local/lib/node_modules/npm/node_modules \
  && rm -rf undici && mkdir undici \
  && npm pack undici@6 --silent --pack-destination /tmp \
  && tar -xzf /tmp/undici-*.tgz --strip-components=1 -C undici \
  && rm -f /tmp/undici-*.tgz \
  && cd / \
  && npm cache clean --force \
  && mkdir -p "$(yarn global dir)" \
  && printf '{"resolutions":%s}\n' "${RESOLUTIONS}" > "$(yarn global dir)/package.json" \
  && yarn global add @strapi/strapi@${STRAPI_VERSION} \
  && yarn cache clean


RUN mkdir -p /srv/app && chown 1000:1000 -R /srv/app

WORKDIR /srv/app

VOLUME /srv/app

COPY docker-entrypoint.sh /usr/local/bin/

RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["strapi"]
