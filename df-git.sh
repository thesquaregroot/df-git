#!/bin/bash

function print_usage() {
    echo "Usage: "
    echo "  $0 help"
    echo "  $0 clone <repo-location>"
    echo "  $0 pull"
    echo "  $0 commit <commit-message>"
    echo "  $0 push"
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
alias cp="cp -v"
alias mv="mv -v"
alias rm="rm -Iv"
function remove_df_git_dir() {
    if [[ -e "${DF_GIT_DIR}" ]]; then
        rm -rf "${DF_GIT_DIR}"
    fi
}
function copy_files() {
    src_dir="$1"
    dest_dir="$2"
    # remove destination
    rm -rf "${dest_dir}/data/save/"
    # create directories
    mkdir -p "${dest_dir}/data/"
    # copy files
    cp -r "${src_dir}/data/save/" "${dest_dir}/data/"
}
function install_df_git_files() {
    copy_files "${DF_GIT_DIR}" "${DF_DIR}"
}
function update_df_git_files() {
    copy_files "${DF_DIR}" "${DF_GIT_DIR}"
}
function confirm_update() {
    read -p "Remote changes found, are you sure you want to overwrite your local Dwarf Fortress save files? [y/N] " response
    if [[ "$response" == "y" ]]; then
        return 0
    fi
    return 1
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
# PULL UPDATES FROM CURRENT BRANCH
"pull")
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 $cmd"
        exit 1
    fi
    cd ${DF_GIT_DIR}
    git fetch origin
    changes="$(git log HEAD..origin/master --oneline)"
    if [[ -n "$changes" ]] && [[ confirm_update ]]; then
        # changes found, update files
        git pull
        # setup updated files
        install_df_git_files
    fi
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
# PUSH BRANCH TO REPOSITORY
"push")
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 $cmd"
        exit 1
    fi
    cd "${DF_GIT_DIR}"
    git push
    ;;
*)
    echo "Unrecognized command \"$cmd\"."
    print_usage
    exit 1
    ;;
esac

