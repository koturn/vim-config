" ============================================================================
" FILE: vimrc.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" Last Modified: 2019 04/19
" DESCRIPTION: {{{
" descriptions.
" }}}
" ============================================================================
let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

" Constants {{{
let s:is_cui = !has('gui_running')
let s:is_windows = has('win32')
let s:is_cygwin = has('win32_unix')
let s:is_nvim = has('nvim')
let s:indent_cmd = 'indent -orig -bad -bap -nbbb -nbbo -nbc -bli0 -br -brs -nbs
      \ -c8 -cbiSHIFTWIDTH -cd8 -cdb -cdw -ce -ciSHIFTWIDTH -cliSHIFTWIDTH -cp2 -cs
      \ -d0 -nbfda -nbfde -di0 -nfc1 -nfca -hnl -iSHIFTWIDTH -ipSHIFTWIDTH
      \ -nlp -lps -npcs -piSHIFTWIDTH -nprs -psl -saf -sai -saw -sbi0
      \ -sc -nsob -nss -tsSOFTTABSTOP -ppiSHIFTWIDTH -ip0 -l160 -lc160'
let s:compl_key_dict = {
      \ char2nr("\<C-l>"): "\<C-x>\<C-l>",
      \ char2nr("\<C-n>"): "\<C-x>\<C-n>",
      \ char2nr("\<C-p>"): "\<C-x>\<C-p>",
      \ char2nr("\<C-k>"): "\<C-x>\<C-k>",
      \ char2nr("\<C-t>"): "\<C-x>\<C-t>",
      \ char2nr("\<C-i>"): "\<C-x>\<C-i>",
      \ char2nr("\<C-]>"): "\<C-x>\<C-]>",
      \ char2nr("\<C-f>"): "\<C-x>\<C-f>",
      \ char2nr("\<C-d>"): "\<C-x>\<C-d>",
      \ char2nr("\<C-v>"): "\<C-x>\<C-v>",
      \ char2nr("\<C-u>"): "\<C-x>\<C-u>",
      \ char2nr("\<C-o>"): "\<C-x>\<C-o>",
      \ char2nr('s'): "\<C-x>s",
      \ char2nr("\<C-s>"): "\<C-x>s"
      \}
let s:hint_i_ctrl_x_msg = join([
      \ '<C-l>: While lines',
      \ '<C-n>: keywords in the current file',
      \ "<C-k>: keywords in 'dictionary'",
      \ "<C-t>: keywords in 'thesaurus'",
      \ '<C-i>: keywords in the current and included files',
      \ '<C-]>: tags',
      \ '<C-f>: file names',
      \ '<C-d>: definitions or macros',
      \ '<C-v>: Vim command-line',
      \ "<C-u>: User defined completion ('completefunc')",
      \ "<C-o>: omni completion ('omnifunc')",
      \ "s: Spelling suggestions ('spell')"
      \], "\n")
let s:keymsgs = [
      \ "Don't use Left-Key!!  Enter Normal-Mode and press 'h'!!!!",
      \ "Don't use Down-Key!!  Enter Normal-Mode and press 'j'!!!!",
      \ "Don't use Up-Key!!  Enter Normal-Mode and press 'k'!!!!",
      \ "Don't use Right-Key!!  Enter Normal-Mode and press 'l'!!!!",
      \ "Don't use Delete-Key!!  Press 'x' in Normal-Mode!!!!",
      \ "Don't use Backspace-Key!!  Press 'X' in Normal-Mode!!!!"
      \]
" }}}


function! vimrc#retab_head() abort " {{{
  if &l:tabstop != a:width
    let &l:tabstop = a:width
  endif
  let spaces = repeat(' ', a:width)
  let cursor = getcurpos()
  if &expandtab
    execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 . (a:has_bang ?
          \ 's/^\s\+/\=substitute(substitute(submatch(0), spaces, "\t", "g"), "\t", spaces, "g")/ge' :
          \ 's/^\(\s*\t\+ \+\|\s\+\t\+ *\)\ze[^ ]/\=substitute(submatch(0), "\t", spaces, "g")/ge')
  else
    execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 . (a:has_bang ?
          \ 's/^\s\+/\=substitute(substitute(submatch(0), "\t", spaces, "g"), spaces, "\t", "g")/ge' :
          \ 's#^\(\s*\t\+ \+\|\s\+\t\+ *\)\ze[^ ]#\=repeat("\t", len(substitute(submatch(0), "\t", spaces, "g")) / a:width)#ge')
  endif
  call setpos('.', cursor)
endfunction " }}}

