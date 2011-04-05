I wrote a mercurial interface for mercurial commands I use most often.
Enjoy.

This is work in process. Its copy paste of vim-addon-git

commands:
    see plugin/vim_addon_mercurial.vim

or
    :*HG<c-d>

:StatusHG
will open a special buffer which maps some very common actions.
See vim_addon_mercurial#Names() in autoload/vim_addon_mercurial.vim

press gf on a/path/file.ext or 34efc237 (git hash)
to open the file or a view of the commit. (see vim-addon-views)
On all views you can use :e! to refresh them

Tested on Linux only

Are you still missing documentation? Tell me.


INSTALLATION:


* way 1: (recommended)
  call scriptmanager#Activate(["vim-addon-git"])
  Enjoy!


* way2 : (manual)
  see vim-addon-git-addon-info.txt. You have to get all dependencies
  as well


TODO:



* make gf (and BBlameHG!) aware of current commit if
  used on views. Currently always HEAD is used


== alternatives
http://www.vim.org/scripts/script.php?script_id=90 (vcscommand.vim)
