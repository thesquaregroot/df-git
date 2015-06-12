#!/bin/bash

function print_usage() {
    echo "Usage: $0 <command> [<arguments>]"
    echo
    echo "Commands with custom implementations:"
    echo "  clone <repo-location>       Clones a remote repository"
    echo "  commit <commit-message>     Adds and commits the current changes"
    echo "  force-state                 Overwrites dwarf fortress save files with"
    echo "                                  repository state"
    echo "  help                        Prints this help screen"
    echo "  pull                        Updates the repository with remote changes"
    echo "  push                        Uploads changes to the remote repository"
    echo "  upgrade-config              Re-creates the dwarf fortress directory and"
    echo "                                  re-installs save files"
    echo
    echo "Commands 'forwarded' to git (normal git arguments can be used):"
    echo "  branch"
    echo "  checkout"
    echo "  fetch"
    echo "  log"
    echo "  status"
    echo
}

##
## Simple usage check / help command
##
if [[ $# -eq 0 ]] || [[ "$1" == "help" ]]; then
    print_usage
    exit 1
fi

##
## Variables, aliases, and helper functions
##
DF_DIR_NAME=".dwarffortress"
DF_DIR="${HOME}/${DF_DIR_NAME}/"
DF_GIT_DIR_NAME=".df-git"
DF_GIT_DIR="${HOME}/${DF_GIT_DIR_NAME}/"
DF_BIN="dwarffortress"
alias cp="cp -v"
alias mv="mv -v"
alias rm="rm -Iv"
function remove_df_dir() {
    if [[ -e "${DF_DIR}" ]]; then
        echo "Removing ${DF_DIR}..."
        rm -rf "${DF_DIR}"
    fi
}
function remove_df_git_dir() {
    if [[ -e "${DF_GIT_DIR}" ]]; then
        echo "Removing ${DF_GIT_DIR}..."
        rm -rf "${DF_GIT_DIR}"
    fi
}
function copy_files() {
    src_dir="$1"
    dest_dir="$2"
    # determine if rysnc is installed
    if hash rsync 2>/dev/null; then
        # sync files
        rsync -rtq -delete "${src_dir}" "${dest_dir}" --exclude ".git"
    else
        # remove destination
        rm -rf "${dest_dir}/data/save/"
        # create directories
        mkdir -p "${dest_dir}/data/"
        # copy files
        cp -r "${src_dir}/data/save/" "${dest_dir}/data/"
    fi
}
function install_df_git_files() {
    echo "Installing df-git files..."
    copy_files "${DF_GIT_DIR}" "${DF_DIR}"
}
function update_df_git_files() {
    echo "Updating df-git files..."
    copy_files "${DF_DIR}" "${DF_GIT_DIR}"
}
function confirm_update() {
    read -p "Remote changes found, are you sure you want to overwrite your local Dwarf Fortress save files? [y/N] " response
    if [[ "$response" == "y" ]]; then
        return 0
    fi
    return 1
}
function get_current_branch() {
    cd ${DF_GIT_DIR}
    git symbolic-ref --short HEAD # e.g. 'master'
}

cmd="$1"
##
## Interpret and execute command
##
case "$cmd" in
# CLONE REPOSITORY
"clone")
    if [[ $# -ne 2 ]]; then
        echo "Usage: $0 $cmd <repo-location>"
        exit 1
    fi
    repo="$2"
    remove_df_git_dir
    # clone to home directory
    cd "${HOME}"
    git clone "$repo" "${DF_GIT_DIR_NAME}"
    # init .gitignore
    cd "${DF_GIT_DIR}"
    echo "# ingore all files"   > "${DF_GIT_DIR}/.gitignore"
    echo "*"                   >> "${DF_GIT_DIR}/.gitignore"
    echo "!.gitignore"         >> "${DF_GIT_DIR}/.gitignore"
    echo ""                    >> "${DF_GIT_DIR}/.gitignore"
    echo "# except data/save"  >> "${DF_GIT_DIR}/.gitignore"
    echo "!data/"              >> "${DF_GIT_DIR}/.gitignore"
    echo "data/*"              >> "${DF_GIT_DIR}/.gitignore"
    echo "!data/save/"         >> "${DF_GIT_DIR}/.gitignore"
    echo "!data/save/**/*"     >> "${DF_GIT_DIR}/.gitignore"
    ;;
# COMMIT LATEST CHANGES
"commit")
    if [[ $# -ne 2 ]]; then
        echo "Usage: $0 $cmd <commit-message>"
        exit 1
    fi
    msg="$2"
    cd "${DF_GIT_DIR}"
    # get any changes
    update_df_git_files
    # add updates
    git add -A
    # commit
    git commit -m "$msg"
    ;;
# FORCES REPOSITORY STATE TO CONFIGURATION
"force-state")
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 $cmd"
        exit 1
    fi
    install_df_git_files
    ;;
# PULL UPDATES FROM CURRENT BRANCH
"pull")
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 $cmd"
        exit 1
    fi
    cd "${DF_GIT_DIR}"
    git fetch origin
    current_branch=$(get_current_branch)
    changes="$(git log HEAD..origin/${current_branch} --oneline)"
    if [[ -n "$changes" ]] && [[ confirm_update ]]; then
        # changes found, update files
        git pull origin ${current_branch}
        # setup updated files
        install_df_git_files
    fi
    ;;
# PUSH BRANCH TO REPOSITORY
"push")
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 $cmd"
        exit 1
    fi
    cd "${DF_GIT_DIR}"
    current_branch=$(get_current_branch)
    git push origin ${current_branch}
    ;;
# RECREATE DWARF FORTRESS CONFIGURATION
"upgrade-config")
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 $cmd"
        exit 1
    fi
    # make sure we have the most recent updates
    update_df_git_files
    # remove dwarf fortress directory
    echo "Recreating ${DF_DIR}..."
    remove_df_dir
    # start dwarf fortress long enough to create new config
    timeout -s 9 1s "${DF_BIN}"
    # add save files
    install_df_git_files
    ;;
# FORWARDED COMMANDS
"branch"|"checkout"|"fetch"|"status"|"log")
    # direct forward
    cd "${DF_GIT_DIR}"
    update_df_git_files
    git $@
    ;;
*)
    echo "Unrecognized command \"$cmd\"."
    print_usage
    exit 1
    ;;
esac