function! vimrc#toggle_tab_space(has_bang, width, line1, line2) abort " {{{
  let [&l:shiftwidth, &l:tabstop, &l:softtabstop] = [a:width, a:width, a:width]
  let [spaces, cursor] = [repeat(' ', a:width), getcurpos()]
  if &expandtab
    setlocal noexpandtab
    execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 . (a:has_bang ?
          \ 's/^\s\+/\=substitute(substitute(submatch(0), "\t", spaces, "g"), spaces, "\t", "g")/ge' :
          \ 's#^ \+#\=repeat("\t", len(submatch(0)) / a:width) . repeat(" ", len(submatch(0)) % a:width)#ge')
  else
    setlocal expandtab
    execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 . (a:has_bang ?
          \ 's/^\s\+/\=substitute(submatch(0), "\t", spaces, "g")/ge' :
          \ 's/^\t\+/\=repeat(" ", len(submatch(0)) * a:width)/ge')
  endif
  call setpos('.', cursor)
endfunction " }}}

function! vimrc#change_indent(has_bang, width) abort " {{{
  if a:has_bang
    let [&shiftwidth, &tabstop, &softtabstop] = [a:width, a:width, -1]
  else
    let [&l:shiftwidth, &l:tabstop, &l:softtabstop] = [a:width, a:width, -1]
  endif
endfunction " }}}

function! vimrc#smart_split(cmd) abort " {{{
  execute (winwidth(0) > winheight(0) * 2 ? 'vsplit' : 'split')
  execute a:cmd
endfunction " }}}

function! vimrc#clear_message() " {{{
  for i in range(201)
    echomsg ''
  endfor
endfunction " }}}

function! vimrc#messages_head(has_bang, ...) abort " {{{
  let n = a:0 > 0 ? a:1 : 10
  let lines = filter(split(s:redir('messages'), "\n"), "v:val !=# ''")[: n]
  if a:has_bang
    for line in lines
      echomsg line
    endfor
  else
    for line in lines
      echo line
    endfor
  endif
endfunction " }}}

function! vimrc#messages_tail(has_bang, ...) abort " {{{
  let n = a:0 > 0 ? a:1 : 10
  let lines = filter(split(s:redir('messages'), "\n"), 'v:val !=# ""')
  if n > len(lines)
    let n = len(lines)
  endif
  let lines = lines[len(lines) - n :]
  if a:has_bang
    for line in lines
      echomsg line
    endfor
  else
    for line in lines
      echo line
    endfor
  endif
endfunction " }}}

function! vimrc#cmd_which(cmd) abort " {{{
  if stridx(a:cmd, '/') != -1 || stridx(a:cmd, '\\') != -1
    echoerr a:cmd 'is not a command-name.'
    return
  endif
  let path = substitute(substitute($PATH, '\\', '/', 'g'), ';', ',', 'g')
  let save_suffix_add  = &suffixesadd
  if s:is_windows
    setlocal suffixesadd=.exe,.cmd,.bat
  endif
  let file_list = findfile(a:cmd, path, -1)
  if !empty(file_list)
    echo fnamemodify(file_list[0], ':p')
  else
    echo a:cmd 'was not found.'
  endif
  let &suffixesadd = save_suffix_add
endfunction " }}}

function! vimrc#cmd_lcd(count) abort " {{{
  let dir = expand('%:p' . repeat(':h', a:count + 1))
  if isdirectory(dir)
    execute 'lcd' fnameescape(dir)
  endif
endfunction " }}}

function! vimrc#buf_delete() abort " {{{
  let current_bufnr   = bufnr('%')
  let alternate_bufnr = bufnr('#')
  if buflisted(alternate_bufnr)
    buffer #
  else
    bnext
  endif
  if buflisted(current_bufnr)
    execute 'silent bwipeout' current_bufnr
    if bufloaded(current_bufnr) != 0
      execute 'buffer' current_bufnr
    endif
  endif
endfunction " }}}

function! vimrc#bwipeout_all(bang, ...) abort " {{{
  let bufnrs = map(split(s:redir('ls'), "\n"), 'str2nr(split(v:val, "\\s")[0])')
  if a:0 > 0
    call filter(bufnrs, 'index(a:000, bufname(v:val)) != -1')
  endif
  echohl ErrorMsg
  for bufnr in bufnrs
    try
      execute 'silent bwipeout' . a:bang bufnr
    catch /^Vim(bwipeout):E89: /
      echomsg substitute(v:exception, '^Vim(bwipeout):', '', '')
    endtry
  endfor
  echohl None
endfunction " }}}

