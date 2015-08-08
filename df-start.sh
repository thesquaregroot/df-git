#!/bin/bash

DF_GIT_INSTALL_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DF_GIT_SH="$DF_GIT_INSTALL_DIR/df-git.sh"

# get newest changes
$DF_GIT_SH pull
if [[ $? -ne 0 ]]; then
    exit 1
fi

# run dwarf fortress
$($DF_GIT_SH get-binary-path)

# auto-commit
$DF_GIT_SH commit "[$(date +"%Y-%m-%d %H:%M:%S")] auto-commit"
if [[ $? -ne 0 ]]; then
    exit 1
fi
# update repo
$DF_GIT_SH push

