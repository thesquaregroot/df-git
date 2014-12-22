#!/bin/bash

# get newest changes
df-git.sh pull
if [[ $? -ne 0 ]]; then
    exit 1
fi

# run dwarf fortress
dwarffortress

# auto-commit
df-git.sh commit "[$(date +"%Y-%m-%d %H:%M:%S")] auto-commit"
if [[ $? -ne 0 ]]; then
    exit 1
fi
# update repo
df-git.sh push

