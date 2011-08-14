" this file is a mess, tidy up
" most code has not been adopted for mercurial usage yet!

" goto feature {{{1
fun! vim_addon_mercurial#HGGotoLocations()
  " only add commit location if the commit exists
  let thing = expand('<cWORD>')
  if thing =~ '^[ab]/'
    " diff file a/foo/bar ? strip a
    if filereadable(thing[2:])
      return [{ 'filename' : thing[2:], 'break' : 1 }]
    endif
    return []
  else
    let list = []
    " hash ?
    try
      let reg_nr = '[0-9]\+'
      let reg_hash = '[0-9a-f]\+'
      if thing =~ '^\%('.reg_nr.'\|'.reg_hash.'\|'.reg_nr.':'.reg_hash.'\)$'
        let hash = thing
        call tovl#runtaskinbackground#System(["hg","log","-r".hash])
        " no failure 
        let list = [ { 'filename' : views#View('exec', ['hg','log','-p','-r', hash], 1), 'break' : 1} ]
      endif
    " catch /.*/
    endtry
    return list
  endif
endf

" StatusHG view {{{1
fun! vim_addon_mercurial#Names()
  return  {
    \ 'a' : 'add'
    \ ,'p' : 'add patched'
    \ ,'U' : 'unstage (git rm --cached)'
    \ ,'r' : 'rm (git rm)'
    \ ,'D' : '!git diff on file under cursor'
    \ ,'c' : ':tabnew | CommitHG'
    \ ,'C' : '"git checkout file'
    \ }
endfun

fun! vim_addon_mercurial#StatusViewAction(action)
  if a:action != 'c'
    let list = matchlist(getline('.'), '^#\s*\%(\(\S*\):\)\?\s*\(\S*\)')
    let status = list[1]
    let file = list[2]
  endif

  if a:action == 'a'
    exec '!git add '.file
  elseif a:action  == 'U'
    exec '!git rm --cached '.file
  elseif a:action  == 'p'
    exec '!git add --patch '.file
  elseif a:action  == 'r'
    exec '!git rm '.file
  elseif a:action  == 'D'
    call views#View('exec',['git', 'diff', file])
  elseif a:action  == 'c'
    tabnew | CommitHG
  elseif a:action  == 'C'
    exec '!git checkout '.file
  endif

endfun

fun! vim_addon_mercurial#StatusOnRead()
  " empty:
  %g!//d
  let lines = ['# >>--> see :Help to read about '.join(keys(vim_addon_mercurial#Names()), ", ") ." mappings"]
                \ + filter(split(vim_addon_mercurial#System(["git", "status"], {"status" : "*"}),"\n"), "v:val !~ '^#\\s*\\%((.*\\)\\?$'")
  call append(0, lines)

  set buftype nowrite
  set filetype=git_status_view
  setlocal syntax=gitcommit
endf

fun! vim_addon_mercurial#StatusAndActions()
  let help = [
    \ '===  file actions ==='
    \ ]
    \ + values(map(copy(vim_addon_mercurial#Names()), 'v:key." = ".v:val'))

  " call search to place the cursor to a more sensible location..
  call s:ScratchCleanAdvanced('git-status-view',
        \ 'call vim_addon_mercurial#StatusOnRead()',
        \ 0,
        \ help)

  call search('# Changed but not updated:','e')


  for i in keys(vim_addon_mercurial#Names())
    exec 'noremap <buffer> '.i.' :call vim_addon_mercurial#StatusViewAction('.string(i).')<cr>'
  endfor
endf

" more command implementations {{{1
fun! vim_addon_mercurial#BDiffSplitHG()
  let proposal = "show HEAD:".expand('%:.')
  let args = split(input("git : ", proposal),'\s\+')
  diffthis
  call views#View("exec",["git"] + args)
  diffthis
  " TODO: if you close the diff window call diffoff 
endf

fun! vim_addon_mercurial#RevisionFromBuf()
  return matchstr(expand('%'),"'-r\\%(', '\\)\\?\\zs[^']*\\ze'")
endf

fun! vim_addon_mercurial#FilesHG()
  if a:0 == 0
    " only show about 200 commits"
    let r = vim_addon_mercurial#RevisionFromBuf()
    let proposal = "manifest -r ". (r == "" ? "tip" : r)
  else
    let proposal = "manifest -r".a:1
  endif
  let args = split(input("hg : ", proposal),'\s\+')
  call views#View("exec",["hg"] + args)
endf

fun! vim_addon_mercurial#HGLog()
  if a:0 == 0
    " only show about 200 commits"
    let proposal = "log -l 200"
  else
    let proposal = "log ".join(a:000,' ')
  endif
  let args = split(input("hg : ", proposal),'\s\+')
  call views#View("exec",["hg"] + args)
endf

" commit buffer and helpers {{{1
fun! vim_addon_mercurial#CommitOnBufWrite()
  let lines = getline(1,line('$'))
  " remove separator and git status output:
  let sep = vim_addon_mercurial#Sep("GIT COMMIT")
  let i = 0
  while i < len(lines)
    if lines[i] == sep
      let lines = lines[0:(i-1)]
      break
    endif
    let i = i+1
  endwhile
  if empty(substitute(join(lines),'\s','','g'))
    echo "user abort, empty commit message"
    return
  endif
  call vim_addon_mercurial#System(['git','commit','-F','-'], {'stdin-text' : join(lines, "\n")})
  bw!
endf

fun! vim_addon_mercurial#CommitOnBufRead()
  " empty:
  %g!//d
  let lines = [""
       \ , vim_addon_mercurial#Sep("GIT COMMIT"), "Put your commit message above this separator"
       \ ,""
       \ ,"==== git status ==="
   \ ]
   \ + split(vim_addon_mercurial#System(["git","status"]),"\n")
   \ + ["","==== git diff --cached ==="]
   \ + split(vim_addon_mercurial#System(["git","diff","--cached"]),"\n")

  call append(0, lines)
  set filetype=gitcommit
  normal gg
  startinsert
  set write
  set buftype=acwrite
endf

" shows the commit buffer - you can enter your message then
fun! vim_addon_mercurial#Commit()
  if vim_addon_mercurial#IsClean()
    echo "nohting to commit" | return
  else
    call s:ScratchCleanAdvanced("comitting-to-git-repository"
      \ , 'call vim_addon_mercurial#CommitOnBufRead()'
      \ , 'call vim_addon_mercurial#CommitOnBufWrite()'
      \ , ["commit current staged changes to git. It's always save to just bd!"]
      \ )
  endif
endf

fun! vim_addon_mercurial#BCommit()
  " ensure nothing else is staged
  try
    if !empty(vim_addon_mercurial#System(['git','diff','--cached']))
      let r = input("You already have cached some lines, proceed? [y = yes, r = run git reset first,* = abort]") 
      if r == "r"
        !git reset
      elseif r != "y"
        echo "user abort" | return
      endif
    endif
  catch /.*/
    if v:exception =~ 'No HEAD commit to compare with'
      call vim_addon_mercurial#Log(1,"can't check for staged changes, no HEAD yet")
    else
      throw v:exception
    endif
  endtry
  !git add %
  call vim_addon_mercurial#Commit()
endfun

" helpers {{{1

fun! vim_addon_mercurial#IsClean()
  try
    call vim_addon_mercurial#System(["git","status"])
    " exit status 0 = there are changes
    " this may break..
    return 0
  catch /.*/
    return 1
  endtry
endf


fun! vim_addon_mercurial#Sep(name)
  return "#===== ".a:name." ====================================================="
endf

" TODO replace this function ?
fun! vim_addon_mercurial#System(items, ... )
  let opts = a:0 > 0 ? a:1 : {}
  let cmd = ''
  for a in a:items
    let cmd .=  ' '.s:EscapeShArg(a)
  endfor
  if has_key(opts, 'stdin-text')
    let f = tempname()
    " don't know why writefile(["line 1\nline 2"], f, 'b') has a different
    " result?
    call writefile(split(opts['stdin-text'],"\n"), f, 'b')
    let cmd = cmd. ' < '.f
    "call s:Log(1, 'executing system command: '.cmd.' first 2000 chars of stdin are :'.opts['stdin-text'][:2000])
  else
    "call s:Log(1, 'executing system command: '.cmd)
  endif

  let result = system(cmd .' 2>&1')
  "if exists('f') | call delete(f) | endif
  let g:systemResult = result

  let s = get(opts,'status',0)
  if v:shell_error != s && ( type(s) != type('') || s != '*'  )
    let g:systemResult = result
    throw "command ".cmd."failed with exit code ".v:shell_error
     \ . " but ".s." expected. Have a look at the program output with :echo g:systemResult".repeat(' ',400)
     \ . " the first 500 chars of the result are \n".strpart(result,0,500)
  endif
  return result
endfun


fun! s:EscapeShArg(arg)
  " zsh requires []
  return escape(a:arg, ";()*<>| '\"\\`[]&")
endf


" scratch buffer {{{ 2
fun! s:ScratchClean(name)
  exec "TScratch 'scratch':".string("__".a:name."__")
  %g!//d
endf

fun! s:ScratchCleanAdvanced(name, onRead, onWrite, helptext)
  call s:ScratchClean(a:name)
  if type(a:onWrite) == type("")
    exec 'au vim_addon_mercurial BufWriteCmd <buffer> '.a:onWrite
  endif
  exec 'au vim_addon_mercurial BufReadCmd <buffer> '.a:onRead
  exec 'command! -nargs=0 -buffer Help call vim_addon_mercurial#Help('.string(a:helptext).')'
  " get contents:
  e!
endf

fun! vim_addon_mercurial#Help(h)
  call s:ScratchClean("HELP_OF_TMP_BUFFER")
  %g!//d
  call append(0, a:h)
endf


" vim: fdm=marker
