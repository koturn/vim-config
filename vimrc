" =============================================================================
"     __         __                      ____
"    / /______  / /___  ___________     / __ \ _
"   / //_/ __ \/ __/ / / / ___/ __ \   / / / /(_)
"  / ,< / /_/ / /_/ /_/ / /  / / / /  / /_/ / _
" /_/|_|\____/\__/\__,_/_/  /_/ /_/   \____/ ( )
"                                            |/
"
" This .vimrc was mainly written for Windows.
" But you can also use in Cygwin or UNIX/Linux.
" In Windows, you have to put this in HOME-directory.
" ==============================================================================
" ------------------------------------------------------------------------------
" Initialize and Variables {{{
" ------------------------------------------------------------------------------
if 0 | endif
if &compatible && has('vim_starting')
  set nocompatible
endif
" Variables for various environment.
let s:startuptime = reltime()

let s:is_nvim    =  has('nvim')
let g:is_windows =  has('win16') || has('win32') || has('win64')
let g:is_cygwin  =  has('win32unix')
let g:is_mac     = !g:is_windows && (has('mac') || has('macunix') || has('gui_macvim')
      \ || (!isdirectory('/proc') && executable('sw_vers')))
let g:is_unix    =  has('unix')
let s:is_cui     = !has('gui_running') && !(g:is_windows && s:is_nvim)
" let s:is_cui     = !has('gui_running')
" echomsg s:is_cui
let g:at_startup =  has('vim_starting')
let s:is_tmux    = $TMUX !=# ''
" let s:is_ssh     = $SSH_TTY ==# ''
" let s:is_android =  has('unix')
"       \ && ($HOSTNAME ==? 'android' || $VIM =~? 'net\.momodalo\.app\.vimtouch')

function! s:get_sid_prefix() abort
  return matchstr(expand('<sfile>'), '^function \zs<SNR>\d\+_\zeget_sid_prefix$')
endfunction
let s:sid_prefix = s:get_sid_prefix()
delfunction s:get_sid_prefix

if g:is_windows && s:is_cui
  set enc=cp932
else
  set enc=utf-8
endif
scriptencoding utf-8  " required to visualize double-byte spaces.(after set enc)
if !g:is_windows || !s:is_nvim
  language C
  language ctype C
  language message C
  language time C
endif

if !exists($MYGVIMRC)
  let $MYGVIMRC = $HOME . '/.gvimrc'
endif
let $DOTVIM = $HOME . '/.vim'
if g:at_startup && g:is_windows
  let &rtp = substitute(&rtp, 'vimfiles', '\.vim', 'g')
  " let &rtp = substitute(substitute(&rtp, 'vimfiles', '\.vim', 'g'), '\\', '/', 'g')
  " set rtp^=$DOTVIM,$DOTVIM/after,$VIM/.vim,$VIM/.vim/after
endif

" If $DOTVIM/.private.vim is exists, ignore error.
if filereadable(expand('$DOTVIM/.private.vim'))
  source $DOTVIM/.private.vim
else
  let g:private = {}
endif

augroup MyAutoCmd
  autocmd!
augroup END
" Measure startup time.
if g:at_startup && has('reltime')
  autocmd MyAutoCmd VimEnter *
        \   redraw
        \ | echomsg 'startuptime:' reltimestr(reltime(s:startuptime))
        \ | unlet s:startuptime
endif

" Singleton
if g:at_startup && has('clientserver') && !get(g:, 'disable_singleton', 0)
  let s:running_vim_list = filter(split(serverlist(), "\n"), 'v:val !=? v:servername')
  if !empty(s:running_vim_list)
    if !argc()
      quitall!
    endif
    if g:is_windows
      if s:is_cui
        silent !cls
      endif
      let s:vim_cmd = '!start gvim'
    else
      let s:vim_cmd = '!gvim'
    endif
    silent execute s:vim_cmd
          \ '--servername' s:running_vim_list[0]
          \ '--remote-tab-silent' join(map(argv(), 'fnameescape(v:val)'), ' ')
    quitall!
  endif
  unlet s:running_vim_list
endif


" Timer {{{
if g:at_startup
  let s:Timer = {
        \ 'elapsed_time': 0.0,
        \ 'is_stopped': 1
        \}

  function! s:Timer.new(name) abort
    let timer = copy(self)
    let timer.name = a:name
    call timer.start()
    return timer
  endfunction

  function! s:Timer.start() abort dict
    if self.is_stopped
      let self.is_stopped = 0
      let self.start_time = reltime()
    endif
  endfunction

  function! s:Timer.stop() abort dict
    if !self.is_stopped
      let self.elapsed_time += str2float(reltimestr(reltime(self.start_time)))
      let self.is_stopped = 1
    endif
  endfunction

  function! s:Timer.get_elapsed_time() abort dict
    return self.elapsed_time + (self.is_stopped ? 0.0 : str2float(reltimestr(reltime(self.start_time))))
  endfunction

  function! s:Timer.show() abort dict
    let t = s:convert_time(self.get_elapsed_time())
    echo printf('%16s: %2d days %02d:%02d:%02d.%1d', self.name, t.day, t.hour, t.minute, t.second, t.msec)
  endfunction

  function! s:convert_time(time) abort
    let integer_part = float2nr(a:time)
    let decimal_part = a:time - integer_part
    let t = {
          \ 'day': integer_part / 86400,
          \ 'msec': float2nr((decimal_part + 0.000001) * 10)
          \}
    let integer_part = integer_part % 86400
    let t.hour = integer_part / 3600
    let integer_part = integer_part % 3600
    let t.minute = integer_part / 60
    let t.second = integer_part % 60
    return t
  endfunction

  let s:startupdate = strftime('%Y/%m/%d(%a) %H:%M:%S')
  let s:timer_launched = s:Timer.new('Launched Time')
  let s:timer_active = s:Timer.new('Active Time')
  let s:timer_used = s:Timer.new('Used Time')
  unlet s:Timer

  function! s:show_time_info() abort
    echo 'Launched at:' s:startupdate
    call s:timer_launched.show()
    call s:timer_active.show()
    call s:timer_used.show()
  endfunction
  command! -bar ShowTimeInfo  call s:show_time_info()
endif

autocmd MyAutoCmd FocusGained,WinEnter * call s:timer_active.start()
autocmd MyAutoCmd FocusLost * call s:timer_active.stop()
autocmd MyAutoCmd CursorHold,CursorHoldI,FocusLost * call s:timer_used.stop()
autocmd MyAutoCmd CursorMoved,CursorMovedI * call s:timer_used.start()
" }}}

" let s:timer_used.clock = 0
" let s:timer_used.time_to_stop = 30000
" function! s:timer_used.update() abort dict
"   if self.clock < self.time_to_stop && !self.is_stopped
"     call feedkeys(mode() ==# 'i' ? "\<C-g>\<ESC>" : "g\<ESC>", 'n')
"     let self.clock += &updatetime
"   else
"     echo 'Stopped'
"     call self.stop()
"     let self.clock = 0
"   endif
" endfunction
"
" function! s:timer_used.wakeup() abort dict
"   let self.clock = 0
"   call self.start()
" endfunction
"
" autocmd MyAutoCmd CursorHold,CursorHoldI * call s:timer_used.update()
" autocmd MyAutoCmd CursorMoved,CursorMovedI * call s:timer_used.wakeup()

" }}}
let g:aref_web_source = {
\  'stackage' : {
\    'url' : 'https://www.stackage.org/lts-6.6/hoogle?q=%s&page=1'
\  }
\}
" ------------------------------------------------------------------------------
" Basic settings {{{
" ------------------------------------------------------------------------------
let s:_executable = {}
function! s:executable(cmd) abort
  if !has_key(s:_executable, a:cmd)
    let s:_executable[a:cmd] = executable(a:cmd)
  endif
  return s:_executable[a:cmd]
endfunction

set pastetoggle=<F10>
set helplang=ja
set shortmess& shortmess+=I
set shellslash
if g:is_windows
  set noshelltemp
endif
set virtualedit=block
setglobal autoread
set nowrap
if exists('+breakindent')
  set breakindent breakindentopt=min:40,shift:-1
endif
set synmaxcol=1000
set textwidth=0
set colorcolumn=80,100
set foldmethod=marker
set browsedir=buffer
set showmatch
set smartcase
set whichwrap=b,s,h,l,<,>,[,]
if v:version > 704 || v:version == 704 && has('patch793')
  set visualbell t_vb=
else
  set belloff=all
endif
set lazyredraw
set viminfo= noswapfile nobackup nowritebackup
if has('persistent_undo')
  set noundofile
endif
set hidden
set switchbuf=useopen,usetab
set more
set formatoptions=nroqB
if v:version >= 704
  set formatoptions+=j
endif
set nojoinspaces
set nrformats=alpha,octal,hex
set scrolloff=5
if s:is_cui
  set ttyfast
  set ttyscroll=3
