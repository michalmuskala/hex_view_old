#!/bin/sh

set -e

NAME="hex_view"
VERSION="0.0.1"
export MIX_ENV=prod

echo "Compiling assets"
(cd assets && npm run deploy)
# DEBUG
ls -al assets/vendor
mix phoenix.digest

echo "Building release"
mix release --env=prod

echo "Uploading release"
scp "_build/$MIX_ENV/rel/$NAME/releases/$VERSION/$NAME.deb" \
    "$DEPLOYER@$SERVER":"$NAME.deb"
ssh "$DEPLOYER@$SERVER" 'sudo dpkg -i '"$NAME"'.deb'
