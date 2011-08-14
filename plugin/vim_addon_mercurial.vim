fun! EnableHGCommands()

  " I chose to let all command!s end by HG intentionally
  " That's faster to type
  " All command!s which act on a buffer only start with B
  command! -nargs=0 BBlameHG call views#View("exec",["hg","blame",expand("%")])
  command! -nargs=0 DiffHG call views#View("exec", ["hg","diff"])
  " checkout current file (throw away your changes). Then reload file
  " I should be using e! when ! is given only (TODO) ?
  " command! -nargs=* BCheckoutHG  exec '!git checkout '.expand('%')." "| e!
  " command! -nargs=0 BDiffHG update| call views#View("exec",["hg","diff",expand("%")])
  " command! -nargs=0 BDiffSplitHG call vim_addon_git#BDiffSplitHG(<f-args>)
  " command! -nargs=0 DiffCachedHG call views#View("exec",["git","diff","--cached"])
  " command! -nargs=0 BDiffCachedHG update | call views#View("exec",["git","diff","--cached",expand("%")])
  " command! -nargs=0 BAddHG update|!git add %
  " command! -nargs=0 BAddHGPatch update|!git add --patch %
  " command! -nargs=0 HGInit !git init
  "
  "
  command! -nargs=* LogHG    call vim_addon_mercurial#HGLog(<f-args>)
  command! -nargs=* FilesHG  call vim_addon_mercurial#FilesHG(<f-args>)
  command! -nargs=* HeadsDot call views#View("exec",["hg","heads","."])
  command! -nargs=* Heads    call views#View("exec",["hg","heads"])


  " command! -nargs=0 BCommitHG update| call vim_addon_git#BCommit()
  " command! -nargs=0 CommitHG call vim_addon_git#Commit()
  " command! -nargs=0 StatusHG call vim_addon_git#StatusAndActions()
  " command! -nargs=0 LogThisFileHG call views#View("exec",["git","log","--",expand("%")])

  " used by tmp buffers
  augroup vim_addon_mercurial
  augroup end

  call on_thing_handler#AddOnThingHandler('g',funcref#Function("return vim_addon_mercurial#HGGotoLocations()"))

endf

if isdirectory('.hg')
  call EnableHGCommands()
endif

command! -nargs=0 EnableHGCommands call EnableHGCommands()