endif
set timeout ttimeout timeoutlen=1000 ttimeoutlen=100
set autoindent smartindent
set expandtab smarttab
set shiftwidth=2 tabstop=2 softtabstop=-1
set shiftround
set copyindent
" set number
set updatetime=1500
set maxfuncdepth=10000
" title
" set title
" set titlelen=95
" set titlestring=Vim:\ %f\ %h%r%m
" Use vim-help
" if get(g:private, 'browser_cmd', '') ==# ''
"   set keywordprg=
" else
"   let &keywordprg = g:private.browser_cmd
" endif
if s:executable('man')
  function! s:keywordprg_man(word) abort " {{{
    let [lines, bname] = [systemlist('man ' . a:word), '[man ' . a:word . ']']
    if v:shell_error != 0
      echohl ErrorMsg
      for line in lines
        echomsg line
      endfor
      echohl None
    elseif bufexists(bname)
      call s:buf_open_existing(bname)
    else
      execute 'topleft new' escape(bname, '[]')
      setfiletype man
      call setline(1, lines)
      call s:clear_undo()
      setlocal bufhidden=wipe buftype=nofile nobuflisted readonly
    endif
  endif
  endfunction " }}}
  autocmd MyAutoCmd FileType c,sh,zsh  nnoremap <silent> <buffer> K  :<C-u>call <SID>keywordprg_man(expand('<cword>'))<CR>
endif

autocmd MyAutoCmd FileType help,vim  setlocal keywordprg=:help
if s:executable('firefox')
  setglobal keywordprg=firefox\ -search
else
  setglobal keywordprg=:help
endif

set spelllang=en,cjk
set completeopt=menu,preview
set showfulltag
if s:executable('ag')
  setglobal grepprg=ag\ --nogroup\ -iS
  set grepformat=%f:%l:%m
elseif s:executable('ack')
  setglobal grepprg=ack\ --nogroup
  set grepformat=%f:%l:%m
elseif s:executable('grep')
  setglobal grepprg=grep\ -Hnd\ skip\ -r
  set grepformat=%f:%l:%m,%f:%l%m,%f\ \ %l%m
else
  setglobal grepprg=internal
endif
if has('printer') && g:is_windows
  set printheader=%t%=%N
  set printoptions=number:y,header:2,syntax:y,left:20pt,right:20pt,top:28pt,bottom:28pt
  " set printfont=Consolas:h8 printmbfont=r:MS_Gothic:h8,a:yes
  set printfont=Ricty_Diminished_Discord:h10 printmbfont=r:Ricty_Diminished_Discord:h10,a:yes
endif
if has('cryptv')
  if v:version > 704 || v:version == 704 && has('patch399')
    setglobal cryptmethod=blowfish2
  elseif v:version >= 703
    setglobal cryptmethod=blowfish
  else
    setglobal cryptmethod=zip
  endif
endif
if has('clipboard') && !s:is_nvim
  if has('unnamedplus')
    set clipboard=unnamedplus,autoselect
    cnoremap <M-P>  <C-r>+
    vnoremap <M-P>  "+p
  else
    set clipboard=unnamed,autoselect
    cnoremap <M-P>  <C-r>*
    vnoremap <M-P>  "*p
  endif
endif

if s:is_tmux
  set t_ut=
elseif exists('&termguicolors') && ($COLORTERM == 'truecolor' || s:is_cui && g:is_windows && has('vcon'))
  set termguicolors
endif

if !s:is_cui
  set guioptions=M
endif

" In windows, not to use cygwin-git.
if g:is_windows
  let s:win_git_path = get(g:private, 'win_git_path', '')
  if s:win_git_path !=# ''
    " let $PATH = g:win_git_path . ';' . $PATH
  endif
  unlet s:win_git_path
endif


set ignorecase
set backspace=indent,eol,start
set wrapscan
set showmatch
set wildmenu wildmode=longest:full,full wildoptions=tagfile
set showcmd
set cmdheight=2
set history=200
set incsearch
if has('mouse')
  set mouse=a mousemodel=popup
endif
if &t_Co > 2 || !s:is_cui
  syntax enable
  set hlsearch
endif
if filereadable($HOME . '/.vimrc') && filereadable($HOME . '/.ViMrC')
  setglobal tags=./tags;,tags;
else
  setglobal tags=./tags;
endif

if !g:at_startup && g:is_windows && $PATH !~? '\(^\|;\)' . escape($VIM, '\\') . '\(;\|$\)'
  let $PATH .= ';' . $VIM
endif

if g:is_mac
  set iskeyword=@,48-57,_,128-167,224-235
endif

" ------------------------------------------------------------------------------
" CLPUM patch {{{
" ------------------------------------------------------------------------------
if has('clpum')
  set wildmenu wildmode=longest,popup
  set clpumheight=40
  autocmd MyAutoCmd ColorScheme * highlight! link ClPmenu Pmenu
  " function! s:clpum_complete(findstart, base) abort
  "   return a:findstart ? getcmdpos() : [
  "         \ {'word': 'Jan', 'menu': 'January'},
  "         \ {'word': 'Feb', 'menu': 'February'},
  "         \ {'word': 'Mar', 'menu': 'March'},
  "         \ {'word': 'Apr', 'menu': 'April'},
  "         \ {'word': 'May', 'menu': 'May'},
  "         \]
  " endfunction
  " let &clcompletefunc = s:sid_prefix . 's:clpum_complete'
endif
" }}}
" }}}

" ------------------------------------------------------------------------------
" Character-code and EOL-code {{{
" ------------------------------------------------------------------------------
if g:is_windows
  set fenc=utf-8
  set tenc=cp932
endif


function! s:set_term_mintty() abort
  let &t_ti .= "\e[2 q"
  let &t_SI .= "\e[6 q"
  let &t_EI .= "\e[2 q"
  let &t_te .= "\e[0 q"
endfunction

let s:termemu_dict = {
      \ 'mintty': function('s:set_term_mintty')
      \}

if has_key(s:termemu_dict, $TERMEMU)
  call s:termemu_dict[$TERMEMU]()
endif


