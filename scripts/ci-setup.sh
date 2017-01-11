#!/bin/sh

set -e

# Check for asdf and install in case it doesn't exist
if ! asdf | grep version
then
    git clone https://github.com/HashNuke/asdf.git ~/.asdf
fi

export ERLANG_EXTRA_CONFIGURE_OPTIONS="--without-javac"

# Add Erlang and Elixir plugins
asdf plugin-add erlang https://github.com/HashNuke/asdf-erlang.git
asdf plugin-add elixir https://github.com/HashNuke/asdf-elixir.git
asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git

# Install plugins based on .tool-versions file
asdf install

# Install mix deps
mix local.hex --force
mix local.rebar --force
