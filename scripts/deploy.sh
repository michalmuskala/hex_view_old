#!/bin/sh

set -e

NAME="hex_view"
VERSION="0.0.1"

export MIX_ENV=prod
(cd assets && npm run deploy)
mix phoenix.digest
mix release --env=prod
scp "_build/$MIX_ENV/rel/$NAME/releases/$VERSION/$NAME.deb" \
    "$DEPLOYER@$SERVER":"$NAME.deb"
ssh "$DEPLOYER@$SERVER" 'sudo dpkg -i '"$NAME"'.deb'