if g:is_cygwin
  set enc =utf-8
  set fenc=utf-8
  set tenc=utf-8
  if (&term =~# '^xterm' || &term ==# 'screen') && &t_Co < 256
    set t_Co=256  " Extend cygwin terminal color
  endif
  if &term !=# 'cygwin'  " not in command prompt
    " 縦分割スクロール高速化
    " http://www.youtube.com/watch?v=KQfOArRJkYI
    " http://ttssh2.sourceforge.jp/manual/ja/usage/tips/vim.html
    " http://qiita.com/kefir_/items/c725731d33de4d8fb096
    " let &t_ti = &t_ti . "\e[?6h\e[?69h"
    " let &t_te = "\e[?69l\e[?6l" . &t_te
    " let &t_CV = "\e[%i%p1%d;%p2%ds"
    " let &t_CS = 'y'
  endif
endif

set fileformats=unix,dos,mac
if g:is_windows
  set makeencoding=cp932
endif
if has('guess_encode')
  set fileencodings=guess,ucs-bom,utf-16le,utf-16be,default,latin1
else
  set fileencodings=iso-2022-jp,utf-8,euc-jp,cp932,ucs-bom,utf-16le,utf-16be,default,latin1
endif
set matchpairs& matchpairs+=（:）,｛:｝,「:」,『:』

autocmd MyAutoCmd BufNewFile * set ff=unix
autocmd MyAutoCmd BufWritePre *
      \   if &ff !=# 'unix' && input(printf('Convert fileformat:%s to unix? [y/N]', &ff)) =~? '^y\%[es]$'
      \ |   setlocal ff=unix
      \ | endif
autocmd MyAutoCmd BufReadPost *
      \   if &modifiable && !search('[^\x00-\x7F]', 'cnw')
      \ |   setlocal fenc=ascii
      \ | endif
autocmd MyAutoCmd BufWritePre *
      \   if &modifiable && &bomb && !search('[^\x00-\x7F]', 'cnw')
      \ |   setlocal fenc=ascii
      \ | endif
function! s:checktime() abort
  if bufname('%') !~# '^\%(\|[Command Line]\)$' && &filetype !~# '^\%(help\|qf\)$'
    checktime
  endif
endfunction
autocmd MyAutoCmd WinEnter,FocusGained * call s:checktime()

function! s:map_easy_close() abort
  nnoremap <silent> <buffer> q          :<C-u>q<CR>
  " nnoremap <silent> <buffer> <Esc>      :<C-u>q<CR>
  " nnoremap <silent> <buffer> <Esc><Esc> :<C-u>q<CR>
endfunction
autocmd MyAutoCmd FileType help,qf  call s:map_easy_close()
autocmd MyAutoCmd CmdwinEnter *  call s:map_easy_close()

let s:dict_base_dir = '~/github/VimDict/'
function! s:add_dictionary() abort
  let &l:dictionary .= ','
  execute 'setlocal dictionary+=' . s:dict_base_dir . &filetype . '.txt'
endfunction
autocmd MyAutoCmd Filetype *  call s:add_dictionary()
" }}}

" ------------------------------------------------------------------------------
" Commands and autocmds {{{
" ------------------------------------------------------------------------------
if has('job') && !s:is_nvim
  function! s:system(cmd) abort
    let out = ''
    let job = job_start(a:cmd, {
          \ 'out_cb': {ch, msg -> [execute('let out .= msg'), out]},
          \ 'out_mode': 'raw'
          \})
    while job_status(job) ==# 'run'
      sleep 1m
    endwhile
    return out
  endfunction
else
  function! s:_system(cmd) abort
    try
      let s:system = function('vimproc#cmd#system')
      return s:system(a:cmd)
    catch /^Vim(call)\=:E117: .\+: vimproc#cmd#system$/
      let s:system = function('system')
      return system(a:cmd)
    endtry
  endfunction
  let s:system = function('s:_system')
endif

function! s:redir(cmd) abort
  let [verbose, verbosefile] = [&verbose, &verbosefile]
  set verbose=0 verbosefile=
  redir => str
    execute 'silent!' a:cmd
  redir END
  let [&verbose, &verbosefile] = [verbose, verbosefile]
  return str
endfunction

function! s:retab_head(has_bang, width, line1, line2) abort
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
endfunction
command! -bar -bang -range=% -nargs=?  RetabHead  call s:retab_head(<bang>0, add([<f-args>], &tabstop)[0], <line1>, <line2>)

function! s:toggle_tab_space(has_bang, width, line1, line2) abort
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
endfunction
command! -bar -bang -range=% ToggleTabSpace  call s:toggle_tab_space(<bang>0, &l:tabstop, <line1>, <line2>)
nnoremap <silent> <Leader><Tab>  :<C-u>call <SID>toggle_tab_space(1, &l:tabstop, 1, line('$'))<CR>

function! s:change_indent(has_bang, width) abort
  if a:has_bang
    let [&shiftwidth, &tabstop, &softtabstop] = [a:width, a:width, -1]
  else
    let [&l:shiftwidth, &l:tabstop, &l:softtabstop] = [a:width, a:width, -1]
  endif
endfunction
command! -bang -bar -nargs=1 Indent  call s:change_indent(<bang>0, <q-args>)

function! s:smart_split(cmd) abort
  if winwidth(0) > winheight(0) * 2
    vsplit
  else
    split
  endif
  execute a:cmd
endfunction
command! -bar -nargs=? -complete=command SmartSplit  call <SID>smart_split(<q-args>)
nnoremap <C-w><Space> :<C-u>SmartSplit<CR>

if s:executable('xxd')
  function! s:read_binary() abort
    if !&bin && &filetype !=# 'xxd'
      set binary
      silent %!xxd -g 1
      let b:original_filetype = &filetype
      setfiletype xxd
    endif
  endfunction
  function! s:write_binary() abort
    if &bin && &filetype ==# 'xxd'
      silent %!xxd -r
      write
      silent %!xxd -g 1
      set nomodified
    endif
  endfunction
  function! s:decode_binary() abort
    if &bin && &filetype ==# 'xxd'
      silent %!xxd -r
      set nobinary
      let &filetype = b:original_filetype
      unlet b:original_filetype
    endif
  endfunction
  command! -bar BinaryRead  call s:read_binary()
  command! -bar BinaryWrite  call s:write_binary()
  command! -bar BinaryDecode  call s:decode_binary()
endif


if v:version > 704 || (v:version == 704 && has('patch1738'))
  command! -bar Clear  messages clear
else
  function! s:clear_message() abort
    for i in range(201)
      echomsg ''
    endfor
  endfunction
  command! -bar Clear  call s:clear_message()
endif

function! s:messages_head(has_bang, ...) abort
  let n = a:0 > 0 ? a:1 : 10
  let lines = filter(split(s:redir('messages'), "\n"), 'v:val !=# ""')[: n]
  if a:has_bang
    for line in lines
      echomsg line
    endfor
  else
    for line in lines
      echo line
    endfor
  endif
endfunction
command! -bar -bang -nargs=? MessagesHead  call s:messages_head(<bang>0, <f-args>)

function! s:messages_tail(has_bang, ...) abort
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
endfunction
command! -bar -bang -nargs=? MessagesTail  call s:messages_tail(<bang>0, <f-args>)

" Make directory automatically.
function! s:auto_mkdir(dir, force) abort
  if !isdirectory(a:dir) && (a:force || input(printf('"%s" does not exist. Create? [y/N]', a:dir)) =~? '^y\%[es]$')
    call mkdir(iconv(a:dir, &enc, &tenc), 'p')
  endif
endfunction
autocmd MyAutoCmd BufWritePre * call s:auto_mkdir(expand('<afile>:p:h'), v:cmdbang)

function! Tapi_Drop(bufnum, arglist) abort " {{{
  let [pwd, argv] = [a:arglist[0] . '/', a:arglist[1 :]]
  for arg in map(argv, 'pwd . v:val')
    execute 'drop ' . fnameescape(arg)
  endfor
endfunction " }}}

autocmd MyAutoCmd TerminalOpen *bash*,*zsh* call term_sendkeys(bufnr('%'), join([
      \ 'function vimterm_quote_args() { for a in "$@"; do echo ", \"$a\""; done; }',
      \ 'function vimterm_drop() { echo -e "\e]51;[\"call\", \"Tapi_Drop\", [\"$PWD\" `vimterm_quote_args "$@"`]]\x07"; }',
      \ 'alias vim=vimterm_drop'
      \], "\n") . "\n")


" Command of 'which' for vim command.
function! s:cmd_which(cmd) abort
  if stridx(a:cmd, '/') != -1 || stridx(a:cmd, '\\') != -1
    echoerr a:cmd 'is not a command-name.'
    return
  endif
  let path = substitute(substitute($PATH, '\\', '/', 'g'), ';', ',', 'g')
  let save_suffix_add  = &suffixesadd
  if g:is_windows
    setlocal suffixesadd=.exe,.cmd,.bat
  endif
  let file_list = findfile(a:cmd, path, -1)
  if !empty(file_list)
    echo fnamemodify(file_list[0], ':p')
  else
    echo a:cmd 'was not found.'
  endif
  let &suffixesadd = save_suffix_add
endfunction
command! -bar -nargs=1 Which  call s:cmd_which(<q-args>)


" lcd to buffer-directory.
function! s:cmd_lcd(count) abort
  let dir = expand('%:p' . repeat(':h', a:count + 1))
  if isdirectory(dir)
    execute 'lcd' fnameescape(dir)
  endif
endfunction
command! -bar -nargs=0 -count=0 Lcd  call s:cmd_lcd(<count>)


" Close buffer not closing window
function! s:buf_delete() abort
  let current_bufnr   = bufnr('%')
  let alternate_bufnr = bufnr('#')
  if buflisted(alternate_bufnr)
    buffer #
  else
    bnext
  endif
  if buflisted(current_bufnr)
    execute 'silent bwipeout' current_bufnr
    " If bwipeout is failed, restore buffer of upper windows.
    if bufloaded(current_bufnr) != 0
      execute 'buffer' current_bufnr
    endif
  endif
endfunction
command! -bar Ebd  call s:buf_delete()

" Close buffer not closing window
function! s:bwipeout_all(bang, ...) abort
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
endfunction
command! -bar -bang -nargs=* -complete=buffer BwipeoutAll  call s:bwipeout_all('<bang>', <f-args>)
command! -bar -bang BwipeoutAllNoname  call s:bwipeout_all('<bang>', '')

" Preview fold area.
function! s:preview_fold(previewheight) abort
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
endfunction
nnoremap <silent> zp  :<C-u>call <SID>preview_fold(&previewheight)<CR>


if s:executable('chmod')
  augroup Permission
    autocmd!
    autocmd BufNewFile * autocmd Permission BufWritePost <buffer>  call s:permission_644()
  augroup END
  function! s:permission_644() abort
    autocmd! Permission BufWritePost <buffer>
    silent call s:system((stridx(getline(1), '#!') ? 'chmod 644 ' : 'chmod 755 ') . shellescape(expand('%')))
  endfunction
elseif s:executable('icacls')
  augroup Permission
    autocmd!
    autocmd BufNewFile * autocmd Permission BufWritePost <buffer>  call s:permission_644()
  augroup END
  function! s:permission_644() abort
    let user = hostname() . '\' . expand('$USERNAME')
    let icacls_cmd = 'icacls ' . expand('%') . ' /inheritance:r /grant:r '
    autocmd! Permission BufWritePost <buffer>
    if stridx(getline(1), '#!')
      silent call s:system(icacls_cmd . user . ':RW')
      silent call s:system(icacls_cmd . 'everyone:R')
    else
      silent call s:system(icacls_cmd . user . ':F')
      silent call s:system(icacls_cmd . 'everyone:RX')
    endif
  endfunction
endif

function! s:get_selected_text() abort
  let tmp = @@
  silent normal! gv"zy
  let [text, @@] = [@@, tmp]
  return text
endfunction

" Execute selected text as a vimscript
function! s:exec_selected_text() abort
  execute s:get_selected_text()
endfunction
xnoremap <silent> <Leader>e  :<C-u>call <SID>exec_selected_text()<CR>

" Generate match pattern for selected text.
" @*: clipboard  @@: anonymous buffer
" mode == 0 : magic, mode == 1 : nomagic, mode == 2 : verymagic
function! s:store_selected_text(...) abort
  let mode = a:0 > 0 ? a:1 : !&magic
  let selected = substitute(escape(s:get_selected_text(),
        \ mode == 2 ? '^$[]/\.*~(){}<>?+=@|%&' :
        \ mode == 1 ? '^$[]/\' :
        \ '^$[]/\.*~'), "\n", '\\n', 'g')
  silent! let @* = selected
  silent! let @0 = selected
endfunction
xnoremap ,r  :<C-u>call <SID>store_selected_text()<CR>:<C-u>.,$s/<C-r>"//gc<Left><Left><Left>
xnoremap ,R  :<C-u>call <SID>store_selected_text(0)<CR>:<C-u>.,$s/\M<C-r>"//gc<Left><Left><Left>
xnoremap ,<C-r>  :<C-u>call <SID>store_selected_text(1)<CR>:<C-u>.,$s/\M<C-r>"//gc<Left><Left><Left>
xnoremap ,<M-r>  :<C-u>call <SID>store_selected_text(2)<CR>:<C-u>.,$s/\M<C-r>"//gc<Left><Left><Left>
xnoremap ,s  :<C-u>call <SID>store_selected_text()<CR>/<C-u><C-r>"<CR>N
xnoremap ,S  :<C-u>call <SID>store_selected_text(0)<CR>/<C-u>\m<C-r>"<CR>N
xnoremap ,<C-s>  :<C-u>call <SID>store_selected_text(1)<CR>/<C-u>\M<C-r>"<CR>N
xnoremap ,<M-s>  :<C-u>call <SID>store_selected_text(2)<CR>/<C-u>\v<C-r>"<CR>N
" function! s:easy_vimgrep(...) abort
"   let text = s:get_selected_text()
"   return 'vimgrep /' . text . '/ *.c' . repeat("\<Left>", 6)
" endfunction
" xnoremap <expr> ,g  <SID>easy_vimgrep()
xnoremap ,g  :<C-u>call <SID>store_selected_text()<CR>:<C-u>vimgrep/<C-r>"/ **/*<Left><Left><Left><Left><Left><Left>

" Complete HTML tag
function! s:complete_tag() abort
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
endfunction
nnoremap <silent> <M-p>  :<C-u>call <SID>complete_tag()<CR>
inoremap <silent> <M-p>  <Esc>:call <SID>complete_tag()<CR>
autocmd Filetype ant,html,xml  inoremap <buffer> </     </<C-x><C-o>
autocmd Filetype ant,html,xml  inoremap <buffer> <M-a>  </<C-x><C-o>
autocmd Filetype ant,html,xml  inoremap <buffer> <M-i>  </<C-x><C-o><Esc>%i


function! s:difforig() abort
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
endfunction
command! -bar DiffOrig  call s:difforig()


function! s:vimdiff_in_newtab(...) abort
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
endfunction
command! -bar -nargs=+ -complete=file Diff  call s:vimdiff_in_newtab(<f-args>)


function! s:compare(...) abort
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
endfunction
command! -bar -nargs=+ -complete=file Compare  call s:compare(<f-args>)

" Highlight cursor position vertically and horizontally.
command! -bar ToggleCursorHighlight
      \   if !&cursorline || !&cursorcolumn || &colorcolumn ==# ''
      \ |   set   cursorline   cursorcolumn
      \ | else
      \ |   set nocursorline nocursorcolumn
      \ | endif
nnoremap <silent> <Leader>h  :<C-u>ToggleCursorHighlight<CR>
autocmd MyAutoCmd CursorHold,CursorHoldI,WinEnter *  set cursorline cursorcolumn
autocmd MyAutoCmd CursorMoved,CursorMovedI,WinLeave *  set nocursorline nocursorcolumn

" Search in selected texts
function! s:range_search(d) abort
  let s = input(a:d)
  if strlen(s) > 0
    let s = a:d . '\%V' . s . "\<CR>"
    call feedkeys(s, 'n')
  endif
endfunction
vnoremap <silent>/  :<C-u>call <SID>range_search('/')<CR>
vnoremap <silent>?  :<C-u>call <SID>range_search('?')<CR>


function! s:speed_up(has_bang) abort
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
      if g:is_windows
        set transparency=255
      else
        set transparency=0
      endif
    endif
  endif
endfunction
command! -bang -bar SpeedUp  call s:speed_up(<bang>0)


function! s:comma_period(line1, line2) abort range
  let cursor = getcurpos()
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 's/、/，/ge'
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 's/。/．/ge'
  call setpos('.', cursor)
endfunction
command! -bar -range=% CommaPeriod  call s:comma_period(<line1>, <line2>)


function! s:kutouten(line1, line2) abort range
  let cursor = getcurpos()
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 's/，/、/ge'
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 's/．/。/ge'
  call setpos('.', cursor)
endfunction
command! -bar -range=% Kutouten  call s:kutouten(<line1>, <line2>)

function! s:devide_sentence(line1, line2) abort range
  let cursor = getcurpos()
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 's/\.\zs[ \n]/\r\r/ge'
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 's/[。．]\zs\n\?/\r\r/ge'
  call setpos('.', cursor)
endfunction
command! -bar -range=% DevideSentence  call s:devide_sentence(<line1>, <line2>)

function! s:make_junk_buffer(has_bang) abort
  if a:has_bang
    edit __JUNK_BUFFER__
    setlocal nobuflisted bufhidden=unload buftype=nofile
  else
    edit __JUNK_BUFFER_RECYCLE__
    setlocal nobuflisted buftype=nofile
  endif
endfunction
command! -bang -bar JunkBuffer  call s:make_junk_buffer(<bang>0)

function! s:delete_match_pattern(pattern, line1, line2) abort
  let cursor = getcurpos()
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 's/' . a:pattern . '//ge'
  call setpos('.', cursor)
endfunction
command! -bar -range=% DeleteTrailingWhitespace  call s:delete_match_pattern('\s\+$', <line1>, <line2>)
command! -bar -range=% DeleteTrailingCR  call s:delete_match_pattern('\r$', <line1>, <line2>)

function! s:delete_blank_lines(line1, line2) abort range
  let cursor = getcurpos()
  let offset = 0
  execute 'silent keepjumps keeppatterns' a:line1 ',' cursor[1] 'g /^\s*$/let offset += 1'
  let cursor[1] -= offset
  execute 'silent keepjumps keeppatterns' a:line1 ',' a:line2 'g /^\s*$/d'
  call setpos('.', cursor)
endfunction
command! -bar -range=% DeleteBlankLines  call s:delete_blank_lines(<line1>, <line2>)

function! s:show_file_size() abort
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
endfunction
command! -bar ShowFileSize  call s:show_file_size()

function! s:clear_undo() abort
  let save_undolevels = &l:undolevels
  setlocal undolevels=-1
  execute "normal! a \<BS>\<Esc>"
  setlocal nomodified
  let &l:undolevels = save_undolevels
endfunction
command! -bar ClearUndo  call s:clear_undo()

function! s:make_viml_foldings(line1, line2) abort
  let cursor = getcurpos()
  " {{{ {{{
  execute 'keepjumps keeppatterns' a:line1 ',' a:line2 's/^\s*\%(endfunction\|endfunctio\|endfuncti\|endfunct\|endfunc\|endfun\|endfu\|endf\)\%([a-z]\)\@!\zs\%(\s*".*}}}\)\@!/ " }}}/ce'
  execute 'keepjumps keeppatterns' a:line1 ',' a:line2 's/^\s*\%(function\|functio\|functi\|funct\|func\|fun\|fu\)\%([a-z]\)\@!!\?\s\+[a-zA-Z\.:_#{}]\+(.*)\%(\s\+\%(abort\|dict\|range\)\)*\zs\%(\%(\s\+\%(abort\|dict\|range\)\)*\s*".*{{{\)\@!/ " {{{/ce'
  " }}} }}}
  call setpos('.', cursor)
endfunction
command! -bar -range=% MakeVimLFoldings  call s:make_viml_foldings(<line1>, <line2>)

" Save as a super user.
if s:executable('sudo') && s:executable('tee')
  function! s:save_as_root(bang, filename) abort
    execute 'write' a:bang '!sudo tee > /dev/null' (a:filename ==# '' ? '%' : a:filename)
  endfunction
else
  function! s:save_as_root(bang, filename) abort
    echoerr 'sudo is not supported in this environment.'
  endfunction
endif
command! -bar -bang -nargs=? -complete=file Write  call s:save_as_root('<bang>', <q-args>)


if s:executable('jq')
  function! s:jq(has_bang, ...) abort range
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
    call s:clear_undo()
    setlocal readonly
  endfunction
  command! -bar -bang -range=% -nargs=? Jq  <line1>,<line2>call s:jq(<bang>0, <f-args>)
endif


if s:executable('indent')
  let s:indent_cmd = 'indent -orig -bad -bap -nbbb -nbbo -nbc -bli0 -br -brs -nbs
        \ -c8 -cbiSHIFTWIDTH -cd8 -cdb -cdw -ce -ciSHIFTWIDTH -cliSHIFTWIDTH -cp2 -cs
        \ -d0 -nbfda -nbfde -di0 -nfc1 -nfca -hnl -iSHIFTWIDTH -ipSHIFTWIDTH
        \ -nlp -lps -npcs -piSHIFTWIDTH -nprs -psl -saf -sai -saw -sbi0
        \ -sc -nsob -nss -tsSOFTTABSTOP -ppiSHIFTWIDTH -ip0 -l160 -lc160'
  function! s:format_c_program(has_bang) abort range
    let indent_cmd = substitute(s:indent_cmd, 'SHIFTWIDTH', &shiftwidth, 'g')
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
    call s:clear_undo()
    setlocal readonly
  endfunction
  autocmd MyAutoCmd FileType c,cpp
        \ command! -bar -bang -range=% -buffer FormatCProgram
        \ <line1>,<line2>call s:format_c_program(<bang>0)
endif


if s:executable('pdftotext')
  function! s:pdftotext(file) abort
    new
    execute '0read !pdftotext -nopgbrk -layout' a:file '-'
    " execute '0read !pdftotext -nopgbrk' a:file '-'
    call s:clear_undo()
  endfunction
  command! -bar -complete=file -nargs=1 Pdf  call s:pdftotext(<q-args>)
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

function! s:show_tab_info() abort " {{{
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
command! -bar TabInfo call s:show_tab_info()

if exists('*win_gotoid')
  function! s:buf_open_existing(bname, ...) abort " {{{
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
  command! -bar -nargs=1 -complete=buffer Buffer  call s:buf_open_existing(<f-args>, <q-mods>)
else
  function! s:buf_open_existing(bname) abort " {{{
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
  command! -bar -nargs=1 -complete=buffer Buffer  call s:buf_open_existing(<f-args>)
endif

if has('terminal')
  function! s:complete_term_bufname(arglead, cmdline, cursorpos) abort " {{{
    let arglead = tolower(a:arglead)
    return filter(map(term_list(), 'bufname(v:val)'), '!stridx(tolower(v:val), arglead)')
  endfunction " }}}

  function! s:term_open_existing(qmods, ...) abort " {{{
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
  command! -bar -nargs=? -complete=customlist,s:complete_term_bufname Terminal  call s:term_open_existing(<q-mods>, <f-args>)
endif


function! s:show_highlight_info(lnum, col) abort " {{{
  for synid in synstack(a:lnum, a:col)
    let hldef_dict = s:generate_hldef_dict({}, synid)
    let name = synIDattr(synid, 'name')
    echo name
    while has_key(hldef_dict[name], 'link')
      let name2 = hldef_dict[name].link
      echo printf('  highlight! link %s %s', name, name2)
      let name = name2
    endwhile
    if has_key(hldef_dict[name], 'def')
      echo printf('  ' . hldef_dict[name].def)
    endif
  endfor
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

command! -bar ShowHlGroup  call s:show_highlight_info(line('.'), col('.'))

" by ujihisa
command! -count=1 -nargs=0 GoToTheLine  silent execute getpos('.')[1][: -len(v:count) - 1] . v:count
nnoremap <silent> gl  :<C-u>GoToTheLine<CR>

" Show highlight group name under a cursor
command! -bar ShowRuntimePath  echo join(split(&runtimepath, ','), "\n")
command! -bar Rot13  normal! mzggg?G`z
command! -bar RandomString  echo sha256(reltimestr(reltime()))[: 7]
command! -nargs=1 GrepCurrent  vimgrep <args> % | cwindow
" Reopen current file with another encoding.
command! -bar -bang Utf8       edit<bang> ++enc=utf-8
command! -bar -bang Iso2022jp  edit<bang> ++enc=iso-2022-jp
command! -bar -bang Cp932      edit<bang> ++enc=cp932
command! -bar -bang Euc        edit<bang> ++enc=euc-jp
command! -bar -bang Utf16      edit<bang> ++enc=ucs-2le
command! -bar -bang Utf16be    edit<bang> ++enc=ucs-2
" File encoding commands.
command! -bar FUtf8       setlocal fenc=utf-8
command! -bar FIso2022jp  setlocal fenc=iso-2022-jp
command! -bar FCp932      setlocal fenc=cp932
command! -bar FEuc        setlocal fenc=euc-jp
command! -bar FUtf16      setlocal fenc=ucs-2le
command! -bar FUtf16be    setlocal fenc=ucs-2

command! -bar -nargs=1 -complete=file Rename  file <args> | call delete(expand('#'))
command! -bar CloneToNewTab  execute 'tabnew' expand('%:p')
command! -bar TabNew  tabnew | setlocal nobuflisted bufhidden=unload buftype=nofile
command! -bar -nargs=1 -complete=file E  tabedit <args>
command! -bar Q  tabclose <args>
command! -bar GC  call garbagecollect()

function! s:plugin_test(use_gvim, ex_command, is_same_window) abort
  let cmd = escape((a:use_gvim ? 'gvim' : 'vim')
        \ . ' -u ~/.vim/min.vim'
        \ . ' -U NONE'
        \ . ' -i NONE'
        \ . ' -n'
        \ . ' -N'
        \ . printf(' --cmd "set rtp+=%s"', getcwd())
        \ . (a:ex_command ==# '' ? '' : printf('-c "au VimEnter * %s"', a:ex_command)), '!')
  if g:is_windows
    execute 'silent' (a:use_gvim ? '!start'
          \ : a:is_same_window ? '!'
          \ : '!start cmd /c call') cmd
  else
    execute 'silent !' cmd
    redraw!
  endif
endfunction
command! -bar -bang -nargs=* PluginTest  call s:plugin_test(<bang>0, <q-args>, 0)
command! -bar -bang -nargs=* PluginTestCUI  call s:plugin_test(0, <q-args>, 0)
command! -bar -bang -nargs=* PluginTestGUI  call s:plugin_test(1, <q-args>, 0)
if s:is_cui && g:is_windows
  command! -bar -bang -nargs=* PluginTestCUISameWindow  call s:plugin_test(0, <q-args>, 1)
endif

" {{{ VimLint
" http://kannokanno.hatenablog.com/entry/20120726/1343321506
function! s:vimlint(file) abort
  unlet! g:__func_lnums__
  try
    call setqflist(s:vimlint_qflist(a:file), 'r')
    cwindow
    silent! doautocmd QuickFixCmdPost make
  finally
    unlet! g:__func_lnums__
  endtry
endfunction

function! s:vimlint_qflist(file) abort
  let srclines = readfile(a:file, 'b')
  let qflist = []
  let start_pos = 0
  let relative_num = 0
  for l in s:vimlint_source(s:vimlint_hook_file(srclines))
    " ex) function <SNR>175_hoge の処理中にエラーが検出されました:
    if l =~ '^function'
      let start_pos = s:vimlint_func_define_linenum(srclines, l)
    "ex) 行    1:
    elseif l =~ '^\%(line\|行\)'
      let relative_num = matchstr(l, '\%(line\|行\)\s*\zs\d*\ze')
    "ex) E492: エディタのコマンドではありません:   et s:str = ''
    elseif l =~ '^E'
      call add(qflist, {
            \ 'filename': a:file,
            \ 'lnum': start_pos + relative_num,
            \ 'text': l
            \})
      let [start_pos, relative_num] = [0, 0]
    endif
  endfor
  return qflist
endfunction

function! s:vimlint_hook_file(srclines) abort
  let tempfile = tempname()
  call writefile(extend(a:srclines, s:vimlint_hook_lines()), tempfile, 'b')
  return tempfile
endfunction

function! s:vimlint_source(file) abort
  let tempfile = tempname()
  let save_verbosefile = &verbosefile
  let &verbosefile = tempfile
  try
    silent! execute 'source' a:file
  finally
    if &verbosefile ==# tempfile
      let &verbosefile = save_verbosefile
    endif
  endtry
  let messages = ''
  if filereadable(tempfile)
    let messages .= join(readfile(tempfile, 'b'), "\n")
    call delete(tempfile)
  endif
  return split(messages, "\n")
endfunction

function! s:vimlint_func_define_linenum(srclines, line) abort
  let funcname = a:line =~# '<SNR>' ? matchstr(a:line, '<SNR>\d*_\zs.*\ze\s') : matchstr(a:line, 'function\s\zs\d*\ze\s')
  return exists('g:__func_lnums__') ? get(g:__func_lnums__, funcname, 0) : 0
endfunction

function! s:vimlint_hook_lines() abort
  return [
        \ 'function! s:vimlint_func_lnums(file) abort',
        \ '  let func_lnum = {}',
        \ '  let lines = readfile(a:file)',
        \ '  for i in range(0, len(lines)-1)',
        \ '    let l = lines[i]',
        \ '    let func_define = s:vimlint_func_define_line(matchstr(l, ''function!\s*\zs.*\ze(''))',
        \ '    if !empty(func_define)',
        \ '      let simplename = func_define =~ ''<SNR>''',
        \ '            \ ? matchstr(func_define, ''<SNR>\d*_\zs.*\ze('')',
        \ '            \ : matchstr(func_define, ''.*\s\zs\d*\ze('')',
        \ '      if !empty(simplename)',
        \ '        let func_lnum[simplename] = i + 1',
        \ '      endif',
        \ '    endif',
        \ '  endfor',
        \ '  return func_lnum',
        \ 'endfunction',
        \ 'function! s:vimlint_func_define_line(funcname) abort',
        \ '  let tempfile = tempname()',
        \ '  let save_verbosefile = &verbosefile',
        \ '  let &verbosefile = tempfile',
        \ '  try',
        \ '    silent! execute ''function '' . a:funcname',
        \ '  finally',
        \ '    if &verbosefile ==# tempfile',
        \ '      let &verbosefile = save_verbosefile',
        \ '    endif',
        \ '  endtry',
        \ '  let messages = ''''',
        \ '  if filereadable(tempfile)',
        \ '    let messages .= join(readfile(tempfile, ''b''), "\n")',
        \ '    call delete(tempfile)',
        \ '  endif',
        \ '  return split(messages, "\n")[0]',
        \ 'endfunction',
        \ 'let g:__func_lnums__ = s:vimlint_func_lnums(expand("%"))'
        \]
endfunction
command! -bar -nargs=1 VimLint  call s:vimlint(expand(<q-args>))
" }}}


" Joke!
if has('cryptv')
  function! s:destroy_file(has_bang) abort
    if !filereadable(expand('%:p'))
      echoerr 'Current buffer is not write out to file'
      return
    endif
    if !a:has_bang
      echoerr "Must to add '!' to destroy this file"
      return
    endif
    let cursor = getcurpos()
    normal! ggg?G
    call setpos('.', cursor)
    let &key = sha256(reltimestr(reltime()))
    write
    bwipeout
  endfunction
  command! -bar -bang DestroyFile  call s:destroy_file(<bang>0)
endif

if s:executable('tasklist')
  if g:is_windows
    function! s:show_memory_usage() abort
      let ret = s:system('tasklist /NH /FI "PID eq ' . getpid() . '"')
      echomsg split(ret, ' \+')[4] 'KB'
    endfunction
  elseif g:is_cygwin
    function! s:show_memory_usage() abort
      let ret = s:system('tasklist /NH /FI "PID eq ' . s:pid2winpid(getpid()) . '"')
      echomsg split(ret, ' \+')[4] 'KB'
    endfunction
    function! s:pid2winpid(pid) abort
      let ret = split(s:system('ps -p ' . a:pid), "\n")
      if len(ret) < 2
        echoerr 'Specified pid:' a:pid 'is not exsits'
      else
        return split(ret[1][1 :], ' \+')[3]
      endif
    endfunction
  else
    function! s:show_memory_usage() abort
      echomsg 'Cannot available this command'
    endfunction
  endif
elseif s:executable('ps')
  function! s:show_memory_usage() abort
    echomsg split(split(s:system('ps u -p ' . getpid()), "\n")[1], ' \+')[5] 'KB'
  endfunction
else
  function! s:show_memory_usage() abort
    echomsg 'Cannot available this command'
  endfunction
endif
command! -bar -bang ShowMemoryUsage  call s:show_memory_usage()

if g:is_windows && s:executable('taskkill')
  command! -bar Suicide  call s:system('taskkill /pid ' . getpid())
elseif s:executable('kill')
  command! -bar Suicide  call s:system('kill -KILL '. getpid())
endif
" }}}

" ------------------------------------------------------------------------------
" Setting for Visualize {{{
" ------------------------------------------------------------------------------
if has('kaoriya')
  set ambiwidth=auto
else
  set ambiwidth=double
endif
" Show invisible characters and define format of the characters.
" Windows CUI (Command prompt) cannot recognize special characters.
" So write a configuration for Windows-CUI and return from this function
" before a configuration for other environment.
function! s:set_listchars() abort
  if &enc !=# 'utf-8'
    set list listchars=eol:$,extends:>,nbsp:%,precedes:<,tab:\|\ ,trail:-
    set showbreak=>
    return
  else
    set list listchars=eol:$,extends:»,nbsp:%,precedes:«,tab:¦\ ,trail:-
    set showbreak=»
  endif
endfunction
call s:set_listchars()
delfunction s:set_listchars

function! s:matchadd(group, pattern, ...) abort
  if index(map(getmatches(), 'v:val.group'), a:group) != -1 || expand('%:h:t') ==# 'doc' || &filetype ==# 'help'
    return
  endif
  call call('matchadd', extend([a:group, a:pattern], a:000))
endfunction
function! s:matchdelete(groups) abort
  let groups = type(a:groups) == type('') ? [a:groups] : a:groups
  for group in groups
    let matches = getmatches()
    let idx = index(map(copy(matches), 'v:val.group'), group)
    if idx != -1
      call matchdelete(matches[idx].id)
    endif
  endfor
endfunction

augroup MyAutoCmd
  " TODO
  au ColorScheme * hi WhitespaceEOL term=underline ctermbg=Blue guibg=Blue
  au VimEnter,WinEnter,BufRead * call s:matchadd('WhitespaceEOL', ' \+$')
  " au VimEnter,WinEnter,BufRead * match WhitespaceEOL / \+$/

  au ColorScheme * hi TabEOL term=underline ctermbg=DarkGreen guibg=DarkGreen
  au VimEnter,WinEnter,BufRead * call s:matchadd('TabEOL', '\t\+$')
  " au VimEnter,WinEnter,BufRead * match TabEOL /\t\+$/

  au ColorScheme * hi SpaceTab term=underline ctermbg=Magenta guibg=Magenta guisp=Magenta
  au VimEnter,WinEnter,BufRead * call s:matchadd('SpaceTab', ' \+\ze\t\|\t\+\ze ')
  " au VimEnter,WinEnter,BufRead * match SpaceTab / \+\ze\t\|\t\+\ze /

  au Colorscheme * hi JPSpace term=underline ctermbg=Red guibg=Red
  au VimEnter,WinEnter,BufRead * call s:matchadd('JPSpace', '　')  " \%u3000
  " au VimEnter,WinEnter,BufRead * match JPSpace /　/

  au Filetype {help,vimshell,presen,rogue,showtime} call s:matchdelete(['WhitespaceEOL', 'TabEOL', 'SpaceTab'])
augroup END
" }}}

" ------------------------------------------------------------------------------
" Setting for languages. {{{
" ------------------------------------------------------------------------------
let g:c_gnu = 1  " Enable highlight gnu-C keyword in C-mode.
augroup MyAutoCmd
  " ----------------------------------------------------------------------------
  " Setting for indent.
  " ----------------------------------------------------------------------------
  au Filetype awk        setlocal                      cindent cinkeys-=0#
  au Filetype c          setlocal                      cindent cinoptions& cinoptions+=g0,l0,N-s,t0 cinkeys-=0#
  au Filetype cpp        setlocal                      cindent cinoptions& cinoptions+=g0,j1,l0,N-s,t0,ws,Ws,(0 cinkeys-=0#
  " )
  au Filetype cs         setlocal sw=4 ts=4 sts=4 et
  au Filetype java       setlocal sw=4 ts=4 sts=4 noet cindent cinoptions& cinoptions+=j1
  au Filetype javascript setlocal sw=2 ts=2 sts=2      cindent cinoptions& cinoptions+=j1,J1,(s
  " )
  au Filetype make       setlocal sw=4 ts=4 sts=4
  au Filetype kuin       setlocal sw=2 ts=2 sts=2 noet
  au Filetype python     setlocal sw=4 ts=8 sts=4      cindent cinkeys-=0#
  au Filetype make       setlocal sw=4 ts=4 sts=4 noet
  au Filetype markdown   setlocal sw=4 ts=4 sts=4
  au Filetype tex        setlocal sw=2 ts=2 sts=2 conceallevel=0
augroup END
" }}}

" ------------------------------------------------------------------------------
" Keybinds {{{
" ------------------------------------------------------------------------------
" For terminal
if !g:is_windows && s:is_cui
  " Use meta keys in console.
  " <ESC>O do not map because used by arrow keys.
  for s:ch in map(
        \   range(char2nr('%'), char2nr('?'))
        \ + range(char2nr('A'), char2nr('N'))
        \ + range(char2nr('P'), char2nr('Z'))
        \ + range(char2nr('a'), char2nr('z'))
        \ , 'nr2char(v:val)')
    execute 'map  <ESC>' . s:ch '<M-' . s:ch . '>'
    execute 'cmap <ESC>' . s:ch '<M-' . s:ch . '>'
  endfor
  unlet s:ch
  map  <NUL>  <C-Space>
  map! <NUL>  <C-Space>
endif
if g:is_mac
  noremap  ¥  \
  noremap! ¥  \
  noremap  \  ¥
  noremap! \  ¥
endif

nnoremap <C-c> <C-c>
" Use black hole register.
nnoremap c  "_c
nnoremap x  "_x
nnoremap Q  gQ
nnoremap gQ  Q
" Keep the cursor in place while joining lines
nnoremap <M-j>  mzJ`z:delmarks z<CR>
" Delete search register
" nnoremap <silent> <Esc><Esc>    :<C-u>let @/= ''<CR>
nnoremap <silent> <Esc><Esc>    :<C-u>nohlsearch<CR>
nnoremap <silent> <Space><Esc>  :<C-u>setlocal hlsearch! hlsearch?<CR>
" Search the word nearest to the cursor in new window.
nnoremap <C-w>*  <C-w>s*
nnoremap <C-w>#  <C-w>s#
" Move line to line as you see whenever wordwrap is set.
nnoremap j   gj
nnoremap k   gk
nnoremap gj   j
nnoremap gk   k
" Tag jump
nnoremap <C-]>   g<C-]>zz
nnoremap g<C-]>  <C-]>zz
nnoremap <M-]>   :<C-u>tag<CR>
nnoremap <M-[>   :<C-u>pop<CR>
" For moveing between argument list
nnoremap [a  :<C-u>previous<CR>
nnoremap ]a  :<C-u>next<CR>
nnoremap [A  :<C-u>first<CR>
nnoremap ]A  :<C-u>last<CR>
" For moveing between buffers
nnoremap [b  :<C-u>bprevious<CR>
nnoremap ]b  :<C-u>bnext<CR>
nnoremap [B  :<C-u>bfirst<CR>
nnoremap ]B  :<C-u>blast<CR>
" For moveing between buffers
nnoremap [l  :<C-u>lprevious<CR>
nnoremap ]l  :<C-u>lnext<CR>
nnoremap [L  :<C-u>lfirst<CR>
nnoremap ]L  :<C-u>llast<CR>
" For vimgrep
nnoremap [q  :<C-u>cprevious<CR>
nnoremap ]q  :<C-u>cnext<CR>
nnoremap [Q  :<C-u>cfirst<CR>
nnoremap ]Q  :<C-u>clast<CR>
" For moveing between tag list
nnoremap [t  :<C-u>tprevious<CR>
nnoremap ]t  :<C-u>tnext<CR>
nnoremap [T  :<C-u>tfirst<CR>
nnoremap ]T  :<C-u>tlast<CR>
" Paste at start of line.
" nnoremap <C-p>  I<C-r>"<Esc>
" Toggle relativenumber.
"""""" if v:version >= 703
nnoremap <silent> <Leader>l  :<C-u>setlocal rnu! rnu?<CR>
"""""" endif
nnoremap <silent> <Leader>s  :<C-u>setlocal spell! spell?<CR>
nnoremap <silent> <Leader>w  :<C-u>setlocal wrap!  wrap?<CR>
" Resize window.
nnoremap <silent> <M-<>  <C-w><
nnoremap <silent> <M-+>  <C-w>+
nnoremap <silent> <M-->  <C-w>-
nnoremap <silent> <M-=>  <C-w>-
nnoremap <silent> <M->>  <C-w>>

" Change tab.
nnoremap <C-Tab>    gt
nnoremap <S-C-Tab>  Gt
" Show marks.
nnoremap <Space>m  :<C-u>marks<CR>
" Show ascii-code of charactor under cursor.
nnoremap <Space>@  :<C-u>ascii<CR>
" Show registers
nnoremap <Space>r  :<C-u>registers<CR>
nnoremap <Leader>/  /<C-u>\<\><Left><Left>
" Repeat last substitution, including flags, with &.
nnoremap &  :<C-u>&&<CR>

function! s:hint_cmd_output(prefix, cmd) abort " {{{
  redir => str
    execute a:cmd
  redir END
  let more_old = &more
  set nomore
  echo str
  let &more = more_old
  return a:prefix . nr2char(getchar())
endfunction " }}}
nnoremap <expr> m  <SID>hint_cmd_output('m', 'marks')
nnoremap <expr> `  <SID>hint_cmd_output('`', 'marks') . 'zz'
nnoremap <expr> '  <SID>hint_cmd_output("'", 'marks') . 'zz'
nnoremap <expr> "  <SID>hint_cmd_output('"', 'registers')
if exists('*reg_recording')
  nnoremap <expr> q  reg_recording() ==# '' ? <SID>hint_cmd_output('q', 'registers') : 'q'
else
  nnoremap <expr> q  <SID>hint_cmd_output('q', 'registers')
endif
nnoremap <expr> @  <SID>hint_cmd_output('@', 'registers')

au MyAutoCmd Filetype html nnoremap <buffer> <F5>  :<C-u>lcd %:h<CR>:<C-u>silent !start cmd /c call chrome %<CR>

inoremap <C-c>  <C-c>u
" Move to indented position.
inoremap <C-A>  a<Esc>==xa
" Cursor-move setting at insert-mode.
inoremap <M-h>  <Left>
inoremap <M-j>  <Down>
inoremap <M-k>  <Up>
inoremap <M-l>  <Right>
" Like Emacs.
inoremap <C-f>  <Right>
inoremap <C-b>  <Left>
inoremap <silent> <C-d>  <Del>
inoremap <silent> <C-e>  <Esc>$a
" Insert a blank line in insert mode.
inoremap <C-o>  <Esc>o
" During insert, ctrl-u will break undo sequence then delete all entered chars
inoremap <C-u> <C-g>u<C-u>
" Easy <Esc> in insert-mode.
" inoremap jj  <Esc>
inoremap <expr> j  getline('.')[col('.') - 2] ==# 'j' ? "\<BS>\<ESC>" : 'j'
" No wait for <Esc>.
if g:is_unix && s:is_cui
  inoremap <silent> <ESC>  <ESC>
endif

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
function! s:hint_i_ctrl_x() abort " {{{
  let more_old = &more
  set nomore
  echo s:hint_i_ctrl_x_msg
  let &more = more_old
  let c = getchar()
  return get(s:compl_key_dict, c, nr2char(c))
endfunction " }}}

inoremap <expr> <C-x>  <SID>hint_i_ctrl_x()


" Cursor-move setting at insert-mode.
cnoremap <M-h>  <Left>
cnoremap <M-j>  <Down>
cnoremap <M-k>  <Up>
cnoremap <M-l>  <Right>
cnoremap <M-H>  <Home>
cnoremap <M-L>  <End>
cnoremap <M-w>  <S-Right>
cnoremap <M-b>  <S-Left>
cnoremap <M-x>  <Del>
cnoremap <C-a>  <Home>
cnoremap <C-b>  <Left>
cnoremap <C-d>  <Del>
cnoremap <C-e>  <End>
cnoremap <C-f>  <Right>
" cnoremap <C-n>  <Down>
" cnoremap <C-p>  <Up>
" cnoremap <M-b>  <S-Left>
" cnoremap <M-f>  <S-Right>
cnoremap <C-p>  <Up>
cnoremap <C-n>  <Down>
" Paste from anonymous buffer
" cnoremap <M-p>  <C-r><S-">
cnoremap <M-p>  <C-r>+
" Add excape to '/' and '?' automatically.
cnoremap <expr> /  getcmdtype() == '/' ? '\/' : '/'
cnoremap <expr> ?  getcmdtype() == '?' ? '\?' : '?'
" Input full-path of the current file directory
cnoremap <expr> %%  getcmdtype() == ':' ? expand('%:h') . '/' : '%%'



" Select paren easly
onoremap )  f)
onoremap (  t(


xnoremap )  f)
xnoremap (  t(
" Reselect visual block after indent.
xnoremap <  <gv
xnoremap >  >gv
" Select current position to EOL.
xnoremap v  $<Left>
" Paste yanked string vertically.
xnoremap <C-p>  I<C-r>"<ESC>
" Search selected text in new window.
xnoremap <C-w>*  y<C-w>s/<C-r>0<CR>N
xnoremap <C-w>:  y<C-w>v/<C-r>0<CR>N

if v:version > 704 || (v:version == 704 && has('patch754'))
  if g:is_windows
    silent! xunmap <C-v>
  endif
  xnoremap <C-a> <C-a>gv
  xnoremap <C-x> <C-x>gv
endif
" Repeat last substitution, including flags, with &.
xnoremap &  :<C-u>&&<CR>
" Sequencial copy
vnoremap <silent> <M-p>  "0p


noremap  <silent> <F2>  :<C-u>VimFiler<CR>
noremap! <silent> <F2>  <Esc>:VimFiler<CR>

noremap  <silent> <F3>  :<C-u>MiniBufExplore<CR>
noremap! <silent> <F3>  <Esc>:MiniBufExplore<CR>

noremap  <silent> <F4>  :<C-u>VimShell<CR>
noremap! <silent> <F4>  <Esc>:VimShell<CR>
" noremap  <silent> <F4>  :<C-u>call tmpwin#toggle('VimShell')<CR>
" noremap! <silent> <F4>  <Esc>:call tmpwin#toggle('VimShell')<CR>

noremap  <silent> <F5>  :<C-u>HierStart<CR>:<C-u>QuickRun<CR>
noremap! <silent> <F5>  <Esc>:HierStart<CR>:<C-u>QuickRun<CR>

noremap  <silent> <S-F5>  :<C-u>sp +enew<CR>:<C-u> r !make<CR>
noremap! <silent> <S-F5>  <Esc>:sp +enew<CR>:<C-u> r !make<CR>

" Open .vimrc
nnoremap  <silent> <Space>c  :<C-u>edit $MYVIMRC<CR>
" Open .gvimrc
nnoremap  <silent> <Space>g  :<C-u>edit $MYGVIMRC<CR>
if s:is_cui
  " Reload .vimrc.
  noremap  <silent> <F12> :<C-u>source $MYVIMRC<CR>
  noremap! <silent> <F12> <Esc>:source $MYVIMRC<CR>
else
  " Reload .vimrc and .gvimrc.
  noremap  <silent> <F12> :<C-u>source $MYVIMRC<CR>:<C-u>source $MYGVIMRC<CR>
  noremap! <silent> <F12> <Esc>:source $MYVIMRC<CR>:<C-u>source $MYGVIMRC<CR>
endif
noremap  <silent> <S-F12> :<C-u>source %<CR>
noremap! <silent> <S-F12> <Esc>:source %<CR>




" ------------------------------------------------------------------------------
" Force to use keybind of vim to move cursor.
" ------------------------------------------------------------------------------
let s:keymsgs = [
      \ "Don't use Left-Key!!  Enter Normal-Mode and press 'h'!!!!",
      \ "Don't use Down-Key!!  Enter Normal-Mode and press 'j'!!!!",
      \ "Don't use Up-Key!!  Enter Normal-Mode and press 'k'!!!!",
      \ "Don't use Right-Key!!  Enter Normal-Mode and press 'l'!!!!",
      \ "Don't use Delete-Key!!  Press 'x' in Normal-Mode!!!!",
      \ "Don't use Backspace-Key!!  Press 'X' in Normal-Mode!!!!"
      \]
function! s:echo_keymsg(msgnr) abort
  echo s:keymsgs[a:msgnr]
endfunction

if s:is_cui && !g:is_windows
  " Disable move with cursor-key.
  noremap  <Left> <Nop>
  noremap! <Left> <Nop>
  nnoremap <Left> :<C-u>call <SID>echo_keymsg(0)<CR>
  inoremap <Left> <Esc>:call <SID>echo_keymsg(0)<CR>a

  noremap  <Down> <Nop>
  noremap! <Down> <Nop>
  nnoremap <Down> :<C-u>call <SID>echo_keymsg(1)<CR>
  inoremap <Down> <Esc>:call <SID>echo_keymsg(1)<CR>a

  noremap  <Up> <Nop>
  noremap! <Up> <Nop>
  nnoremap <Up> :<C-u>call <SID>echo_keymsg(2)<CR>
  inoremap <Up> <Esc>:call <SID>echo_keymsg(2)<CR>a

  noremap  <Right> <Nop>
  noremap! <Right> <Nop>
  nnoremap <Right> :<C-u>call <SID>echo_keymsg(3)<CR>
  inoremap <Right> <Esc>:call <SID>echo_keymsg(3)<CR>a
else
  map  <Left>   <Plug>(movewin-left)
  map! <Left>   <Plug>(movewin-left)
  map  <Down>   <Plug>(movewin-down)
  map! <Down>   <Plug>(movewin-down)
  map  <Up>     <Plug>(movewin-up)
  map! <Up>     <Plug>(movewin-up)
  map  <Right>  <Plug>(movewin-right)
  map! <Right>  <Plug>(movewin-right)
endif

" Disable delete with <Delete>
noremap  <Del> <Nop>
noremap! <Del> <Nop>
nnoremap <Del> :<C-u>call <SID>echo_keymsg(4)<CR>
inoremap <Del> <Esc>:call <SID>echo_keymsg(4)<CR>a
" Disable delete with <BS>.
" But available in command-line mode.
noremap  <BS> <Nop>
inoremap <BS> <Nop>
nnoremap <BS> :<C-u>call <SID>echo_keymsg(5)<CR>
inoremap <BS> <Esc>:call <SID>echo_keymsg(5)<CR>a
" }}}

" ------------------------------------------------------------------------------
" Plugins {{{
" ------------------------------------------------------------------------------
" ------------------------------------------------------------------------------
" Disable default plugins {{{
" ------------------------------------------------------------------------------
let g:loaded_gzip = 1
let g:loaded_tar = 1
let g:loaded_tarPlugin = 1
let g:loaded_zip = 1
let g:loaded_zipPlugin = 1
let g:loaded_rrhelper = 1
let g:loaded_2html_plugin = 1
let g:loaded_vimball = 1
let g:loaded_vimballPlugin = 1
let g:loaded_getscript = 1
let g:loaded_getscriptPlugin = 1
" let g:loaded_netrw = 1
" let g:loaded_netrwPlugin = 1
" let g:loaded_netrwSettings = 1
" let g:loaded_netrwFileHandlers = 1
" }}}
" ------------------------------------------------------------------------------
" Plugin lists and dein-configuration {{{
" ------------------------------------------------------------------------------
let s:deindir = expand(g:is_cygwin ? '~/.cache/dein_win32unix' : '~/.cache/dein')
let s:deinlocal = s:deindir . '/repos/github.com/Shougo/dein.vim'
let &rtp = s:deinlocal . ',' . &rtp
if !isdirectory(s:deinlocal)
  if v:version < 703
    echoerr 'Please use Vim 7.4!!!'
    finish
  elseif !s:executable('git')
    echoerr 'Please install git!!!'
    finish
  elseif !s:executable('rsync')
    echoerr 'Please install rsync!!!'
    finish
  endif
  function! s:dein_init() abort
    call mkdir(s:deinlocal, 'p')
    call s:system('git clone https://github.com/Shougo/dein.vim.git ' . s:deinlocal)
    source $MYVIMRC
    call dein#install()
  endfunction
  command! -bar DeinInit  call s:dein_init()
  echomsg 'Please Install dein.vim!'
  echomsg 'Do command :DeinInit'
  colorscheme default
  finish
endif

if g:at_startup
  let s:_ = escape(get(g:private, 'fzf_path', ''), ' ')
  if isdirectory(expand(s:_))
    let &rtp .= ',' . s:_
  endif
  let s:_ = escape(get(g:private, 'lilypond_path', ''), ' ')
  if isdirectory(expand(s:_))
    let &rtp .= ',' .  s:_
  endif
  unlet s:_
endif

function! s:dein_name_complete(arglead, cmdline, cursorpos) abort
  let arglead = tolower(a:arglead)
  echomsg a:arglead
  return filter(keys(dein#get()), '!stridx(tolower(v:val), arglead)')
endfunction
command! -bar -nargs=+ -complete=customlist,s:dein_name_complete DeinUpdate  call dein#update([<f-args>])

if dein#load_state(s:deindir)
  call dein#begin(s:deindir)
  call dein#load_toml(expand('~/.vim/dein.toml'), {'lazy': 0})
  call dein#load_toml(expand('~/.vim/dein_lazy.toml'), {'lazy': 1})
  call dein#end()
  call dein#save_state()
endif

" packadd vim-atcoder
packadd vim-kotutil
packadd vim-kolor
packadd AtCoderSubmitter.vim
set packpath+=$VIMRUNTIME/runtime
packadd termdebug

if !dein#tap('lightline.vim')
  setglobal statusline=%<%f\ %m\ %r%h%w%{'[fenc='.(&fenc!=#''?&fenc:&enc).']\ [ff='.&ff.']\ [ft='.(&ft==#''?'null':&ft).']\ [ascii=0x'}%B]%=\ (%v,%l)/%L%8P
  if has('syntax')
    augroup MyAutoCmd
      au InsertEnter * call s:hi_statusline(1)
      au InsertLeave * call s:hi_statusline(0)
      au ColorScheme * silent! let s:highlight_cmd = 'highlight ' . s:get_highlight('StatusLine')
    augroup END
  endif

  function! s:hi_statusline(mode) abort
    if a:mode == 1
      highlight StatusLine guifg=white guibg=MediumOrchid gui=none ctermfg=white ctermbg=DarkRed cterm=none
    else
      highlight clear StatusLine
      silent execute s:highlight_cmd
    endif
  endfunction

  function! s:get_highlight(hi) abort
    return substitute(substitute(s:redir('highlight ' . a:hi), 'xxx', '', ''), '[\r\n]', '', 'g')
  endfunction
endif
" }}}

" ------------------------------------------------------------------------------
" END of .vimrc {{{
" ------------------------------------------------------------------------------
if !g:at_startup
  call dein#call_hook('on_source')
  call dein#call_hook('post_source')
endif
filetype plugin indent on
set background=dark
if !s:is_cui || &t_Co == 256
  function! s:customize_iceberg() abort
    hi! Function ctermfg=216 guifg=#e2a478
    hi! String ctermfg=109 guifg=#89b8c2
    hi! Type ctermfg=109 gui=NONE guifg=#89b8c2
  endfunction
  autocmd MyAutoCmd ColorScheme iceberg call s:customize_iceberg()
  colorscheme iceberg
else
  colorscheme default
endif
set hlsearch
set secure
" }}}
