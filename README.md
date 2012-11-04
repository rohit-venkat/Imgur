About
-----

This is a 100% Bash script used to download imgur albums while making sure that
the order of the pictures is retained. The script now allows for multi-album
support.

    usage: `bash imgur.bash [-cpsm] [file] URL`
    This script is used solely to download imgur albums.

    OPTIONS:
      -h        Show this message.
      -m <File> Download multiple albums found in <File>.
      -c        Clean nonalphanumeric characters from the album's name.
      -p        Preserve imgur's naming. (Warning! This will not retain order.)
      -s        Silent mode.

Thanks to everyone in this thread who helped me out.  
http://redd.it/webn1  
Special Thanks goes to Reddit users:  
  /u/Ihasn and /u/Skaarj for help on the base code during the early stages.  
  /u/invisiblescars for the idea and original code for a kde4 context menu.

Compatible with Linux, Unix, and OS X  
Cygwin remains untested.

Usage
-----

The script was created so that all that you need to do is copy+paste the address
bar link into the terminal.

    chmod +x imgur.bash
    ./imgur.bash -h

If you want to use the multiple-files feature then you will need to have a plain
text file with imgur album URLs seperated by new lines

`./imgur.bash -m Imgur-Albums-List.txt`

Special note: If you do use the -m flag it must be the last option.  
E.X. `./imgur.bash -scm Imgur-Albums-List.txt`

Installation
------------

This is only if you want to reference the script without having it in the
directory you want the imgur album.

    sudo mkdir -p /usr/local/bin 
    sudo chown `whoami` /usr/local/bin
    cd /usr/local/bin
    curl https://raw.github.com/manabutameni/Imgur/master/imgur.bash -o imgur
    chmod +x imgur
    PATH=$PATH:/usr/local/bin # only if you haven't done this already
    export PATH

To use:
`imgur imgur.com/a/XXXXX`

KDE
---

There is a file named imgur.desktop with you in mind. Simply copy to your local
`kde4-config --path services` location and make sure it's executable. `chmod +x
imgur.desktop`.

To use: Simply copy the url of an imgur album into your clipboard and right
click on an empty area in dolphin. Under actions you should see "Imgur Album
DL".

Please note, this will only work if you have installed the script in the
INSTALLATION part of this readme.

Extra
-----

I wanted to write a script that would ensure that each image is in the proper
order which you can't do by clicking the "Download" button on imgur albums.
Clicking the "Download" link on imgur albums does not save the order. [Example album](http://imgur.com/a/NhmjT/all#0)

This script was made with the intent to be used without any requirements and
will work on a fresh install of a minimal system. As long as you have /bin/bash
and the mktemp and curl commands this script should work out of the box.