#!/bin/sh
set -ea

if [ "$*" = "strapi" ]; then

  if [ ! -f "package.json" ]; then

    DATABASE_CLIENT=${DATABASE_CLIENT:-sqlite}
    PACKAGE_MANAGER=${PACKAGE_MANAGER:-npm}

    # create-strapi writes an empty DATABASE_FILENAME otherwise, which breaks sqlite
    if [ "$DATABASE_CLIENT" = "sqlite" ]; then
      DATABASE_FILENAME=${DATABASE_FILENAME:-.tmp/data.db}
    fi

    EXTRA_ARGS=${EXTRA_ARGS}

    STRAPI_VERSION=$(strapi version)

    echo "Using strapi $STRAPI_VERSION"
    echo "No project found at /srv/app. Creating a new strapi project ..."

    # Build the argument list positionally so values are never word-split or
    # glob-expanded. Only pass database options that are actually set.
    # The real DATABASE_PASSWORD is never put on the command line (it would be
    # visible in the process list). create-strapi requires the option, so a
    # placeholder is passed and replaced in .env afterwards.
    set -- --no-run --non-interactive --skip-cloud --no-example --no-git-init --install \
      "--use-$PACKAGE_MANAGER" "--dbclient=$DATABASE_CLIENT"
    [ -n "$DATABASE_HOST" ] && set -- "$@" "--dbhost=$DATABASE_HOST"
    [ -n "$DATABASE_PORT" ] && set -- "$@" "--dbport=$DATABASE_PORT"
    [ -n "$DATABASE_NAME" ] && set -- "$@" "--dbname=$DATABASE_NAME"
    [ -n "$DATABASE_USERNAME" ] && set -- "$@" "--dbusername=$DATABASE_USERNAME"
    [ -n "$DATABASE_PASSWORD" ] && set -- "$@" "--dbpassword=__DATABASE_PASSWORD_FROM_ENV__"
    [ -n "$DATABASE_SSL" ] && set -- "$@" "--dbssl=$DATABASE_SSL"
    [ -n "$DATABASE_FILENAME" ] && set -- "$@" "--dbfile=$DATABASE_FILENAME"

    # `strapi new` was removed in Strapi v5, projects are created with create-strapi.
    # EXTRA_ARGS may hold several flags, so it is split on whitespace but not globbed.
    set -f
    DOCKER=true npx -y "create-strapi@$STRAPI_VERSION" . "$@" $EXTRA_ARGS
    set +f

    if [ -n "$DATABASE_PASSWORD" ] && [ -f .env ]; then
      # Read the secret from the environment inside awk, not from argv
      awk 'index($0, "DATABASE_PASSWORD=") == 1 { print "DATABASE_PASSWORD=" ENVIRON["DATABASE_PASSWORD"]; next } { print }' .env > .env.tmp
      mv .env.tmp .env
    fi

  elif [ ! -d "node_modules" ] || [ ! "$(ls -qAL node_modules 2>/dev/null)" ]; then

    if [ -f "yarn.lock" ]; then

      echo "Node modules not installed. Installing using yarn ..."
      yarn install --prod --silent

    else

      echo "Node modules not installed. Installing using npm ..."
      npm install --omit=dev --silent

    fi

  fi

  if [ "$NODE_ENV" = "production" ]; then
    STRAPI_MODE="start"
  elif [ "$NODE_ENV" = "development" ]; then
    STRAPI_MODE="develop"
  fi

  # Prefer the project's own strapi so its dependencies (e.g. DB drivers) are resolved
  STRAPI_BIN="./node_modules/.bin/strapi"
  [ -x "$STRAPI_BIN" ] || STRAPI_BIN="strapi"

  if [ -z "$STRAPI_MODE" ]; then
    echo "WARNING: NODE_ENV is '${NODE_ENV:-<unset>}', starting in DEVELOPMENT mode. Set NODE_ENV=production for production deployments."
  fi

  echo "Starting your app (with ${STRAPI_MODE:-develop})..."
  exec "$STRAPI_BIN" "${STRAPI_MODE:-develop}"

else
  exec "$@"
fi
