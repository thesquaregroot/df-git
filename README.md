df-git
======

`df-git` maintains and synchronizes your Dwarf Fortress save files by keeping
track of changes in a git repository.  Two scripts are provided to accomplish
this `df-git.sh` and `df-start.sh`.

`df-git.sh` works in a similar fashion to git
itself but always acts on the directory `~/.df-git/`, where copies of your Dwarf
Fortress files will be kept.  `df-start.sh` however provides a wrapper around
`df-git.sh` and transparently manages the git repository before and after
starting Dwarf Fortress itself.

In this way, once you've set up `df-git` you should only need to call
`df-start.sh` whenever you want to play Dwarf Fortress and the rest should
happen automatically.

Dependencies
------------

You'll need the following to run df-git:

- `Dwarf Fortress`
  - This, so far, is only tested on my Arch Linux system with `multilib/dwarffortress`.
- `git`
- `bash` (or potentially some other shell)

Installation
------------

Unpack the scripts into any directory and add it to your PATH.

For bash you will likely want to add something like the following to your
bashrc:

```
export PATH="$PATH:/path/to/df-git/"
```

Using df-git
------------

The first time you use `df-git`, it will attempt to find your Dwarf Fortress
files.  If you have installed it manually it will likely print an error telling
you to configure it, which you can do with the following command:

    $ df-git.sh setup install /path/to/df-files

This should automatically locate the default `df` script.  If it does not, or if
you want to use a custom script, you can you the following command to set it up:

    $ df-git.sh setup binary /path/to/start-script

Once `df-git` knows the install and binary locations, you will want to create a
remote repository (preferably one you can access from anywhere).  Once this is
created you can clone it using:

    $ df-git.sh clone <repo-location>

This will clone the repository into the directory `~/.df-git/`, removing it if
it is already present.

If you already have a fortress (or many) locally, you may want to run the
following:

```
$ df-git.sh commit
$ df-git.sh push
```

This should add, commit, and push your changes back to the repository.

If you do not (or after you have completed the above), you should be able to
run `df-start.sh` and begin playing Dwarf Fortress.  Once you save and exit
Dwarf Fortress, your new (or updated) save files will automatically be added,
committed, and pushed to the repository.  When you start Dwarf Fortress again
using `df-start.sh` it will check for any changes to repository and download
them prior to starting Dwarf Fortress.

If you have multiple computers, setting up `df-git` and using `df-start.sh` to
run Dwarf Fortress every time will ensure that you always have the most recent
version of your fortress.

***upgrade-config (Arch Linux only)***

The `upgrade-config` command automates the process for restarting configuration
after an upgrade to Dwarf Fortress.  The .dwarffortress directory is deleted
and Dwarf Fortress is started briefly, allowing the new version's
configuration files to be copied into place by the Arch Linux start script.
Any save files currently being tracked by `df-git` will then be copied into
place.

Assuming `df-git` is already set up and in sync, the following commands should
start up Dwarf Fortress with new configuration and your old save files:

```
$ df-git.sh upgrade-config
$ df-start.sh
```

That said, this is heavily dependent on Arch-Linux-specific functionality
and on other systems may only be useful as an opportunity for real-world
[Fun](http://dwarffortresswiki.org/index.php/DF2014:Fun).

***force-state***

The `force-state` command provides a way to take the current state of the
repository and overwrite your Dwarf Fortress save files with it.  This is
especially useful if you have interacted with the repository outside of df-git
(e.g. with git itself) or if there has otherwise been corruption of your Dwarf
Fortress save directory.