function! vimrc#difforig() abort " {{{
  let save_filetype = &filetype
  vertical new
  setlocal buftype=nofile
  read #
  0d_
  let &filetype = save_filetype
  diffthis
  wincmd p
  diffthis
  autocmd MyAutoCmd InsertLeave <buffer>  diffupdate
endfunction " }}}

function! vimrc#vimdiff_in_newtab(...) abort " {{{
  if a:0 == 1
    tabedit %:p
    execute 'rightbelow vertical diffsplit' a:1
  else
    execute 'tabedit' a:1
    for file in a:000[1 :]
      execute 'rightbelow vertical diffsplit' file
    endfor
  endif
  wincmd w
endfunction " }}}

function! vimrc#compare(...) abort " {{{
  if a:0 == 1
    tabedit %:p
    execute 'rightbelow vnew' a:1
  else
    execute 'tabedit' a:1
    setlocal scrollbind
    for file in a:000[1 :]
      execute 'rightbelow vnew' file
      setlocal scrollbind
    endfor
  endif
  wincmd w
endfunction " }}}

function! vimrc#speed_up(has_bang) abort " {{{
  if a:has_bang
    setlocal noshowmatch nocursorline nocursorcolumn colorcolumn=
  else
    set noshowmatch nocursorline nocursorcolumn colorcolumn=
  endif
  NoMatchParen
  set laststatus=0 showtabline=0
  if !s:is_cui
    set guicursor=a:blinkon0
    if exists('+transparency')
      if s:is_windows
        set transparency=255
      else
        set transparency=0
      endif
    endif
  endif
endfunction " }}}

function! vimrc#comma_period(line1, line2) abort range " {{{
  let cursor = getcurpos()
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 's/、/，/ge'
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 's/。/．/ge'
  call setpos('.', cursor)
endfunction " }}}

function! vimrc#kutouten(line1, line2) abort range " {{{
  let cursor = getcurpos()
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 's/，/、/ge'
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 's/．/。/ge'
  call setpos('.', cursor)
endfunction " }}}

function! vimrc#devide_sentence(line1, line2) abort range " {{{
  let cursor = getcurpos()
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 's/\.\zs[ \n]/\r\r/ge'
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 's/[。．]\zs\n\?/\r\r/ge'
  call setpos('.', cursor)
endfunction " }}}

function! vimrc#make_junk_buffer(has_bang) abort " {{{
  if a:has_bang
    edit __JUNK_BUFFER__
    setlocal nobuflisted bufhidden=unload buftype=nofile
  else
    edit __JUNK_BUFFER_RECYCLE__
    setlocal nobuflisted buftype=nofile
  endif
endfunction " }}}

function! vimrc#delete_match_pattern(pattern, line1, line2) abort " {{{
  let cursor = getcurpos()
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 's/' . a:pattern . '//ge'
  call setpos('.', cursor)
endfunction " }}}

function! vimrc#delete_blank_lines(line1, line2) abort range " {{{
  let cursor = getcurpos()
  let offset = 0
  execute 'silent keepjumps keeppatterns' a:line1 ',' cursor[1] 'g /^\s*$/let offset += 1'
  let cursor[1] -= offset
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 'g /^\s*$/d'
  call setpos('.', cursor)
endfunction " }}}

function! vimrc#clear_undo() abort " {{{
  let save_undolevels = &l:undolevels
  setlocal undolevels=-1
  execute "silent! normal! a \<BS>\<Esc>"
  setlocal nomodified
  let &l:undolevels = save_undolevels
endfunction " }}}

function! vimrc#make_viml_foldings(line1, line2) abort " {{{
  let cursor = getcurpos()
  " {{{ {{{
  execute 'keepjumps keeppatterns' a:line1 ',' a:line2 's/^\s*\%(endfunction\|endfunctio\|endfuncti\|endfunct\|endfunc\|endfun\|endfu\|endf\)\%([a-z]\)\@!\zs\%(\s*".*}}}\)\@!/ " }}}/ce'
  execute 'keepjumps keeppatterns' a:line1 ',' a:line2 's/^\s*\%(function\|functio\|functi\|funct\|func\|fun\|fu\)\%([a-z]\)\@!!\?\s\+[a-zA-Z0-9\.:_#{}]\+(.*)\%(\s\+\%(abort\|dict\|range\)\)*\zs\%(\%(\s\+\%(abort\|dict\|range\)\)*\s*".*{{{\)\@!/ " {{{/ce'
  " }}} }}}
  call setpos('.', cursor)
endfunction " }}}

