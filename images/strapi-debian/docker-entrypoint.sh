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

    # Only pass database options that are actually set
    DB_ARGS="--dbclient=$DATABASE_CLIENT"
    [ -n "$DATABASE_HOST" ] && DB_ARGS="$DB_ARGS --dbhost=$DATABASE_HOST"
    [ -n "$DATABASE_PORT" ] && DB_ARGS="$DB_ARGS --dbport=$DATABASE_PORT"
    [ -n "$DATABASE_NAME" ] && DB_ARGS="$DB_ARGS --dbname=$DATABASE_NAME"
    [ -n "$DATABASE_USERNAME" ] && DB_ARGS="$DB_ARGS --dbusername=$DATABASE_USERNAME"
    [ -n "$DATABASE_PASSWORD" ] && DB_ARGS="$DB_ARGS --dbpassword=$DATABASE_PASSWORD"
    [ -n "$DATABASE_SSL" ] && DB_ARGS="$DB_ARGS --dbssl=$DATABASE_SSL"
    [ -n "$DATABASE_FILENAME" ] && DB_ARGS="$DB_ARGS --dbfile=$DATABASE_FILENAME"

    echo "Using strapi $STRAPI_VERSION"
    echo "No project found at /srv/app. Creating a new strapi project ..."

    # `strapi new` was removed in Strapi v5, projects are created with create-strapi
    DOCKER=true npx -y "create-strapi@$STRAPI_VERSION" . \
      --no-run \
      --non-interactive \
      --skip-cloud \
      --no-example \
      --no-git-init \
      --install \
      "--use-$PACKAGE_MANAGER" \
      $DB_ARGS \
      $EXTRA_ARGS

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

  echo "Starting your app (with ${STRAPI_MODE:-develop})..."
  exec "$STRAPI_BIN" "${STRAPI_MODE:-develop}"

else
  exec "$@"
fi
