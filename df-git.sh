#!/bin/bash

function print_usage() {
    echo "Usage: $0 <command> [<arguments>]"
    echo
    echo "Commands with custom implementations:"
    echo "  clone <repo-location>       Clones a remote repository"
    echo "  commit <commit-message>     Adds and commits the current changes"
    echo "  force-state                 Overwrites dwarf fortress save files with"
    echo "                                  repository state"
    echo "  get-binary-path             Returns the configured binary path (see setup)"
    echo "  get-install-path            Returns the configured install path (see setup)"
    echo "  help                        Prints this help screen"
    echo "  pull                        Updates the repository with remote changes"
    echo "  push                        Uploads changes to the remote repository"
    echo "  setup [...]                 See configuration commands below."
    echo "  upgrade-config              Re-creates the dwarf fortress directory and"
    echo "                                  re-installs save files.  WARNING: this"
    echo "                                  will only work in Arch Linux!"
    echo
    echo "Command for configuring df-git:"
    echo "  setup                       When used without arguments, prints configuration."
    echo "  setup install <path>        Configure Dwarf Fortress installation directory"
    echo "                                  This will be stored in ~/.df-git-install-path"
    echo "  setup binary <path>         Configure Dwarf Fortress binary location."
    echo "                                  This will be stored in ~/.df-git-binary-path"
    echo "  setup clear                 Removes df-git configuration files (but not"
    echo "                                  ~/.df-git/)."
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

# Determine installation directory
DF_BINARY_PATH_FILE="${HOME}/.df-git-binary-path"
DF_INSTALL_PATH_FILE="${HOME}/.df-git-install-path"
function setup_binary_path() {
    path="$1"
    if [[ ! -f "$path" ]]; then
        echo "ERROR: $path is not a file."
    else
        if [[ -x "$path" ]]; then
            echo "$path" > $DF_BINARY_PATH_FILE
            echo "Binary path set to $path."
        else
            echo "$path is not an executable file."
        fi
    fi
}
function setup_install_path() {
    path="$1"
    if [[ ! -d "$path" ]]; then
        echo "ERROR: $path is not a directory."
    else
        save_path="$path/data/save/"
        if [[ ! -d "$save_path" ]]; then
            echo "WARNING: Could not find $save_path."
        else
            echo "$path" > $DF_INSTALL_PATH_FILE
            echo "Install path set to $path."
            default_binary="$path/df"
            if [[ -f "$default_binary" && -x "$default_binary" ]]; then
                setup_binary_path $default_binary
            fi
        fi
    fi
}
# check for install
if [[ -e $DF_INSTALL_PATH_FILE ]]; then
    DF_DIR=$(cat $DF_INSTALL_PATH_FILE)
else
    ARCH_INSTALL="${HOME}/.dwarffortress/"
    if [[ -d $ARCH_INSTALL ]]; then
        echo "Found $ARCH_INSTALL, configuring install path..."
        setup_install_path "$ARCH_INSTALL"
        DF_DIR="$ARCH_INSTALL"
    else
        echo "Could not find Dwarf Fortress installation path."
        echo "Please configure binary location using:"
        echo "  $0 setup install <df-install-path>"
        exit 1
    fi
fi
# check for binary
if [[ -e $DF_BINARY_PATH_FILE ]]; then
    DF_BIN=$(cat $DF_BINARY_PATH_FILE)
else
    ARCH_BIN="/usr/bin/dwarffortress"
    if [[ -f $ARCH_BIN && -x $ARCH_BIN ]]; then
        echo "Found $ARCH_BIN, configuring binary path..."
        setup_binary_path $ARCH_BIN
        DF_BIN="$ARCH_BIN"
    else
        echo "Could not find Dwarf Fortress binary."
        echo "Please configure binary location using:"
        echo "  $0 setup binary <df-binary-path>"
        exit 1
    fi
fi

##
## Variables, aliases, and helper functions
##
DF_GIT_DIR_NAME=".df-git"
DF_GIT_DIR="${HOME}/${DF_GIT_DIR_NAME}/"
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
function print_df_git_config() {
    echo "Install path: $DF_DIR"
    echo "Binary path:  $DF_BIN"
}
function remove_df_git_config_files() {
    rm -v "$DF_INSTALL_PATH_FILE"
    rm -v "$DF_BINARY_PATH_FILE"
}
function copy_save_files() {
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
    copy_save_files "${DF_GIT_DIR}" "${DF_DIR}"
}
function update_df_git_files() {
    echo "Updating df-git files..."
    copy_save_files "${DF_DIR}" "${DF_GIT_DIR}"
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
"get-binary-path")
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 $cmd"
        exit 1
    fi
    echo "$DF_BIN"
    ;;
"get-install-path")
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 $cmd"
        exit 1
    fi
    echo "$DF_DIR"
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
# SETUP DWARF FORTRESS BINARY LOCATION
"setup")
    setup_cmd="$2"
    if [[ -z "$2" ]]; then
        print_df_git_config
    else
        case "$setup_cmd" in
        # setup install path
        "install")
            if [[ $# -ne 3 ]]; then
                echo "Usage $0 $cmd $setup_cmd <df-install-path>"
                exit 1
            fi
            install_path="$3"
            echo "Configuring install path ${install_path}..."
            setup_install_path "$install_path"
            ;;
        # setup binary path
        "binary")
            if [[ $# -ne 3 ]]; then
                echo "Usage $0 $cmd $setup_cmd <df-binary-path>"
                exit 1
            fi
            binary_path="$3"
            echo "Configuating binary path ${binary_path}..."
            setup_binary_path "$binary_path"
            ;;
        # remove existing configuration
        "clear")
            if [[ $# -ne 2 ]]; then
                echo "Usage $0 $cmd $setup_cmd"
                exit 1
            fi
            remove_df_git_config_files
            ;;
        *)
            echo "Unrecognized setup command: $setup_cmd"
            print_usage
            exit 1
            ;;
        esac
    fi
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
    install_df_git_files
    ;;
*)
    echo "Unrecognized command \"$cmd\"."
    print_usage
    exit 1
    ;;
esac