function! vimrc#show_tab_info() abort " {{{
  echo "====== Tab Page Info ======"
  let current_tnr = tabpagenr()
  let winid2bufnr_dict = s:create_winid2bufnr_dict()
  for tnr in range(1, tabpagenr('$'))
    let current_winnr = tabpagewinnr(tnr)
    echo (tnr == current_tnr ? '>' : ' ') 'Tab:' tnr
    echo '    Buffer number | Window Number | Window ID | Buffer Name'
    for wininfo in map(map(range(1, tabpagewinnr(tnr, '$')), '{"wnr": v:val, "wid": win_getid(v:val, tnr)}'), 'extend(v:val, {"bnr": winid2bufnr_dict[v:val.wid]})')
      echo '   ' (wininfo.wnr == current_winnr ? '*' : ' ') printf('%11d | %13d | %9d | %s', wininfo.bnr, wininfo.wnr, wininfo.wid, bufname(wininfo.bnr))
    endfor
  endfor
endfunction " }}}

function! vimrc#show_interp_version() abort " {{{
  let verdict = s:get_interp_version()
  for [key, val] in map(sort(keys(verdict)), '[v:val, verdict[v:val]]')
    if !val.has
      continue
    endif
    if has_key(val, 'exception')
      echohl Error
      echomsg printf('%s: %s', key, val.exception)
      echohl None
    else
      echomsg printf('%s: %s', key, val.version)
    endif
  endfor
endfunction " }}}

