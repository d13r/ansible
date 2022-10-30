#!/bin/bash
set -o nounset -o pipefail -o errexit

# Based on https://djm.me/cfg, but quiet and non-interactive
cd $HOME

git init -q
git remote add origin "https://github.com/davejamesmiller/dotfiles.git"
git remote set-url --push origin "git@github.com:davejamesmiller/dotfiles.git"
git fetch -q --depth=1 origin

rm -f .bashrc .bash_profile .sudo_as_admin_successful

git checkout origin/main -b main

.dotfiles/post-install --unattended