function! vimrc#dein_name_complete(arglead, cmdline, cursorpos) abort " {{{
  let arglead = tolower(a:arglead)
  echomsg a:arglead
  return filter(keys(dein#get()), '!stridx(tolower(v:val), arglead)')
endfunction " }}}

if exists('*win_gotoid')
  function! vimrc#buf_open_existing(bname, ...) abort " {{{
    let bnr = bufnr(a:bname)
    if bnr == -1
      throw 'E94: No matching buffer for ' . a:bname
    endif
    let wids = win_findbuf(bnr)
    let qmods = a:0 > 0 ? a:1 : ''
    if empty(wids)
      execute qmods 'new'
      execute 'buffer' bnr
    else
      call win_gotoid(wids[0])
    endif
  endfunction " }}}
else
  function! vimrc#buf_open_existing(bname) abort " {{{
    let bnr = bufnr(a:bname)
    if bnr == -1
      throw 'E94: No matching buffer for ' . a:bname
    endif
    let tindice = map(filter(map(range(1, tabpagenr('$')), '{"tindex": v:val, "blist": tabpagebuflist(v:val)}'), 'index(v:val.blist, bnr) != -1'), 'v:val.tindex')
    if empty(tindice)
      new
      execute 'buffer' bnr
    else
      execute 'tabnext' tindice[0]
      execute bufwinnr(bnr) 'wincmd w'
    endif
  endfunction " }}}
endif

if executable('sudo') && executable('tee')
  function! vimrc#save_as_root(bang, filename) abort " {{{
    execute 'write' a:bang '!sudo tee > /dev/null' (a:filename ==# '' ? '%' : a:filename)
  endfunction " }}}
else
  function! vimrc#save_as_root(bang, filename) abort " {{{
    echoerr 'sudo is not supported in this environment.'
  endfunction " }}}
endif

if executable('xxd')
  function! vimrc#read_binary() abort " {{{
    if !&bin && &filetype !=# 'xxd'
      set binary
      silent %!xxd -g 1
      let b:original_filetype = &filetype
      setfiletype xxd
    endif
  endfunction " }}}
  function! vimrc#write_binary() abort " {{{
    if &bin && &filetype ==# 'xxd'
      silent %!xxd -r
      write
      silent %!xxd -g 1
      set nomodified
    endif
  endfunction " }}}
  function! vimrc#decode_binary() abort " {{{
    if &bin && &filetype ==# 'xxd'
      silent %!xxd -r
      set nobinary
      let &filetype = b:original_filetype
      unlet b:original_filetype
    endif
  endfunction " }}}
else
  function! vimrc#read_binary() abort " {{{
    echoerr 'command not found: xxd'
  endfunction " }}}
  function! vimrc#write_binary() abort " {{{
    echoerr 'command not found: xxd'
  endfunction " }}}
  function! vimrc#decode_binary() abort " {{{
    echoerr 'command not found: xxd'
  endfunction " }}}
endif

if has('terminal')
  function! vimrc#complete_term_bufname(arglead, cmdline, cursorpos) abort " {{{
    let arglead = tolower(a:arglead)
    return filter(map(term_list(), 'bufname(v:val)'), '!stridx(tolower(v:val), arglead)')
  endfunction " }}}

  function! vimrc#term_open_existing(qmods, ...) abort " {{{
    if a:0 == 0
      let bnrs = term_list()
      if empty(bnrs)
        execute a:qmods 'terminal'
      else
        let wids = win_findbuf(bnrs[0])
        if empty(wids)
          terminal
        else
          call win_gotoid(wids[0])
        endif
      endif
    else
      let bnr = bufnr(a:1)
      if bnr == -1
        throw 'E94: No matching buffer for ' . a:1
      elseif index(term_list(), bnr) == -1
        throw a:1 . ' is not a terminal buffer'
      endif
      let wids = win_findbuf(bnr)
      if empty(wids)
        execute a:qmods term_getsize(bnr)[0] 'new'
        execute 'buffer' bnr
      else
        call win_gotoid(wids[0])
      endif
    endif
  endfunction " }}}
else
  function! vimrc#complete_term_bufname(arglead, cmdline, cursorpos) abort " {{{
    echomsg 'terminal is not supported'
  endfunction " }}}
  function! vimrc#term_open_existing(qmods, ...) abort " {{{
    echomsg 'terminal is not supported'
  endfunction " }}}
endif

if executable('man')
  function! vimrc#open_man(word) abort " {{{
    echo 'man' string(a:word)
    let bname = '[man ' . a:word . ']'
    if bufexists(bname)
      call vimrc#buf_open_existing(bname)
      return
    endif
    let lines = systemlist('man ' . a:word)
    if v:shell_error != 0
      echohl ErrorMsg
      for line in lines
        echomsg line
      endfor
      echohl None
    else
      execute 'topleft new' bname
      setfiletype man
      call setline(1, lines)
      call vimrc#clear_undo()
      setlocal bufhidden=wipe buftype=nofile nobuflisted readonly
    endif
  endfunction " }}}
else
  function! vimrc#open_man(word) abort " {{{
    echoerr 'command not found: man'
  endfunction " }}}
endif

function! vimrc#get_highlight_info_lines(lnum, col) " {{{
  let lines = []
  for synid in synstack(a:lnum, a:col)
    let hldef_dict = s:generate_hldef_dict({}, synid)
    let name = synIDattr(synid, 'name')
    call add(lines, name)
    while has_key(hldef_dict[name], 'link')
      let name2 = hldef_dict[name].link
      call add(lines, printf('  highlight! link %s %s', name, name2))
      let name = name2
    endwhile
    if has_key(hldef_dict[name], 'def')
      call add(lines, printf('  ' . hldef_dict[name].def))
    endif
  endfor
  return lines
endfunction " }}}

function! vimrc#show_highlight_info(lnum, col) abort " {{{
  echo join(vimrc#get_highlight_info_lines(a:lnum, a:col), "\n")
endfunction " }}}

function! vimrc#show_file_size() abort " {{{
  let size = (&encoding ==# &fileencoding || &fileencoding ==# '')
        \ ? line2byte(line('$') + 1) - 1 : getfsize(expand('%'))
  let bufname = bufname('%')
  if bufname ==# ''
    let bufname = '[No Name]'
  endif
  echo 'File size:' bufname
  echo printf('%.2f KB', size / 1024.0)
  echo size 'B'
  " if size < 0
  "   let size = 0
  " endif
  " for unit in ['B', 'KB', 'MB']
  "   if size < 1024
  "     return size . unit
  "   endif
  "   let size = size / 1024
  " endfor
  " return size . 'GB'
endfunction " }}}

function! vimrc#plugin_test(use_gvim, ex_command, is_same_window) abort " {{{
  let cmd = escape((a:use_gvim ? 'gvim' : 'vim')
        \ . ' -u ~/.vim/min.vim'
        \ . ' -U NONE'
        \ . ' -i NONE'
        \ . ' -n'
        \ . ' -N'
        \ . printf(' --cmd "set rtp+=%s"', getcwd())
        \ . (a:ex_command ==# '' ? '' : printf('-c "au VimEnter * %s"', a:ex_command)), '!')
  if s:is_windows
    execute 'silent' (a:use_gvim ? '!start'
          \ : a:is_same_window ? '!'
          \ : '!start cmd /c call') cmd
  else
    execute 'silent !' cmd
    redraw!
  endif
endfunction " }}}


if executable('tasklist')
  if s:is_windows
    function! vimrc#show_memory_usage() abort " {{{
      let ret = s:system('tasklist /NH /FI "PID eq ' . getpid() . '"')
      echomsg split(ret, ' \+')[4] 'KB'
    endfunction " }}}
  elseif s:is_cygwin
    function! vimrc#show_memory_usage() abort " {{{
      let ret = s:system('tasklist /NH /FI "PID eq ' . s:pid2winpid(getpid()) . '"')
      echomsg split(ret, ' \+')[4] 'KB'
    endfunction " }}}
    function! s:pid2winpid(pid) abort " {{{
      let ret = split(s:system('ps -p ' . a:pid), "\n")
      if len(ret) < 2
        echoerr 'Specified pid:' a:pid 'is not exsits'
      else
        return split(ret[1][1 :], ' \+')[3]
      endif
    endfunction " }}}
  else
    function! vimrc#show_memory_usage() abort " {{{
      echomsg 'Cannot available this command'
    endfunction " }}}
  endif
elseif executable('ps')
  function! vimrc#show_memory_usage() abort " {{{
    echomsg split(split(s:system('ps u -p ' . getpid()), "\n")[1], ' \+')[5] 'KB'
  endfunction " }}}
else
  function! vimrc#show_memory_usage() abort " {{{
    echomsg 'Cannot available this command'
  endfunction " }}}
endif

if executable('jq')
  function! vimrc#jq(has_bang, ...) abort range " {{{
    execute 'silent' a:firstline ',' a:lastline '!jq' (a:0 == 0 ? '.' : a:1)
    if !v:shell_error || a:has_bang
      return
    endif
    let error_lines = filter(getline('1', '$'), 'v:val =~# "^parse error: "')
    let error_lines = map(error_lines, 'substitute(v:val, "line \\zs\\(\\d\\+\\)\\ze,", "\\=(submatch(1) + a:firstline - 1)", "")')
    let winheight = len(error_lines) > 10 ? 10 : len(error_lines)
    undo
    execute 'botright' winheight 'new'
    setlocal nobuflisted bufhidden=unload buftype=nofile
    call setline(1, error_lines)
    call vimrc#clear_undo()
    setlocal readonly
  endfunction " }}}
else
  function! vimrc#jq(has_bang, ...) abort range " {{{
    echoerr 'command not found: jq'
  endfunction " }}}
endif

if executable('indent')
  function! vimrc#format_c_program(has_bang) abort range " {{{
    let indent_cmd = substitute(vimrc#indent_cmd, 'SHIFTWIDTH', &shiftwidth, 'g')
    let indent_cmd = substitute(indent_cmd, 'SOFTTABSTOP', &softtabstop < 0 ? &shiftwidth : &softtabstop, 'g')
    let indent_cmd .= &expandtab ? ' -nut' : ' -ut'
    execute 'silent' a:firstline ',' a:lastline '!' indent_cmd
    if !v:shell_error || a:has_bang
      return
    endif
    let current_file = expand('%')
    if current_file ==# ''
      let current_file = '[No Name]'
    endif
    let error_lines = filter(getline('1', '$'), 'v:val =~# "^indent: Standard input:\\d\\+: Error:"')
    let error_lines = map(error_lines, 'substitute(v:val, "^indent: \\zsStandard input:\\(\\d\\+\\)\\ze: Error:", "\\=current_file . \":\" . (submatch(1) + a:firstline - 1)", "")')
    let winheight = len(error_lines) > 10 ? 10 : len(error_lines)
    undo
    execute 'botright' winheight 'new'
    setlocal nobuflisted bufhidden=unload buftype=nofile
    call setline(1, error_lines)
    call vimrc#clear_undo()
    setlocal readonly
  endfunction " }}}
else
  function! vimrc#format_c_program(has_bang) abort range " {{{
    echoerr 'command not found: indent'
  endfunction " }}}
endif

if executable('pdftotext')
  function! vimrc#pdftotext(file) abort " {{{
    new
    execute '0read !pdftotext -nopgbrk -layout' a:file '-'
    call vimrc#clear_undo()
  endfunction " }}}
else
  function! vimrc#pdftotext(file) abort " {{{
    echoerr 'command not found: pdftotext'
  endfunction " }}}
endif

function! vimrc#auto_mkdir(dir, force) abort " {{{
  if !isdirectory(a:dir) && (a:force || input(printf('"%s" does not exist. Create? [y/N]', a:dir)) =~? '^y\%[es]$')
    call mkdir(iconv(a:dir, &enc, &tenc), 'p')
  endif
endfunction " }}}

function! vimrc#hint_cmd_output(prefix, cmd) abort " {{{
  redir => str
    execute a:cmd
  redir END
  let more_old = &more
  set nomore
  echo str
  let &more = more_old
  return a:prefix . nr2char(getchar())
endfunction " }}}

function! vimrc#hint_i_ctrl_x() abort " {{{
  let more_old = &more
  set nomore
  echo s:hint_i_ctrl_x_msg
  let &more = more_old
  let c = getchar()
  return get(s:compl_key_dict, c, nr2char(c))
endfunction " }}}


function! vimrc#preview_fold(previewheight) abort " {{{
  let lnum = line('.')
  if foldclosed(lnum) <= -1
    pclose
    return
  endif
  let lines = getline(lnum, foldclosedend(lnum))
  if len(lines) > a:previewheight
    let lines = lines[: a:previewheight - 1]
  endif
  let filetype = &ft
  let winnr = bufwinnr('__fold__')
  if winnr == -1
    silent execute 'botright' a:previewheight 'split' '__fold__'
  else
    silent wincmd P
  endif
  %d _
  execute 'setlocal syntax=' . filetype
  setlocal buftype=nofile noswapfile bufhidden=wipe previewwindow foldlevel=99 nowrap
  call append(0, lines)
  wincmd p
endfunction " }}}

function! vimrc#map_easy_close() abort " {{{
  nnoremap <silent> <buffer> q  :<C-u>q<CR>
endfunction " }}}

function! vimrc#complete_xml_tag() abort " {{{
  normal! vy
  execute 'normal!' (@* ==# '<' ? 'v%x' : '%v%x')
  if @* =~# '/\s*>'
    normal! p
    return
  endif
  let @* = @* =~# '^</' ?
        \ substitute(@*, '\(</\(\a\+\)\s*.*/*>\)', '<\2>\1', 'g') :
        \ substitute(@*, '\(<\(\a\+\)\s*.*/*>\)', '\1</\2>', 'g')
  normal! p%
  startinsert
endfunction " }}}

function! vimrc#get_selected_text() abort " {{{
  let tmp = @@
  silent normal! gv"zy
  let [text, @@] = [@@, tmp]
  return text
endfunction " }}}

function! vimrc#exec_selected_text() abort " {{{
  execute vimrc#get_selected_text()
endfunction " }}}

" Generate match pattern for selected text.
" @*: clipboard  @@: anonymous buffer
" mode == 0 : magic, mode == 1 : nomagic, mode == 2 : verymagic
function! vimrc#store_selected_text(...) abort " {{{
  let mode = a:0 > 0 ? a:1 : !&magic
  let selected = substitute(escape(vimrc#get_selected_text(),
        \ mode == 2 ? '^$[]/\.*~(){}<>?+=@|%&' :
        \ mode == 1 ? '^$[]/\' :
        \ '^$[]/\.*~'), "\n", '\\n', 'g')
  silent! let [@*, @0] = [selected, selected]
endfunction " }}}

function! vimrc#range_search(d) abort " {{{
  let s = input(a:d)
  if strlen(s) > 0
    call feedkeys(a:d . '\%V' . s . "\<CR>", 'n')
  endif
endfunction " }}}

function! vimrc#echo_keymsg(msgnr) abort " {{{
  echo s:keymsgs[a:msgnr]
endfunction " }}}


function! s:redir(cmd) abort " {{{
  let [verbose, verbosefile] = [&verbose, &verbosefile]
  set verbose=0 verbosefile=
  redir => str
    execute 'silent!' a:cmd
  redir END
  let [&verbose, &verbosefile] = [verbose, verbosefile]
  return str
endfunction " }}}

if has('job') && !s:is_nvim
  function! s:system(cmd) abort " {{{
    let out = ''
    let job = job_start(a:cmd, {
          \ 'out_cb': {ch, msg -> [execute('let out .= msg'), out]},
          \ 'out_mode': 'raw'
          \})
    while job_status(job) ==# 'run'
      sleep 1m
    endwhile
    return out
  endfunction " }}}
else
  function! s:_system(cmd) abort " {{{
    try
      let s:system = function('vimproc#cmd#system')
      return s:system(a:cmd)
    catch /^Vim(call)\=:E117: .\+: vimproc#cmd#system$/
      let s:system = function('system')
      return system(a:cmd)
    endtry
  endfunction " }}}
  let s:system = function('s:_system')
endif

function! s:create_winid2bufnr_dict() abort " {{{
  let winid2bufnr_dict = {}
  for bnr in filter(range(1, bufnr('$')), 'v:val')
    for wid in win_findbuf(bnr)
      let winid2bufnr_dict[wid] = bnr
    endfor
  endfor
  return winid2bufnr_dict
endfunction " }}}

function! s:generate_hldef_dict(hldef_dict, synid1) abort " {{{
  let [synid2, name1] = [synIDtrans(a:synid1), synIDattr(a:synid1, 'name')]
  if a:synid1 == synid2
    let hldef = substitute(printf('highlight! %s %s %s %s %s %s',
          \ name1,
          \ s:generate_colordef(a:synid1, 'cterm'),
          \ s:generate_attr(a:synid1, 'cterm'),
          \ s:generate_colordef(a:synid1, 'gui'),
          \ s:generate_attr(a:synid1, 'gui'),
          \ s:generate_attr(a:synid1, 'term')), '\%(\s\zs\s\+\|\s\+$\)', '', 'g')
    return extend(a:hldef_dict, {
          \ name1: {
          \   'id': a:synid1,
          \   'def': hldef
          \ }
          \})
  else
    return s:generate_hldef_dict(extend(a:hldef_dict, {
          \ name1: {
          \   'id': a:synid1,
          \   'link': synIDattr(synid2, 'name')
          \ }
          \}), synid2)
  endif
endfunction " }}}

function! s:generate_colordef(synid, mode) abort " {{{
  let colordef_list = []
  for what in ['fg#', 'bg#']
    let color = synIDattr(a:synid, what, a:mode)
    if color !=# ''
      call add(colordef_list, a:mode . what[: 1] . '=' . color)
    endif
  endfor
  return join(colordef_list)
endfunction " }}}

function! s:generate_attr(synid, mode) abort " {{{
  let attrs = filter(['bold', 'italic', 'reverse', 'standout', 'underline', 'undercurl', 'strikethrough'], "synIDattr(a:synid, v:val, a:mode) is# '1'")
  return len(attrs) == 0 ? '' : (a:mode . '=' . join(attrs, ','))
endfunction " }}}

function! s:get_lua_version() abort " {{{
  if !has('lua')
    return {'version': '', 'has': 0}
  endif
  try
    let verstr = luaeval('_VERSION')
    let jitver = luaeval('jit.version')
    if type(jitver) == type('')
      let verstr .= printf(', %s', jitver)
    endif
    return {'version': verstr, 'has': 1}
  catch
    return {'version': '', 'has': 1, 'exception': v:exception}
  endtry
endfunction " }}}

function! s:get_mzscheme_version() abort " {{{
  if !has('mzscheme')
    return {'version': '', 'has': 0}
  endif
  try
    return {'version': mzeval('(display (version))'), 'has': 1}
  catch
    return {'version': '', 'has': 1, 'exception': v:exception}
  endtry
endfunction " }}}

function! s:get_perl_version() abort " {{{
  if !has('perl')
    return {'version': '', 'has': 0}
  endif
  try
    return {'version': perleval('$^V').original, 'has': 1}
  catch
    return {'version': '', 'has': 1, 'exception': v:exception}
  endtry
endfunction " }}}

function! s:get_python_version() abort " {{{
  if !has('python')
    return {'version': '', 'has': 0}
  endif
  try
    python import sys
    return {'version': pyeval('sys.version'), 'has': 1}
  catch
    return {'version': '', 'has': 1, 'exception': v:exception}
  endtry
endfunction " }}}

function! s:get_python3_version() abort " {{{
  if !has('python3')
    return {'version': '', 'has': 0}
  endif
  try
    python3 import sys
    return {'version': py3eval('sys.version'), 'has': 1}
  catch
    return {'version': '', 'has': 1, 'exception': v:exception}
  endtry
endfunction " }}}

function! s:get_pythonx_version() abort " {{{
  if !has('pythonx')
    return {'version': '', 'has': 0}
  endif
  try
    pythonx import sys
    return {'version': pyxeval('sys.version'), 'has': 1}
  catch
    return {'version': '', 'has': 1, 'exception': v:exception}
  endtry
endfunction " }}}

function! s:get_ruby_version() abort " {{{
  if !has('ruby')
    return {'version': '', 'has': 0}
  endif
  try
    return {'version': rubyeval('RUBY_VERSION'), 'has': 1}
  catch
    return {'version': '', 'has': 1, 'exception': v:exception}
  endtry
endfunction " }}}

function! s:get_tcl_version() abort " {{{
  if !has('tcl')
    return {'version': '', 'has': 0}
  endif
  try
    redir => tclver
      silent tcl puts [info patchlevel]
    redir END
    return {'version': trim(tclver), 'has': 1}
  catch
    redir END
    return {'version': '', 'has': 1, 'exception': v:exception}
  endtry
endfunction " }}}

function! s:get_interp_version() abort " {{{
  let verdict = {}
  for interp in ['lua', 'mzscheme', 'perl', 'pythonx', 'python3', 'python', 'ruby', 'tcl']
    call extend(verdict, {
          \ interp: s:get_{interp}_version()
          \})
  endfor
  return verdict
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo
