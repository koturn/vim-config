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
endfun
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

if !s:is_nvim
  source $VIMRUNTIME/macros/matchit.vim
  let g:hl_matchit_enable_on_vim_startup = 1
  let g:hl_matchit_speed_level = 1
  let g:hl_matchit_allow_ft_regexp = 'html\|vim\|sh'
endif
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
set visualbell t_vb=
set belloff=all
" set lazyredraw
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
  set notimeout
  set ttimeout
  set timeoutlen=100
else
  set timeout
  set timeoutlen=500
  set ttimeoutlen=100
endif
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
  autocmd MyAutoCmd FileType c  setlocal keywordprg=man
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
elseif exists('&termguicolors')
  set termguicolors
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
  let &clcompletefunc = s:sid_prefix . 's:clpum_complete'
  autocmd MyAutoCmd ColorScheme * highlight! link ClPmenu Pmenu
  function! s:clpum_complete(findstart, base) abort
    return a:findstart ? getcmdpos() : [
          \ {'word': 'Jan', 'menu': 'January'},
          \ {'word': 'Feb', 'menu': 'February'},
          \ {'word': 'Mar', 'menu': 'March'},
          \ {'word': 'Apr', 'menu': 'April'},
          \ {'word': 'May', 'menu': 'May'},
          \]
  endfunction
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


let s:t_codes = {
      \ 'ti': &t_ti,
      \ 'SI': &t_SI,
      \ 'EI': &t_EI,
      \ 'te': &t_te
      \}
function! s:set_term_mintty() abort
  let &t_ti = s:t_codes.ti . "\e[2 q"
  let &t_SI = s:t_codes.SI . "\e[6 q"
  let &t_EI = s:t_codes.EI . "\e[2 q"
  let &t_te = s:t_codes.te . "\e[0 q"
endfunction

if g:is_cygwin
  set enc =utf-8
  set fenc=utf-8
  set tenc=utf-8
  if (&term =~# '^xterm' || &term ==# 'screen') && &t_Co < 256
    set t_Co=256  " Extend cygwin terminal color
  endif
  if &term !=# 'cygwin'  " not in command prompt
    " Change cursor shape depending on mode.
    call s:set_term_mintty()

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
  set fileencodings=guess,ucs-2le,ucs-2,utf-16le,utf-16
else
  set fileencodings=iso-2022-jp,ucs-bom,utf-8,euc-jp,cp932,ucs-2le,ucs-2,utf-16le,utf-16
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
function! s:system(cmd) abort
  try
    return vimproc#cmd#system(a:cmd)
  catch /^Vim(call)\=:E117: .\+: vimproc#cmd#system$/
    return system(a:cmd)
  endtry
endfunction

function! s:_system(cmd) abort
  let out = ''
  let job = job_start([&shell, &shellcmdflag, a:cmd], {
        \ 'out_cb': {ch, msg -> [execute("let out .= msg"), out]},
        \ 'out_mode': 'raw'
        \})
  while job_status(job) ==# 'run'
    sleep 1m
  endwhile
  return out
endfunction

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
command! -bar -bang -range=% RetabHead  call s:retab_head(<bang>0, &tabstop, <line1>, <line2>)

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
  silent normal! gvy
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


function! s:comma_period(line1, line2) abort
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

" {{{ Dummy folding
function! s:make_viml_foldings(line1, line2) abort
  let cursor = getcurpos()
  execute 'keepjumps keeppatterns' a:line1 ',' a:line2 's/^\s*endfunction\zs\s*/ " }}}/ce'
  execute 'keepjumps keeppatterns' a:line1 ',' a:line2 's/^\s*function!\?\s\+[a-zA-Z:_#{}]\+(.*)\%(\s\+\%(abort\|dict\|range\)\)\+\zs\s*/ " {{{/ce'
  call setpos('.', cursor)
endfunction
command! -bar -range=% MakeVimLFoldings  call s:make_viml_foldings(<line1>, <line2>)
" }}}


" Save as a super user.
if s:executable('sudo')
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

" by ujihisa
command! -count=1 -nargs=0 GoToTheLine  silent execute getpos('.')[1][: -len(v:count) - 1] . v:count
nnoremap <silent> gl  :<C-u>GoToTheLine<CR>

" Show highlight group name under a cursor
command! -bar VimShowHlGroup  echo synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
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
    echomsg split(split(system('ps u -p ' . getpid()), "\n")[1], ' \+')[5] 'KB'
  endfunction
else
  function! s:show_memory_usage() abort
    echomsg 'Cannot available this command'
  endfunction
endif
command! -bar -bang ShowMemoryUsage  call s:show_memory_usage()

if g:is_windows && s:executable('taskkill')
  command! -bar Suicide  call system('taskkill /pid ' . getpid())
elseif s:executable('kill')
  command! -bar Suicide  call system('kill -KILL '. getpid())
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
  au Filetype cs         setlocal sw=4 ts=4 sts=4 noet
  au Filetype java       setlocal sw=4 ts=4 sts=4 noet cindent cinoptions& cinoptions+=j1
  au Filetype javascript setlocal sw=2 ts=2 sts=2      cindent cinoptions& cinoptions+=j1,J1,(s
  " )
  au Filetype make       setlocal sw=4 ts=4 sts=4
  au Filetype kuin       setlocal sw=2 ts=2 sts=2 noet
  au Filetype python     setlocal sw=4 ts=4 sts=4      cindent cinkeys-=0#
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
let s:deindir = expand('~/.cache/dein')
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
    call system('git clone https://github.com/Shougo/dein.vim.git ' . s:deinlocal)
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
command! -bar -nargs=+ -complete=customlist,s:dein_name_complete DeinUpdate  call dein#update(<f-args>)

if dein#load_state(s:deindir)
  call dein#begin(s:deindir)
  call dein#add('Shougo/dein.vim')
  " call dein#add('OmniSharp/omnisharp-vim', {
  "     \ 'lazy': 0,
  "     \ 'on_ft': 'cs'
  "     \})
  call dein#add('y0za/vim-udon-araisan', {
        \ 'lazy': 0
        \})
  call dein#add('koturn/nvim-denite-sample', {
        \ 'on_source': 'denite.nvim'
        \})
  call dein#add('haya14busa/dein-command.vim', {
        \ 'on_cmd': 'Dein'
        \})
  call dein#add('vim-jp/vimdoc-ja')
  call dein#add('ryunix/vim-wttrin')
  call dein#add('vim-jp/vital.vim', {
        \ 'on_cmd': 'Vitalize',
        \ 'on_func': 'vital'
        \})
  call dein#add('mattn/webapi-vim')
  let s:cflags = "CFLAGS='-Ofast -march=native -flto -s -Wall -Wextra -Wno-unused -Wno-unused-parameter -use=gnu99 -shared'"
  call dein#add('Shougo/vimproc.vim', {
        \ 'build': (g:is_windows ? 'tools\\update-dll-mingw' : 'make ' . s:cflags),
        \ 'on_cmd': [
        \   'VimProcInstall',
        \   'VimProcBang',
        \   'VimProcRead'
        \ ],
        \ 'on_func': 'vimproc'
        \})
  unlet s:cflags
  call dein#add('editorconfig/editorconfig-vim', {
        \ 'lazy': 0
        \})
  call dein#add('Yggdroot/indentLine')
  call dein#add('thinca/vim-localrc', {
        \ 'if': '!g:is_cygwin'
        \})
  call dein#add('itchyny/lightline.vim')
  call dein#add('Shougo/denite.nvim', {
        \ 'on_cmd': [
        \   'Denite',
        \   'DeniteBufferDir',
        \   'DeniteCursorWord'
        \ ]
        \})
  call dein#add('Shougo/unite.vim', {
        \ 'on_cmd': [
        \   'Unite',
        \   'UniteWithCurrentDir',
        \   'UniteWithBufferDir',
        \   'UniteWithProjectDir',
        \   'UniteWithInputDirectory',
        \   'UniteWithCursorWord',
        \   'UniteWithInput',
        \   'UniteResume',
        \   'UniteClose',
        \   'UniteNext',
        \   'UnitePrevious',
        \   'UniteFirst',
        \   'UniteLast'
        \ ]
        \})
  call dein#add('Shougo/neomru.vim', {'on_source': 'unite.vim'})
  call dein#add('ujihisa/unite-colorscheme', {'on_source': 'unite.vim'})
  call dein#add('ujihisa/unite-font',{'on_source': 'unite.vim'})
  call dein#add('osyo-manga/unite-highlight',{'on_source': 'unite.vim'})
  call dein#add('tsukkee/unite-tag', {'on_source': 'unite.vim'})
  call dein#add('tacroe/unite-mark', {'on_source': 'unite.vim'})
  call dein#add('yomi322/unite-tweetvim', {'on_source': 'unite.vim'})
  call dein#add('Shougo/unite-outline', {'on_source': 'unite.vim'})
  call dein#add('osyo-manga/unite-boost-online-doc', {'on_source': 'unite.vim'})
  call dein#add('tsukkee/unite-help', {'on_source': 'unite.vim'})
  call dein#add('sorah/unite-ghq', {'on_source': 'unite.vim'})
  call dein#add('Shougo/vimfiler', {
        \ 'depends' : 'unite.vim',
        \ 'lazy': 1,
        \ 'on_cmd': [
        \   'VimFiler',
        \   'VimFilerDouble',
        \   'VimFilerCurrentDir',
        \   'VimFilerBufferDir',
        \   'VimFilerCreate',
        \   'VimFilerSimple',
        \   'VimFilerSplit',
        \   'VimFilerTab',
        \   'VimFilerExplorer',
        \   'VimFilerClose',
        \   'VimFilerEdit',
        \   'VimFilerRead',
        \   'VimFilerSource',
        \   'VimFilerWrite',
        \ ]
        \})
  call dein#add('roxma/nvim-yarp', {
        \ 'if': !has('nvim') && !has('win32') && !has('win32unix') && v:version >= 704
        \})
  call dein#add('roxma/vim-hug-neovim-rpc', {
        \ 'if': !has('nvim') && !has('win32') && !has('win32unix') && v:version >= 704
        \})
  call dein#add('Shougo/deoplete.nvim', {
        \ 'if': has('nvim') || !has('win32') && !has('win32unix') && v:version >= 704,
        \ 'on_event': 'InsertEnter'
        \})
  call dein#add('Shougo/neocomplete.vim', {
        \ 'if': !(has('nvim') || !has('win32') && !has('win32unix') && v:version >= 704) && has('lua') && (v:version > 703 || (v:version == 703 && has('patch885'))),
        \ 'on_event': 'InsertEnter',
        \ 'on_cmd': [
        \   'NeoCompleteEnable',
        \   'NeoCompleteDisable',
        \   'NeoCompleteLock',
        \   'NeoCompleteUnlock',
        \   'NeoCompleteToggle',
        \   'NeoCompleteSetFileType',
        \   'NeoCompleteClean',
        \   'NeoCompleteBufferMakeCache',
        \   'NeoCompleteDictionaryMakeCache',
        \   'NeoCompleteSyntaxMakeCache',
        \   'NeoCompleteTagMakeCache'
        \ ]
        \})
  call dein#add('Shougo/neocomplcache', {
        \ 'if': !(has('nvim') || !has('win32') && !has('win32unix') && v:version >= 704) && !(has('lua') && (v:version > 703 || (v:version == 703 && has('patch885')))),
        \ 'on_event': 'InsertEnter',
        \ 'on_cmd': [
        \   'NeoComplCacheEnable',
        \   'NeoComplCacheDisable',
        \   'NeoComplCacheLock',
        \   'NeoComplCacheUnlock',
        \   'NeoComplCacheToggle',
        \   'NeoComplCacheLockSource',
        \   'NeoComplCacheUnlockSource',
        \   (v:version >= 703 ? 'NeoComplCacheSetFileType' : 'NeoComplCacheSetFileType'),
        \   'NeoComplCacheSetFileType',
        \   'NeoComplCacheClean',
        \ ],
        \ 'on_map': [['is', '<Plug>(neocomplcache_snippets_']]
        \})
  call dein#add('Shougo/neosnippet', {
        \ 'on_event': 'InsertEnter',
        \ 'on_cmd': [
        \   'NeoSnippetEdit',
        \   'NeoSnippetMakeCache',
        \   'NeoSnippetSource',
        \   'NeoSnippetClearMarkers'
        \ ],
        \ 'on_ft': 'neosnippet',
        \ 'on_map': [['nisx', '<Plug>(neosnippet_']],
        \})
  call dein#add('Shougo/neosnippet-snippets')
  call dein#add('Shougo/vimshell', {
        \ 'depends': 'vimproc.vim',
        \ 'on_cmd': [
        \   'VimShell',
        \   'VimShellCreate',
        \   'VimShellPop',
        \   'VimShellTab',
        \   'VimShellCurrentDir',
        \   'VimShellBufferDir',
        \   'VimShellExecute',
        \   'VimShellInteractive',
        \   'VimShellSendString',
        \   'VimShellSendBuffer',
        \   'VimShellClose'
        \ ],
        \ 'on_map': [['n', '<Plug>(vimshell_']]
        \})
  call dein#add('Shougo/vinarise', {
        \ 'on_cmd': [
        \   'Vinarise',
        \   'VinarisePluginBitmapView',
        \   'VinarisePluginDump'
        \ ]
        \})
  call dein#add('ujihisa/vimshell-ssh', {
        \ 'on_ft': 'vimshell'
        \})
  call dein#add('vim-scripts/Conque-Shell', {
        \ 'on_cmd': 'ConqueTerm'
        \})
  call dein#add('rbtnn/vimconsole.vim', {
        \ 'on_cmd': [
        \   'VimConsoleOpen',
        \   'VimConsoleRedraw',
        \   'VimConsoleClose',
        \   'VimConsoleClear',
        \   'VimConsoleToggle',
        \   'VimConsoleLog',
        \   'VimConsoleSaveSession',
        \   'VimConsoleLoadSession'
        \ ]
        \})
  call dein#add('gregsexton/VimCalc', {
        \ 'on_cmd': 'Calc'
        \})
  " call dein#add('haya14busa/incsearch.vim', {
  "       \ 'on_map': [['nvo', '<Plug>(incsearch-']]
  "       \})
  call dein#add('jceb/vim-hier', {
        \ 'on_cmd': ['HierUpdate', 'HierClear', 'HierStart', 'HierStop'],
        \ 'on_ft': 'qf'
        \})
  call dein#add('haya14busa/vim-undoreplay', {
        \ 'on_cmd': 'UndoReplay'
        \})
  call dein#add('osyo-manga/vim-over', {
        \ 'on_cmd': [
        \   'OverCommandLine',
        \   'OverCommandLineNoremap',
        \   'OverCommandLineMap',
        \   'OverCommandLineUnmap'
        \ ]
        \})
  call dein#add('glidenote/memolist.vim', {
        \ 'on_cmd': ['MemoGrep', 'MemoNew']
        \})
  call dein#add('kana/vim-altr', {
        \ 'on_map': [['cinov', '<Plug>(altr-']]
        \})
  call dein#add('AndrewRadev/switch.vim', {
        \ 'on_cmd': 'Switch'
        \})
  call dein#add('rhysd/tmpwin.vim', {
        \ 'on_func': 'tmpwin'
        \})
  call dein#add('itchyny/calendar.vim', {
        \ 'on_cmd': 'Calendar',
        \ 'on_map': [['nv', '<Plug>(calendar)']]
        \})
  call dein#add('LeafCage/vimhelpgenerator', {
        \ 'on_cmd': ['VimHelpGenerator', 'VimHelpGeneratorVirtual']
        \})
  call dein#add('tyru/restart.vim', {
        \ 'on_cmd': 'Restart'
        \})
  call dein#add('osyo-manga/vim-reanimate', {
        \ 'on_cmd': [
        \   'ReanimateSave',
        \   'ReanimateSaveCursorHold',
        \   'ReanimateSaveInput',
        \   'ReanimateLoad',
        \   'ReanimateLoadInput',
        \   'ReanimateLoadLatest',
        \   'ReanimateSwitch',
        \   'ReanimateEditVimrcLocal',
        \   'ReanimateUnLoad'
        \ ]
        \})
  call dein#add('kana/vim-textobj-user')
  call dein#add('kana/vim-textobj-entire', {
        \ 'depends': 'vim-textobj-user',
        \ 'on_map': [['xo', 'ae'], ['xo', 'ie']]
        \})
  call dein#add('kana/vim-textobj-fold', {
        \ 'depends': 'vim-textobj-user',
        \ 'on_map': [['xo', 'az'], ['xo', 'iz']]
        \})
  call dein#add('kana/vim-textobj-indent', {
        \ 'depends': 'vim-textobj-user',
        \ 'on_map': [['xo', 'ai'], ['xo', 'aI'], ['xo', 'ii'], ['xo', 'iI']]
        \})
  call dein#add('kana/vim-textobj-line', {
        \ 'depends': 'vim-textobj-user',
        \ 'on_map': [['xo', 'al'], ['xo', 'il']]
        \})
  call dein#add('kana/vim-textobj-syntax', {
        \ 'depends': 'vim-textobj-user',
        \ 'on_map': [['xo', 'ay'], ['xo', 'iy']]
        \})
  call dein#add('kana/vim-textobj-django-template', {
        \ 'depends': 'vim-textobj-user',
        \ 'on_map': [['xo', 'adb'], ['xo', 'idb']]
        \})
  call dein#add('thinca/vim-textobj-between', {
        \ 'depends': 'vim-textobj-user',
        \ 'on_map': [['xo', 'af'], ['xo', 'if'], ['xo', '<Plug>(textobj-between-']]
        \})
  call dein#add('mattn/vim-textobj-url', {
        \ 'depends': 'vim-textobj-user',
        \ 'on_map': [['xo', 'au'], ['xo', 'iu']]
        \})
  call dein#add('osyo-manga/vim-textobj-multiblock', {
        \ 'depends': 'vim-textobj-user',
        \ 'on_map': [['xo', 'ab'], ['xo', 'ib'], ['xo', '<Plug>(textobj-multiblock-']]
        \})
  call dein#add('lucapette/vim-textobj-underscore', {
        \ 'depends': 'vim-textobj-user',
        \ 'on_map': [['xo', 'a_'], ['xo', 'i_']]
        \})
  call dein#add('haya14busa/vim-textobj-number', {
        \ 'depends': 'vim-textobj-user',
        \ 'on_map': [['xo', 'an'], ['xo', 'in']]
        \})
  call dein#add('mattn/emmet-vim', {
        \ 'on_cmd': ['EmmetInstall', 'Emmet'],
        \ 'on_ft': ['html', 'css', 'markdown']
        \})
  call dein#add('tyru/eskk.vim', {
        \ 'on_map': [['nicl', '<Plug>(eskk:']]
        \})
  call dein#add('thinca/vim-quickrun', {
        \ 'on_cmd': 'QuickRun',
        \ 'on_map': [['n', '<Plug>(quickrun']]
        \})
  call dein#add('thinca/vim-scouter', {
        \ 'on_cmd': 'Scouter'
        \})
  call dein#add('thinca/vim-ref', {
        \ 'depends': 'vimproc.vim',
        \ 'on_cmd': 'Ref',
        \ 'on_map': [['nv', '<Plug>(ref-keyword)']]
        \})
  call dein#add('aiya000/aref-web.vim', {
        \ 'on_cmd': ['Aref', 'ArefOpenBrowser'],
        \ 'on_map': [['n', '<Plug>(aref_web_show_']]
        \})
  call dein#add('ebc-2in2crc/vim-ref-jvmis', {
        \ 'depends': 'vim-ref',
        \ 'on_cmd': 'Jvmis'
        \})
  call dein#add('rhysd/vim-grammarous', {
        \ 'on_cmd': [
        \   'GrammarousCheck',
        \   'GrammarousReset'
        \ ],
        \ 'on_map': [['n', '<Plug>(grammarous-']]
        \})
  call dein#add('mattn/excitetranslate-vim', {
        \ 'depends': 'webapi-vim',
        \ 'on_cmd': 'ExciteTranslate'
        \})

  call dein#add('cohama/lexima.vim', {
        \ 'on_event': 'InsertEnter'
        \})
  call dein#add('rhysd/endwize.vim', {
        \ 'on_ft': ['lua', 'ruby', 'sh', 'zsh', 'vb', 'vbnet', 'aspvbs', 'vim']
        \})
  call dein#add('ctrlpvim/ctrlp.vim', {
        \ 'on_cmd': [
        \   'CtrlP',
        \   'CtrlPMRUFiles',
        \   'CtrlPBuffer',
        \   'CtrlPLastMode',
        \   'CtrlPClearCache',
        \   'CtrlPClearAllCaches',
        \   'CtrlPCtrlPCache',
        \   'CtrlPAllCtrlPCaches',
        \   'CtrlPCurWD',
        \   'CtrlPCurFile',
        \   'CtrlPRoot',
        \   'CtrlPTag',
        \   'CtrlPQuickfix',
        \   'CtrlPDir',
        \   'CtrlPBufTag',
        \   'CtrlPBufTagAll',
        \   'CtrlPRTS',
        \   'CtrlPUndo',
        \   'CtrlPLine',
        \   'CtrlPChange',
        \   'CtrlPChangeAll',
        \   'CtrlPMixed',
        \   'CtrlPBookmarkDir',
        \   'CtrlPBookmarkDirAdd',
        \ ],
        \})
  call dein#add('mattn/ctrlp-launcher', {
        \ 'depends': 'ctrlp.vim',
        \ 'on_cmd': 'CtrlPLauncher',
        \ 'on_map': '<plug>(ctrlp-launcher)'
        \})
  call dein#add('mattn/startmenu-vim', {
        \ 'depends': ['webapi-vim', 'ctrlp.vim', 'unite.vim'],
        \ 'on_cmd': 'StartMenu',
        \ 'on_source': 'unite.vim'
        \})
  call dein#add('LeafCage/alti.vim', {
        \ 'on_func': 'alti'
        \})
  call dein#add('kamichidu/vim-milqi', {
        \ 'on_cmd': 'MilqiFromUnite',
        \ 'on_func': 'milqi'
        \})
  call dein#add('tyru/caw.vim', {
        \ 'on_map': [['nv', '<Plug>(caw:hatpos:']]
        \})
  call dein#add('tpope/vim-surround', {
        \ 'on_map': [
        \   ['n', '<Plug>Dsurround'],
        \   ['n', '<Plug>Csurround'],
        \   ['n', '<Plug>Ysurround'],
        \   ['n', '<Plug>YSurround'],
        \   ['n', '<Plug>Yssurround'],
        \   ['n', '<Plug>YSsurround'],
        \   ['v', '<Plug>VSurround'],
        \   ['v', '<Plug>VgSurround']
        \ ]
        \})
  call dein#add('osyo-manga/vim-anzu', {
        \ 'on_cmd': [
        \   'AnzuClearSearchStatus',
        \   'AnzuClearSearchCache',
        \   'AnzuUpdateSearchStatus',
        \   'AnzuUpdateSearchStatusOutput',
        \   'AnzuSignMatchLine',
        \   'AnzuClearSignMatchLine'
        \ ],
        \ 'on_map': [['nxo', '<Plug>(anzu-']]
        \})
  call dein#add('thinca/vim-visualstar', {
        \ 'on_map': [['nvo', '<Plug>(visualstar-']]
        \})
  call dein#add('rhysd/clever-f.vim', {
        \ 'on_map': [['nxo', '<Plug>(clever-f-']]
        \})
  call dein#add('daisuzu/rainbowcyclone.vim', {
        \ 'on_cmd': ['RC', 'RCReset', 'RCList', 'RCConcat'],
        \ 'on_map': [['n', '<Plug>(rc_']]
        \})
  call dein#add('rhysd/accelerated-jk', {
        \ 'on_map': [['n', '<Plug>(accelerated_jk_']]
        \})
  call dein#add('tyru/capture.vim', {
        \ 'on_cmd': 'Capture'
        \})
  call dein#add('thinca/vim-prettyprint', {
        \ 'on_cmd': [
        \   'PrettyPrint',
        \   'PP'
        \ ],
        \ 'on_func': 'prettyprint'
        \})
  call dein#add('tpope/vim-fugitive', {
        \ 'lazy': 0,
        \ 'augroup': 'fugitive'
        \})
  call dein#add('cohama/agit.vim', {
        \ 'on_cmd': [
        \   'Agit',
        \   'AgitFile'
        \ ]
        \})
  call dein#add('lambdalisue/gina.vim', {
        \ 'on_cmd': 'Gina'
        \})
  call dein#add('mattn/gist-vim', {
        \ 'depends': 'webapi-vim',
        \ 'on_cmd': 'Gist'
        \})
  call dein#add('rhysd/wandbox-vim', {
        \ 'on_cmd': [
        \   'Wandbox',
        \   'WandboxAsync',
        \   'WandboxSync',
        \   'WandboxOptionList',
        \   'WandboxOptionListAsync',
        \   'WandboxAbortAsyncWorks',
        \   'WandboxOpenBrowser'
        \ ]
        \})
  call dein#add('mopp/AOJ.vim', {
        \ 'depends': ['webapi-vim', 'unite.vim'],
        \ 'on_cmd': ['AOJSubmit', 'AOJSubmitByProblemID', 'AOJViewProblems', 'AOJViewStaticticsLogs']
        \})
  call dein#add('vim-scripts/DoxygenToolkit.vim', {
        \ 'on_cmd': ['Dox', 'DoxLic', 'DoxAuthor', 'DoxUndoc', 'DoxBlock']
        \})
  call dein#add('vim-scripts/tagexplorer.vim', {
        \ 'if': executable('ctags'),
        \ 'on_ft': ['cpp', 'java', 'perl', 'python', 'ruby', 'tags'],
        \ 'on_cmd': 'TagExplorer'
        \})
  call dein#add('majutsushi/tagbar', {
        \ 'on_cmd': [
        \   'Tagbar',
        \   'TagbarToggle',
        \   'TagbarOpen',
        \   'TagbarOpenAutoClose',
        \   'TagbarClose',
        \   'TagbarSetFoldlevel',
        \   'TagbarShowTag',
        \   'TagbarCurrentTag',
        \   'TagbarGetTypeConfig',
        \   'TagbarDebug',
        \   'TagbarDebugEnd',
        \   'TagbarTogglePause',
        \ ]
        \})
call dein#add('mopp/makecomp.vim', {
      \ 'on_cmd': 'Make'
        \})
  call dein#add('mattn/emoji-vim', {
        \ 'on_cmd': 'Emoji'
        \})
  call dein#add('kannokanno/previm', {
        \ 'on_cmd': 'PrevimOpen'
        \})
  call dein#add('dhruvasagar/vim-table-mode', {
        \ 'on_cmd': [
        \   'TableModeToggle',
        \   'TableModeEnable',
        \   'TableModeDisable',
        \   'Tableize',
        \   'TableSort',
        \   'TableAddFormula',
        \   'TableModeRealign',
        \   'TableEvalFormulaLine'
        \ ],
        \ 'on_map': '<Plug>(table-mode-'
        \})
  call dein#add('vim-scripts/CCTree')
  call dein#add('joker1007/vim-markdown-quote-syntax', {
        \ 'on_ft': 'markdown'
        \})
  call dein#add('octol/vim-cpp-enhanced-highlight', {
        \ 'on_ft': ['c', 'cpp'],
        \})
  call dein#add('kana/vim-operator-user')
  call dein#add('rhysd/vim-clang-format', {
        \ 'depends': ['vim-operator-user'],
        \ 'on_cmd': ['ClangFormat', 'ClangFormatEchoFormattedCode', 'ClangFormatAutoToggle'],
        \ 'on_map': ['<Plug>(operator-clang-format)']
        \})
  " call dein#add('osyo-manga/vim-marching', {
  "       \ 'on_cmd': [
  "       \   'MarchingBufferClearCache',
  "       \   'MarchingDebugLog',
  "       \   'MarchingDebugClearLog',
  "       \   'MarchingEnableDebug',
  "       \   'MarchingDisableDebug',
  "       \   'MarchingDebugCheck'
  "       \ ],
  "       \ 'on_map': [['i', '<Plug>(marching_']],
  "       \ 'on_ft': ['c', 'cpp']
  "       \})
  call dein#add('vim-scripts/java_getset.vim', {
        \ 'on_ft': 'java'
        \})
  call dein#add('vim-scripts/jcommenter.vim', {
        \ 'on_ft': 'java'
        \})
  call dein#add('osyo-manga/vim-snowdrop', {
        \ 'on_ft': ['c', 'cpp']
        \})
  " call dein#add('justmao945/vim-clang', {
  "       \ 'on_ft': ['c', 'cpp']
  "       \})
  call dein#add('pangloss/vim-javascript', {
        \ 'on_ft': 'javascript'
        \})
  call dein#add('heavenshell/vim-jsdoc', {
        \ 'on_ft': 'javascript'
        \})
  call dein#add('othree/html5-syntax.vim', {
        \ 'on_ft': 'html'
        \})
  call dein#add('hail2u/vim-css3-syntax', {
        \ 'on_ft': 'css'
        \})
  call dein#add('elzr/vim-json', {
        \ 'on_ft': 'json'
        \})
  " call dein#add('mitechie/pyflakes-pathogen', {
  "       \ 'on_ft': 'python'
  "       \})
  call dein#add('vim-scripts/ruby-matchit', {
        \ 'on_ft': 'ruby'
        \})
  call dein#add('losingkeys/vim-niji', {
      \ 'on_ft': ['lisp', 'scheme', 'clojure'],
      \ 'on_path': ['\.lisp$', '\.scm$', '\.clojure$'],
      \})
  call dein#add('vim-scripts/gnuplot.vim', {
        \ 'on_ft': 'gnuplot'
        \})
  call dein#add('tatt61880/kuin_vim', {
        \ 'on_ft': 'kuin'
        \})
  call dein#add('brgmnn/vim-opencl', {
        \ 'on_ft': 'opencl'
        \})
  call dein#add('lilydjwg/colorizer')
  call dein#add('junegunn/goyo.vim', {
        \ 'on_cmd': 'Goyo'
        \})
  call dein#add('pocket7878/curses-vim')
  call dein#add('pocket7878/presen-vim', {
        \ 'depends': 'curses-vim',
        \ 'on_cmd': [
        \   'Presen',
        \   'Vp2html'
        \ ],
        \ 'on_ft': 'vimpresen',
        \})
  call dein#add('thinca/vim-showtime', {
        \ 'on_cmd': [
        \   'ShowtimeStart',
        \   'ShowtimeResume'
        \ ]
        \})
  call dein#add('thinca/vim-fontzoom', {
        \ 'if': !s:is_cui,
        \ 'on_cmd': 'Fontzoom',
        \ 'on_map': [['n', '<Plug>(fontzoom-']]
        \})
  call dein#add('tyru/open-browser.vim', {
        \ 'on_cmd': [
        \   'OpenBrowser',
        \   'OpenBrowserSearch',
        \   'OpenBrowserSmartSearch'
        \ ],
        \ 'on_map': [['nv', '<Plug>(openbrowser-']],
        \ 'on_func': 'openbrowser'
        \})
  call dein#add('basyura/twibill.vim')
  call dein#add('basyura/TweetVim', {
        \ 'depends': ['open-browser.vim', 'twibill.vim'],
        \ 'on_cmd': [
        \   'TweetVimAccessToken',
        \   'TweetVimAddAccount',
        \   'TweetVimClearIcon',
        \   'TweetVimCommandSay',
        \   'TweetVimCurrentLineSay',
        \   'TweetVimHomeTimeline',
        \   'TweetVimListStatuses',
        \   'TweetVimMentions',
        \   'TweetVimSay',
        \   'TweetVimSearch',
        \   'TweetVimSwitchAccount',
        \   'TweetVimUserStream',
        \   'TweetVimUserTimeline',
        \   'TweetVimVersion'
        \ ],
        \ 'on_source': 'unite.vim'
        \})
  let s:build_cmd = 'pip install fbconsole'
  call dein#add('daisuzu/facebook.vim', {
        \ 'build': {
        \   'windows': s:build_cmd,
        \   'mac': s:build_cmd,
        \   'cygwin': s:build_cmd,
        \   'linux': s:build_cmd,
        \   'unix': s:build_cmd
        \ },
        \ 'depends': ['open-browser.vim', 'webapi-vim'],
        \ 'on_cmd': [
        \   'FacebookHome',
        \   'FacebookFeed',
        \   'FacebookWallPost',
        \   'FacebookAuthenticate'
        \ ]
        \})
  unlet s:build_cmd
  call dein#add('tsukkee/lingr-vim', {
        \ 'on_cmd': 'LingrLaunch'
        \})
  call dein#add('yuratomo/gmail.vim', {
        \ 'on_cmd': ['Gmail', 'GmailChangeUser', 'GmailExit', 'GmailCheckNewMail'],
        \})
  call dein#add('katono/rogue.vim', {
        \ 'on_cmd': ['Rogue', 'RogueRestore', 'RogueResume', 'RogueScores']
        \})
  call dein#add('christianrondeau/vimcastle', {
        \ 'on_cmd': 'Vimcastle'
        \})
  call dein#add('thinca/vim-threes', {
        \ 'on_cmd': ['ThreesStart', 'ThreesShowRecord']
        \})
  call dein#add('deris/vim-duzzle', {
        \ 'on_cmd': 'DuzzleStart'
        \})
  call dein#add('rbtnn/puyo.vim', {
        \ 'on_cmd': 'Puyo'
        \})

  call dein#add('supermomonga/jazzradio.vim', {
        \ 'on_source': 'unite.vim',
        \ 'on_cmd': [
        \   'JazzradioUpdateChannels',
        \   'JazzradioStop',
        \   'JazzradioPlay',
        \ ],
        \ 'on_func': 'jazzradio'
        \})
  call dein#add('mattn/ctrlp-jazzradio', {
        \ 'depends' : 'ctrlp.vim',
        \ 'on_cmd': 'CtrlPJazzradio'
        \})
  call dein#add('yuratomo/w3m.vim', {
        \ 'if': executable('w3m'),
        \ 'on_cmd': [
        \   'W3m',
        \   'W3mTab',
        \   'W3mSplit',
        \   'W3mVSplit',
        \   'W3mLocal',
        \   'W3mHistory',
        \   'W3mHistoryClear'
        \ ]
        \})
  call dein#add('vim-scripts/DrawIt', {
        \ 'on_cmd': ['DrawIt', 'DIstart', 'DIstop', 'DInrml', 'DIsngl', 'DIdbl'],
        \ 'on_map': [['nxo', '<Plug>DrawIt']]
        \})
  call dein#add('osyo-manga/vim-sugarpot', {
        \ 'on_cmd': [
        \   'SugarpotRenderImage',
        \   'SugarpotPreview',
        \   'SugarpotClosePreview',
        \   'SugarpotClosePreviewAll'
        \ ]
        \})
  call dein#add('koturn/vim-clipboard', {
        \ 'on_cmd': ['GetClip', 'PutClip']
        \})
  call dein#add('koturn/vim-replica', {
        \ 'on_cmd': ['Replica', 'ReplicaInternal']
        \})
  call dein#add('koturn/weather.vim', {
        \ 'on_cmd': 'Weather'
        \})
  call dein#add('koturn/benchvimrc-vim', {
        \ 'on_cmd': 'BenchVimrc'
        \})
  call dein#add('koturn/vim-serverutil')
  call dein#add('koturn/vim-altcomplete')
  call dein#add('koturn/vim-venchmark')
  call dein#add('koturn/vim-kotemplate', {
        \ 'depends': ['unite.vim', 'ctrlp.vim', 'alti.vim', 'vim-milqi'],
        \ 'on_cmd': [
        \   'KoTemplateLoad',
        \   'KoTemplateMakeProject',
        \   'CtrlPKoTemplate',
        \   'AltiKoTemplate',
        \   'MilqiKoTemplate',
        \   'FZFKoTemplate',
        \ ],
        \ 'on_source': ['unite.vim', 'denite.nvim'],
        \ 'on_func': 'kotemplate'
        \})
  call dein#add('koturn/vim-mplayer', {
        \ 'depends': ['unite.vim', 'ctrlp.vim', 'alti.vim', 'vim-milqi'],
        \ 'on_cmd': [
        \   'AltiMPlayer',
        \   'CtrlPMPlayer',
        \   'MilqiMPlayer',
        \   'FZFMPlayer',
        \   'MPlayer',
        \   'MPlayerEnqueue',
        \   'MPlayerCommand',
        \   'MPlayerStop',
        \   'MPlayerVolume',
        \   'MPlayerVolumeBar',
        \   'MPlayerSpeed',
        \   'MPlayerEqualizer',
        \   'MPlayerToggleMute',
        \   'MPlayerTogglePause',
        \   'MPlayerToggleRTTimeInfo',
        \   'MPlayerLoop',
        \   'MPlayerSeek',
        \   'MPlayerSeekToHead',
        \   'MPlayerSeekToEnd',
        \   'MPlayerOperateWithKey',
        \   'MPlayerPrev',
        \   'MPlayerNext',
        \   'MPlayerShowFileInfo',
        \   'MPlayerCommand',
        \   'MPlayerGetProperty',
        \   'MPlayerSetProperty',
        \   'MPlayerStepProperty',
        \   'MPlayerHelp',
        \   'MPlayerFlush'
        \ ],
        \ 'on_source': ['unite.vim', 'denite.nvim'],
        \})
  call dein#add('koturn/movewin.vim', {
        \ 'on_cmd': ['MoveWin', 'MoveWinLeft', 'MoveWinDown', 'MoveWinUp', 'MoveWinRight'],
        \ 'on_map': [['nvoic', '<Plug>(movewin-']]
        \})
  call dein#add('koturn/vim-resizewin', {
        \ 'on_cmd': [
        \   'Resizewin',
        \   'ResizewinByOffset',
        \   'ResizewinStartFullScreen',
        \   'ResizewinStopFullScreen',
        \   'ResizewinToggleFullScreen'
        \ ],
        \ 'on_map': [['nvoic', '<Plug>(resizewin-']]
        \})
  call dein#add('koturn/vim-themostdangerouswritingapp', {
        \ 'on_cmd': ['TheMostDangerousWritingAppEnable', 'TheMostDangerousWritingAppDisable']
        \})
  call dein#add('koturn/vim-podcast', {
        \ 'depends': ['vim-mplayer', 'denite.nvim', 'unite.vim', 'ctrlp.vim', 'alti.vim'],
        \ 'on_cmd': [
        \   'PodcastStop',
        \   'PodcastUpdate',
        \   'CtrlPPodcast',
        \   'AltiPodcast',
        \ ],
        \ 'on_source': ['denite.nvim', 'unite.vim']
        \})
  call dein#add('koturn/vim-rebuildfm', {
        \ 'on_cmd': [
        \   'CtrlPRebuildfm',
        \   'RebuildfmPlayByNumber',
        \   'RebuildfmLiveStream',
        \   'RebuildfmStop',
        \   'RebuildfmTogglePause',
        \   'RebuildfmToggleMute',
        \   'RebuildfmVolume',
        \   'RebuildfmSpeed',
        \   'RebuildfmSeek',
        \   'RebuildfmRelSeek',
        \   'RebuildfmShowInfo',
        \   'RebuildfmUpdateChannel',
        \ ],
        \ 'on_source': 'unite.vim',
        \})
  call dein#add('koturn/vim-mozaicfm', {
        \ 'on_cmd': [
        \   'CtrlPMozaicfm',
        \   'MozaicfmPlayByNumber',
        \   'MozaicfmStop',
        \   'MozaicfmTogglePause',
        \   'MozaicfmToggleMute',
        \   'MozaicfmVolume',
        \   'MozaicfmSpeed',
        \   'MozaicfmSeek',
        \   'MozaicfmRelSeek',
        \   'MozaicfmShowInfo',
        \   'MozaicfmUpdateChannel',
        \ ],
        \ 'on_source': 'unite.vim',
        \})
  call dein#add('koturn/vim-brainfuck', {
        \ 'on_cmd': ['BFExecute', 'BFTranslate2C'],
        \ 'on_ft': 'brainfuck'
        \})
  call dein#add('koturn/vim-rawsearch', {
        \ 'on_cmd': 'ToggleRawSearch'
        \})
  call dein#add('koturn/vim-nicovideo', {
        \ 'on_cmd': [
        \   'CtrlPNicoVideo',
        \   'NicoVideo',
        \   'NicoVideoUpdateRanking',
        \   'NicoVideoLogin',
        \   'NicoVideoLogout'
        \ ],
        \ 'on_source': 'unite.vim'
        \})
  call dein#end()
  call dein#save_state()
endif
" }}}
" ------------------------------------------------------------------------------
" Plugin-configurations {{{
" ------------------------------------------------------------------------------
if (!s:is_cui || &t_Co >= 16) && dein#tap('lightline.vim')
  set laststatus=2
  let g:lightline = {
        \ 'colorscheme': 'wombat',
        \ 'separator': { 'left': "\u2b80", 'right': "\u2b82" },
        \ 'subseparator': {  'left': "\u2b81", 'right': "\u2b83" },
        \ 'mode_map': {'c': 'NORMAL'},
        \ 'active': {
        \   'left': [['mode', 'eskk_status', 'paste'], ['fugitive', 'filename']],
        \   'right': [['lineinfo'], ['percent'], ['fileformat', 'fileencoding', 'filetype'], ['time']]
        \ },
        \ 'component_function': {
        \   'modified': s:sid_prefix . 'light_line_modified',
        \   'eskk_status': s:sid_prefix . 'light_line_eskk_status',
        \   'readonly': s:sid_prefix . 'light_line_readonly',
        \   'fugitive': s:sid_prefix . 'light_line_fugitive',
        \   'filename': s:sid_prefix . 'light_line_filename',
        \   'fileformat': s:sid_prefix . 'light_line_fileformat',
        \   'filetype': s:sid_prefix . 'light_line_filetype',
        \   'fileencoding': s:sid_prefix . 'light_line_fileencoding',
        \   'mode': s:sid_prefix . 'light_line_mode',
        \   'time': s:sid_prefix . 'light_line_time'
        \ }
        \}
  function! s:light_line_modified() abort
    return &ft =~ 'help\|vimfiler\|gundo' ? '' : &modified ? '+' : &modifiable ? '' : '-'
  endfunction
  function! s:light_line_readonly() abort
    return &ft !~? 'help\|vimfiler\|gundo' && &readonly ? 'x' : ''
  endfunction
  function! s:light_line_filename() abort
    return ('' != s:light_line_readonly() ? s:light_line_readonly() . ' ' : '') .
          \ (&ft == 'vimfiler' ? vimfiler#get_status_string() :
          \  &ft == 'unite' ? unite#get_status_string() :
          \  &ft == 'vimshell' ? vimshell#get_status_string() :
          \ '' != expand('%:t') ? expand('%:t') : '[No Name]') .
          \ ('' != s:light_line_modified() ? ' ' . s:light_line_modified() : '')
  endfunction
  function! s:light_line_fugitive() abort
    try
      if &ft !~? 'vimfiler\|gundo' && exists('*fugitive#head')
        return fugitive#head()
      endif
    catch
    endtry
    return ''
  endfunction
  function! s:light_line_fileformat() abort
    return winwidth(0) > 70 ? &fileformat : ''
  endfunction
  function! s:light_line_filetype() abort
    return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype : 'no ft') : ''
  endfunction
  function! s:light_line_fileencoding() abort
    return winwidth(0) > 70 ? (strlen(&fenc) ? &fenc : &enc) : ''
  endfunction
  function! s:light_line_mode() abort
    return winwidth(0) > 60 ? lightline#mode() : ''
  endfunction
  function! s:light_line_time() abort
    return winwidth(0) > 80 ? strftime('%Y/%m/%d(%a) %H:%M:%S') : ''
  endfunction
  function! s:light_line_eskk_status() abort
    return winwidth(0) > 60 && lightline#mode() ==# 'INSERT' && exists('*eskk#statusline') ? eskk#statusline() ==# '[eskk:あ]' ? '[あ]' : '[--]' : '[--]'
  endfunction
else
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

if dein#tap('denite.nvim')
  if has('win32') || has('nvim')
    let g:python3_host_prog = 'C:\Program Files\Python35\python.exe'
  elseif has('win32unix')
    let g:python3_host_prog = '/c/Program Files/Python35/python.exe'
  endif
endif

if dein#tap('unite.vim')
  let g:unite_enable_start_insert = 1
  nnoremap [unite] <Nop>
  nmap ,u  [unite]
  nnoremap [unite]u  :<C-u>Unite<Space>
  nnoremap <silent> [unite]a  :<C-u>Unite airline_themes -auto-preview -winheight=12<CR>
  nnoremap <silent> [unite]b  :<C-u>Unite buffer<CR>
  nnoremap <silent> [unite]c  :<C-u>Unite colorscheme -auto-preview<CR>
  nnoremap <silent> [unite]d  :<C-u>Unite directory<CR>
  nnoremap <silent> [unite]f  :<C-u>Unite buffer file_rec/async:! file file_mru<CR>
  nnoremap <silent> [unite]F  :<C-u>Unite font -auto-preview<CR>
  nnoremap <silent> [unite]h  :<C-u>Unite highlight<CR>
  nnoremap <silent> [unite]m  :<C-u>Unite mark -auto-preview<CR>
  nnoremap <silent> [unite]o  :<C-u>Unite outline<CR>
  nnoremap <silent> [unite]r  :<C-u>Unite register<CR>
  nnoremap <silent> [unite]s  :<C-u>Unite source<CR>
  nnoremap <silent> [unite]t  :<C-u>Unite tag<CR>
  nnoremap <silent> [unite]T  :<C-u>Unite tweetvim<CR>
  nnoremap <silent><expr> [unite]/ line('$') > 5000 ?
        \ ":\<C-u>Unite -buffer-name=search -no-split -start-insert line/fast\<CR>" :
        \ ":\<C-u>Unite -buffer-name=search -start-insert line\<CR>"
  nnoremap <Space>ub  :<C-u>UniteWithCursorWord boost-online-doc<CR>
  nnoremap [unite]M   :<C-u>Unite mplayer
endif

if dein#tap('deoplete.nvim')
  let g:deoplete#enable_at_startup = 1
endif
if dein#tap('neocomplete.vim')
  " inoremap <expr><CR>  neocomplete#smart_close_popup() . "\<CR>"
  " inoremap <expr><CR>  pumvisible() ? neocomplete#smart_close_popup() . "\<CR>" : "\<CR>"
  let g:neocomplete#enable_at_startup = 1
  let g:neocomplete#sources#dictionary#dictionaries = {
        \ 'default': '',
        \ 'cpp': expand('~/github/VimDict/cpp.txt')
        \}
endif
if dein#tap('neocomplcache')
  inoremap <expr><CR>  neocomplcache#smart_close_popup() . "\<CR>"
  let g:neocomplcache_enable_at_startup = 1
  let g:neocomplcache_force_overwrite_completefunc = 1
  if !exists('g:neocomplcache_force_omni_patterns')
    let g:neocomplcache_force_omni_patterns = {}
  endif
  let g:neocomplcache_dictionary_filetype_lists = {
        \ 'default': '',
        \ 'cpp': expand('~/github/VimDict/cpp.txt')
        \}
  " let g:neocomplcache_force_omni_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|::'
endif

if dein#tap('neosnippet')
  imap <C-k>  <Plug>(neosnippet_expand_or_jump)
  smap <C-k>  <Plug>(neosnippet_expand_or_jump)
  imap <expr><TAB>  neosnippet#expandable() <Bar><Bar> neosnippet#jumpable() ?
        \ "\<Plug>(neosnippet_expand_or_jump)" : pumvisible() ? "\<C-n>" : "\<TAB>"
  smap <expr><TAB>  neosnippet#expandable() <Bar><Bar> neosnippet#jumpable() ?
        \ "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
  let g:neosnippet#snippets_directory = '~/github/koturn-snippets/neosnippets'
  let g:neosnippet#expand_word_boundary = 1
  if has('conceal')
    " set conceallevel=2 concealcursor=i
    set conceallevel=0 concealcursor=incv
  endif
endif

if dein#tap('vimshell')
  function! s:vimshell_on_source() abort
    if s:is_cui
      let g:vimshell_prompt = "('v ')$ "
    else
      let s:my_vimshell_prompt_counter = -1
      let s:my_vimshell_anim = [
            \ "(´:_:`)",
            \ "( ´:_:)",
            \ "(  ´:_)",
            \ "(   ´:)",
            \ "(    ´)",
            \ "(     )",
            \ "(     )",
            \ "(`    )",
            \ "(:`   )",
            \ "(_:`  )",
            \ "(:_:` )",
            \]
      let s:my_vimshell_anim_len = len(s:my_vimshell_anim)
      function! s:my_vimshell_dynamic_prompt() abort
        let s:my_vimshell_prompt_counter += 1
        return s:my_vimshell_anim[s:my_vimshell_prompt_counter % s:my_vimshell_anim_len]
      endfunction
      let g:vimshell_prompt_expr = s:sid_prefix . 'my_vimshell_dynamic_prompt() . " $ "'
      let g:vimshell_prompt_pattern = '^([ ´:_:`]\{5}) \$ '
    endif
    let g:vimshell_secondary_prompt = '> '
    let g:vimshell_user_prompt = 'getcwd()'
    let g:vimshell_right_prompt = '"[" . strftime("%Y/%m/%d %H:%M:%S", localtime()) . "]"'
  endfunction
  " if g:at_startup && !argc()
  "   autocmd MyAutoCmd VimEnter * VimShell
  " endif
  call dein#set_hook(g:dein#name, 'hook_source', function('s:vimshell_on_source'))
endif

if dein#tap('omnisharp-vim')
  let g:OmniSharp_selector_ui = 'ctrlp'
  let g:OmniSharp_host = "http://localhost:2000"
  let g:OmniSharp_timeout = 1
  augroup omnisharp_commands
    autocmd!
    "Set autocomplete function to OmniSharp (if not using YouCompleteMe completion plugin)
    autocmd FileType cs setlocal omnifunc=OmniSharp#Complete

    " Synchronous build (blocks Vim)
    "autocmd FileType cs nnoremap <F5> :wa!<cr>:OmniSharpBuild<cr>
    " Builds can also run asynchronously with vim-dispatch installed
    autocmd FileType cs nnoremap <leader>b :wa!<cr>:OmniSharpBuildAsync<cr>
    " automatic syntax check on events (TextChanged requires Vim 7.4)
    " autocmd BufEnter,TextChanged,InsertLeave *.cs SyntasticCheck

    " Automatically add new cs files to the nearest project on save
    autocmd BufWritePost *.cs call OmniSharp#AddToProject()

    "show type information automatically when the cursor stops moving
    autocmd CursorHold *.cs call OmniSharp#TypeLookupWithoutDocumentation()

    "The following commands are contextual, based on the current cursor position.

    autocmd FileType cs nnoremap gd :OmniSharpGotoDefinition<cr>
    autocmd FileType cs nnoremap <leader>fi :OmniSharpFindImplementations<cr>
    autocmd FileType cs nnoremap <leader>ft :OmniSharpFindType<cr>
    autocmd FileType cs nnoremap <leader>fs :OmniSharpFindSymbol<cr>
    autocmd FileType cs nnoremap <leader>fu :OmniSharpFindUsages<cr>
    "finds members in the current buffer
    autocmd FileType cs nnoremap <leader>fm :OmniSharpFindMembers<cr>
    " cursor can be anywhere on the line containing an issue
    autocmd FileType cs nnoremap <leader>x  :OmniSharpFixIssue<cr>
    autocmd FileType cs nnoremap <leader>fx :OmniSharpFixUsings<cr>
    autocmd FileType cs nnoremap <leader>tt :OmniSharpTypeLookup<cr>
    autocmd FileType cs nnoremap <leader>dc :OmniSharpDocumentation<cr>
    "navigate up by method/property/field
    autocmd FileType cs nnoremap <C-K> :OmniSharpNavigateUp<cr>
    "navigate down by method/property/field
    autocmd FileType cs nnoremap <C-J> :OmniSharpNavigateDown<cr>
  augroup END
  " Contextual code actions (requires CtrlP or unite.vim)
  nnoremap <leader><space> :OmniSharpGetCodeActions<cr>
  " Run code actions with text selected in visual mode to extract method
  vnoremap <leader><space> :call OmniSharp#GetCodeActions('visual')<cr>

  " rename with dialog
  nnoremap <leader>nm :OmniSharpRename<cr>
  nnoremap <F2> :OmniSharpRename<cr>
  " rename without dialog - with cursor on the symbol to rename... ':Rename newname'
  command! -nargs=1 Rename :call OmniSharp#RenameTo("<args>")

  " Force OmniSharp to reload the solution. Useful when switching branches etc.
  nnoremap <leader>rl :OmniSharpReloadSolution<cr>
  nnoremap <leader>cf :OmniSharpCodeFormat<cr>
  " Load the current .cs file to the nearest project
  nnoremap <leader>tp :OmniSharpAddToProject<cr>

  " (Experimental - uses vim-dispatch or vimproc plugin) - Start the omnisharp server for the current solution
  nnoremap <leader>ss :OmniSharpStartServer<cr>
  nnoremap <leader>sp :OmniSharpStopServer<cr>

" Add syntax highlighting for types and interfaces
nnoremap <leader>th :OmniSharpHighlightTypes<cr>
endif

if dein#tap('Conque-Shell')
  let g:ConqueTerm_FastMode = 1
  let g:ConqueTerm_ReadUnfocused = 1
  let g:ConqueTerm_InsertOnEnter = 1
  " let g:ConqueTerm_PromptRegex = '^-->'
  " let g:ConqueTerm_TERM = 'xterm'
endif

if dein#tap('incsearch.vim')
  map /   <Plug>(incsearch-forward)
  map ?   <Plug>(incsearch-backward)
  map g/  <Plug>(incsearch-stay)
endif

if dein#tap('memolist.vim')
  " When use NeoBundleLazy, Netrw doesn't work well at the first time
  " So redifine MemoList to call memolist#list() twice.
  command! -nargs=0 MemoList  silent call memolist#list() | call memolist#list()
  " let g:memolist_unite = 1
  " let g:memolist_vimfiler = 1
endif

if dein#tap('vim-altr')
  nmap <Space>a  <Plug>(altr-forward)
  nmap <Space>A  <Plug>(altr-back)
endif

if dein#tap('switch.vim')
  function! s:switch_on_source() abort
    call pluginconfig#switch()
    delfunction pluginconfig#switch
  endfunction
  call dein#set_hook(g:dein#name, 'hook_source', function('s:switch_on_source'))
  nnoremap <silent> <Space>!  :<C-u>Switch<CR>
endif

if dein#tap('vimhelpgenerator')
  let g:vimhelpgenerator_defaultlanguage = 'en'
  let g:vimhelpgenerator_version = ''
  let g:vimhelpgenerator_author = 'Author  : koturn'
  let g:vimhelpgenerator_contents = {
        \ 'contents': 1, 'introduction': 1, 'usage': 1, 'interface': 1,
        \ 'variables': 1, 'commands': 1, 'key-mappings': 1, 'functions': 1,
        \ 'setting': 0, 'todo': 1, 'changelog': 0
        \}
endif

if dein#tap('vim-reanimate')
  function! s:reanimate_save_point_completelist(arglead, ...) abort
    return filter(reanimate#save_points(), "v:val =~? '" . a:arglead . "'")
  endfunction
  let g:reanimate_save_dir = $DOTVIM . '/save'
  let g:reanimate_default_save_name = 'reanimate'
  let g:reanimate_sessionoptions = 'curdir,folds,help,localoptions,slash,tabpages,winsize'
endif

if dein#tap('ctrlp.vim')
  let g:ctrlp_path_nolim = 1
  let g:ctrlp_key_loop = 1
  let g:ctrlp_extensions = [
        \ 'mplayer',
        \ 'rebuildfm',
        \ 'mozaicfm',
        \ 'nicovideo',
        \ 'kotemplate'
        \]
  nnoremap <silent> <C-p>  :<C-u>CtrlP<CR>
endif

if dein#tap('startmenu-vim')
  let g:startmenu_interface = 'unite'
endif

if dein#tap('vim-milqi')
  function! s:milqi_complete_unite_source(arglead, ...) abort
    let files = split(globpath(&runtimepath, 'autoload/unite/sources/*.vim', 1), "\n")
    let names = map(files, 'fnamemodify(v:val, ":t:r")')
    return join(names, "\n")
  endfunction
endif

if dein#tap('emmet-vim')
  let g:user_emmet_install_global = 0
  autocmd MyAutoCmd FileType html,css,markdown  EmmetInstall
endif

if dein#tap('eskk.vim')
  function! s:toggle_ime() abort
    if s:is_ime
      set noimdisable
      iunmap <C-j>
      cunmap <C-j>
      lunmap <C-j>
    else
      set imdisable
      imap <C-j>  <Plug>(eskk:toggle)
      cmap <C-j>  <Plug>(eskk:toggle)
      lmap <C-j>  <Plug>(eskk:toggle)
    endif
    let s:is_ime = !s:is_ime
  endfunction
  let s:is_ime = 0
  call s:toggle_ime()
  command! -bar ToggleIME  call s:toggle_ime()

  function! s:eskk_on_source() abort
    " let g:eskk#enable_completion = 1
    let g:eskk#start_completion_length = 2
    let g:eskk#show_candidates_count = 2
    let g:eskk#egg_like_newline_completion = 1
    if s:is_cui
      let g:eskk#marker_henkan = '»'
      let g:eskk#marker_okuri = '*'
      let g:eskk#marker_henkan_select = '«'
      let g:eskk#marker_jisyo_touroku = '?'
    endif
    let g:eskk#dictionary = {'path' : '~/.skk-jisyo', 'sorted' : 0, 'encoding' : 'utf-8'}
    let g:eskk#large_dictionary = {'path' : '~/.eskk/SKK-JISYO.L', 'sorted' : 1, 'encoding' : 'euc-jp'}
    let g:eskk#debug = 0
    " let g:eskk#rom_input_style = 'msime'
    let g:eskk#revert_henkan_style = 'okuri'
    let g:eskk#egg_like_newline = 1
    let g:eskk#keep_state = 1

    function! s:eskk_map() abort
      let table = eskk#table#new('rom_to_hira*', 'rom_to_hira')
      call s:eskk_map_zenkaku(table)
      call eskk#register_mode_table('hira', table)
      let table = eskk#table#new('rom_to_kata*', 'rom_to_kata')
      call s:eskk_map_zenkaku(table)
      call eskk#register_mode_table('kata', table)
    endfunction

    function! s:eskk_map_zenkaku(table) abort
      call a:table.add_map(',', '，')
      call a:table.add_map('.', '．')

      call a:table.add_map('0', '０')
      call a:table.add_map('1', '１')
      call a:table.add_map('2', '２')
      call a:table.add_map('3', '３')
      call a:table.add_map('4', '４')
      call a:table.add_map('5', '５')
      call a:table.add_map('6', '６')
      call a:table.add_map('7', '７')
      call a:table.add_map('8', '８')
      call a:table.add_map('9', '９')

      call a:table.add_map('"', '”')
      call a:table.add_map('#', '＃')
      call a:table.add_map('$', '＄')
      call a:table.add_map('%', '％')
      call a:table.add_map('&', '＆')
      call a:table.add_map("'", '’')
      call a:table.add_map('(', '（')
      call a:table.add_map(')', '）')

      call a:table.add_map('=', '＝')
      call a:table.add_map('~', '～')
      call a:table.add_map('|', '｜')
      call a:table.add_map('@', '＠')
      call a:table.add_map('`', '‘')
      call a:table.add_map('{', '｛')
      call a:table.add_map('+', '＋')
      call a:table.add_map('*', '＊')
      call a:table.add_map('}', '｝')
      call a:table.add_map('<', '＜')
      call a:table.add_map('>', '＞')
      call a:table.add_map('\', '￥')
      call a:table.add_map('_', '＿')
      call a:table.add_map(' ', '　')
    endfunction
    autocmd MyAutoCmd User eskk-initialize-pre  call s:eskk_map()
  endfunction
  " execute 'autocmd MyAutoCmd User dein#source#' . g:dein#name
  "       \ 'call s:eskk_on_source() | delfunction s:eskk_on_source'
  call dein#set_hook(g:dein#name, 'hook_source', function('s:eskk_on_source'))
endif

if dein#tap('vim-quickrun')
  function! s:quickrun_on_source() abort
    call pluginconfig#quickrun()
    delfunction pluginconfig#quickrun
    nnoremap <expr><silent><C-c> quickrun#is_running() ? quickrun#sweep_sessions() : "\<C-c>"
    nnoremap <Leader>r  :<C-u>QuickRun -exec '%C %S'<CR>
  endfunction
  call dein#set_hook(g:dein#name, 'hook_source', function('s:quickrun_on_source'))
endif

if dein#tap('vim-ref')
  nnoremap [ref] <Nop>
  nmap ,r  [ref]
  nnoremap [ref]a   :<C-u>Ref webdict alc<Space>
  nnoremap [ref]e   :<C-u>Ref webdict Ej<Space>
  nnoremap [ref]E   :<C-u>Ref webdict ej<Space>
  nnoremap [ref]j   :<C-u>Ref webdict je<Space>
  nnoremap [ref]dn  :<C-u>Ref webdict dn<Space>
  nnoremap [ref]k   :<C-u>execute 'Ref webdict ej ' . expand('<cword>')<CR>
  function! s:ref_on_source() abort
    call pluginconfig#ref()
    delfunction pluginconfig#ref
  endfunction
  call dein#set_hook(g:dein#name, 'hook_source', function('s:ref_on_source'))
endif

if dein#tap('endwize.vim')
  let g:endwize_add_info_filetypes = ['ruby', 'c', 'cpp']
  let g:endwise_no_mappings = 1
  " autocmd MyAutoCmd FileType lua,ruby,sh,zsh,vb,vbnet,aspvbs,vim  imap <buffer> <silent><CR>  <CR><Plug>DiscretionaryEnd
  autocmd MyAutoCmd FileType lua,ruby,sh,zsh,vb,vbnet,aspvbs,vim
        \ imap <buffer> <silent><expr><CR>
        \ pumvisible() ? neocomplete#smart_close_popup() . '<CR>' : '<CR><Plug>DiscretionaryEnd'
endif

if dein#tap('caw.vim')
  nmap <Leader>c  <Plug>(caw:hatpos:toggle)
  xmap <Leader>c  <Plug>(caw:hatpos:toggle)
endif

if dein#tap('vim-surround')
  nmap ds   <Plug>Dsurround
  nmap cs   <Plug>Csurround
  nmap ys   <Plug>Ysurround
  nmap yS   <Plug>YSurround
  nmap yss  <Plug>Yssurround
  nmap ySs  <Plug>YSsurround
  nmap ySS  <Plug>YSsurround
  xmap S    <Plug>VSurround
  xmap gS   <Plug>VgSurround
endif

if dein#tap('vim-anzu')
  let g:anzu_bottomtop_word = 'search hit BOTTOM, continuing at TOP'
  let g:anzu_topbottom_word = 'search hit TOP, continuing at BOTTOM'
  let g:anzu_status_format  = '%p(%i/%l) %w'
  nmap n  <Plug>(anzu-n-with-echo)zz
  nmap N  <Plug>(anzu-N-with-echo)zz
  nmap *  <Plug>(anzu-star-with-echo)Nzz
  nmap #  <Plug>(anzu-sharp-with-echo)Nzz
  nnoremap g*  g*Nzz
  nnoremap g#  g#Nzz
endif

if dein#tap('vim-visualstar')
  let g:visualstar_no_default_key_mappings = 1
  xmap *   <Plug>(visualstar-*)
  xmap #   <Plug>(visualstar-#)
  xmap g*  <Plug>(visualstar-g*)
  xmap g#  <Plug>(visualstar-g#)
  xmap <kMultiply>     <Plug>(visualstar-*)
  xmap g<kMultiply>    <Plug>(visualstar-g*)
  vmap <S-LeftMouse>   <Plug>(visualstar-*)
  vmap g<S-LeftMouse>  <Plug>(visualstar-g*)
endif

if dein#tap('clever-f.vim')
  map f  <Plug>(clever-f-f)
  map F  <Plug>(clever-f-F)
  map t  <Plug>(clever-f-t)
  map T  <Plug>(clever-f-T)
endif

if dein#tap('rainbowcyclone.vim')
  nmap c/  <Plug>(rc_search_forward)
  nmap c?  <Plug>(rc_search_backward)
  nmap <silent> c*  <Plug>(rc_search_forward_with_cursor)
  nmap <silent> c#  <Plug>(rc_search_backward_with_cursor)
  nmap <silent> cn  <Plug>(rc_search_forward_with_last_pattern)
  nmap <silent> cN  <Plug>(rc_search_backward_with_last_pattern)
endif

if dein#tap('accelerated-jk')
  nmap <C-j> <Plug>(accelerated_jk_gj)
  nmap <C-k> <Plug>(accelerated_jk_gk)
endif

if dein#tap('wandbox-vim')
  let wandbox#default_compiler = {
        \ 'cpp': 'clang-head',
        \ 'ruby': 'ruby-1.9.3-p0',
        \}
  let wandbox#default_options = {
        \ 'cpp': 'warning,optimize,boost-1.55,sprout',
        \ 'haskell': ['haskell-warning', 'haskell-optimize']
        \}
endif

if dein#tap('vim-markdown-quote-syntax')
  let g:markdown_quote_syntax_filetypes = {
        \ 'c': {'start': 'c'},
        \ 'cpp': {'start': 'cpp'},
        \ 'html': {'start': 'html'},
        \ 'java': {'start': 'java'},
        \ 'javascript': {'start': 'javascript'},
        \ 'perl': {'start': 'perl'},
        \ 'python': {'start': 'python'},
        \ 'ruby': {'start': 'ruby'},
        \ 'vim': {'start': 'VimL'}
        \}
endif



if dein#tap('vim-cpp-enhanced-highlight')
  let g:cpp_class_scope_highlight = 1
  let g:cpp_experimental_template_highlight = 1
endif

if dein#tap('vim-clang-format')
  let g:clang_format#style_options = {
        \ 'BasedOnStyle': 'Google',
        \ 'AccessModifierOffset': -2,
        \ 'AlignEscapedNewlinesLeft': 'false',
        \ 'AlignTrailingComments': 'false',
        \ 'AlwaysBreakAfterDefinitionReturnType': 'All',
        \ 'AlwaysBreakAfterReturnType': 'All',
        \ 'BraceWrapping': {
        \   'AfterClass': 'true',
        \   'AfterEnum': 'true',
        \   'AfterFunction': 'true',
        \   'AfterNamespace': 'true',
        \   'AfterStruct': 'true',
        \   'AfterUnion': 'true'
        \ },
        \ 'BreakBeforeBraces': 'Custom',
        \ 'BreakConstructorInitializersBeforeComma': 'true',
        \ 'ColumnLimit': 0,
        \ 'ConstructorInitializerAllOnOneLineOrOnePerLine': 'false',
        \ 'ConstructorInitializerIndentWidth': 2,
        \ 'ContinuationIndentWidth': 2,
        \ 'IndentWidth': 2,
        \ 'TabWidth': 4
        \}
  map ,x  <Plug>(operator-clang-format)
endif

if dein#tap('vim-marching')
  if g:is_windows
    let g:marching_clang_command = 'C:/CommonUtil/LLVM/clang.exe'
  else
    let g:marching_clang_command = '/cygdrive/c/CommonUtil/LLVM/clang.exe'
  endif
  let g:marching#clang_command#options = {
        \ 'cpp': '-std=gnu++1y'
        \}
  if g:is_windows
    let g:marching_include_paths = [
          \ 'C:/cygwin64/usr/include',
          \ 'C:/cygwin64/lib/gcc/x86_64-pc-cygwin/4.8.3/include/c++'
          \]
  else
    let g:marching_include_paths = [
          \ '/usr/include',
          \ '/lib/gcc/x86_64-pc-cygwin/4.8.3/include/c++'
          \]
  endif
  let g:marching_enable_neocomplete = 1
  if !exists('g:neocomplete#force_omni_input_patterns')
    let g:neocomplete#force_omni_input_patterns = {}
  endif
  let g:neocomplete#force_omni_input_patterns.cpp =
        \ '[^.[:digit:] *\t]\%(\.\|->\)\w*\|\h\w*::\w*'
endif

if dein#tap('vim-snowdrop')
  let g:snowdrop#libclang_directory = 'C:/msys64/mingw64/lib'
  let g:snowdrop#command_options = {
        \ 'cpp': '-std=c++1y',
        \}
  let g:snowdrop#include_paths = {
        \ 'cpp': [
        \   'C:/msys64/mingw64/include/c++/5.3.0'
        \ ]
        \}
  let g:neocomplete#sources#snowdrop#enable = 1
  let g:neocomplete#skip_auto_completion_time = ''
endif

if dein#tap('vim-clang')
  let g:clang_c_options = '-std=c11'
  let g:clang_cpp_options = '-std=c++1z -stdlib=libc++ --pedantic-errors'
endif

if dein#tap('kuin_vim')
  autocmd MyAutoCmd BufReadPre *.kn  setfiletype kuin
endif

if dein#tap('gnuplot.vim')
  autocmd MyAutoCmd BufReadPre *.plt  setfiletype gnuplot
endif

if dein#tap('vim-niji')
  " function! neobundle#tapped.hooks.on_post_source(bundle) abort
  "   let matching_filetypes = get(g:, 'niji_matching_filetypes', ['lisp', 'scheme', 'clojure'])
  "   if count(matching_filetypes, &ft) > 0 || exists('g:niji_match_all_filetypes')
  "     call niji#highlight()
  "   endif
  " endfunction
endif

if dein#tap('goyo.vim')
  function! s:goyo_on_source() abort
    let g:goyo_margin_top = 0
    let g:goyo_margin_bottom = 0
    let g:goyo_linenr = 1
    let g:goyo_width = 100

    function! s:goyo_before() abort
      setlocal colorcolumn=+1,+21
      highlight ColorColumn ctermbg=Red guibg=Red
    endfunction
    function! s:goyo_after() abort
      " Do nothing
    endfunction
    let g:goyo_callbacks = [function('s:goyo_before'), function('s:goyo_after')]
  endfunction
  call dein#set_hook(g:dein#name, 'hook_source', function('s:goyo_on_source'))
endif

if dein#tap('presen-vim')
  " augroup MyAutoCmd
  " au BufReadPre *.vp  setfiletype vimpresen
    " au FileType presen,vimshell hi WhitespaceEOL term=NONE ctermbg=NONE guibg=NONE
    " au FileType presen,vimshell execute 'au MyAutoCmd BufEnter <buffer> hi WhitespaceEOL term=NONE ctermbg=NONE guibg=NONE'
    " au FileType presen,vimshell execute 'au MyAutoCmd BufLeave <buffer> hi WhitespaceEOL term=underline ctermbg=Blue guibg=Blue'

    " au FileType presen hi TabEOL term=NONE ctermbg=NONE guibg=NONE
    " au FileType presen,vimshell hi SpaceTab term=NONE ctermbg=NONE guibg=NONE guisp=NONE
    " au FileType presen,vimshell execute 'au MyAutoCmd BufEnter <buffer> hi SpaceTab term=NONE ctermbg=NONE guibg=NONE'
    " au FileType presen,vimshell execute 'au MyAutoCmd BufLeave <buffer> hi SpaceTab term=underline ctermbg=Magenta guibg=Magenta guisp=Magenta'
    " au FileType presen hi JPSpace term=NONE ctermbg=NONE guibg=NONE
  " augroup END
endif

if dein#tap('vim-showtime')
  " augroup MyAutoCmd
    " au FileType showtime nested hi WhitespaceEOL term=NONE ctermbg=NONE guibg=NONE
    " au FileType showtime nested hi TabEOL term=NONE ctermbg=NONE guibg=NONE
    " au FileType showtime nested hi SpaceTab term=NONE ctermbg=NONE guibg=NONE guisp=NONE
    " au FileType showtime nested hi JPSpace term=NONE ctermbg=NONE guibg=NONE
  " augroup END
endif

if dein#tap('previm')
  function! s:previm_on_source() abort
    call dein#source('open-browser.vim')
  endfunction
  call dein#set_hook(g:dein#name, 'hook_source', function('s:previm_on_source'))
endif

if dein#tap('vim-fontzoom')
  nmap +  <Plug>(fontzoom-larger)
  nmap -  <Plug>(fontzoom-smaller)
  map  <C-ScrollWheelUp>    <Plug>(fontzoom-larger)
  map! <C-ScrollWheelUp>    <Plug>(fontzoom-larger)
  map  <C-ScrollWheelDown>  <Plug>(fontzoom-smaller)
  map! <C-ScrollWheelDown>  <Plug>(fontzoom-smaller)
endif

if dein#tap('open-browser.vim')
  function! s:execute_with_selected_text(command) abort
    if a:command !~? '%s'
      return
    endif
    let reg = '"'
    let [save_reg, save_type] = [getreg(reg), getregtype(reg)]
    normal! gvy
    let selectedText = @"
    call setreg(reg, save_reg, save_type)
    if selectedText ==# ''
      return
    endif
    execute printf(a:command, selectedText)
  endfunction
  nmap <Space>o  <Plug>(openbrowser-smart-search)
  nmap <Space>O  :<C-u>OpenBrowserSmartSearch<Space>
  nnoremap gz  vi':<C-u>call <SID>execute_with_selected_text('call openbrowser#open("https://github.com/%s")')<CR>
  vnoremap gz  :<C-u>call <SID>execute_with_selected_text('call openbrowser#open("https://github.com/%s")')<CR>
endif

if dein#tap('TweetVim')
  let g:tweetvim_original_hi = 1
  let g:tweetvim_tweet_per_page = 50
  let g:tweetvim_display_source = 1
  let g:tweetvim_display_time = 1
  " let g:tweetvim_display_icon = 1

  nnoremap [tweetvim] <Nop>
  nmap ,t  [tweetvim]
  " nnoremap [ref]t
  "       \ :<C-u>call tmpwin#toggle(['normal! gg', 'setl nohidden'], 'TweetVimHomeTimeline')<CR>
  nnoremap [tweetvim]tc  :<C-u>call tweetvim#say#current_line()<CR>
  nnoremap [tweetvim]ts  :<C-u>call tweetvim#say#open_with_account()<CR>
  nnoremap [tweetvim]th  :<C-u>call tmpwin#toggle('TweetVimHomeTimeline')<CR>
endif


if dein#tap('gmail.vim')
  " g:gmail_address is defined in ~/.vim/.private.vim
  let g:gmail_user_name = get(g:private, 'gmail_address', '')
endif

if dein#tap('rogue.vim')
  let g:rogue#name = 'koturn'
  let g:rogue#japanese = 1
endif

if dein#tap('jazzradio.vim')
  nnoremap <silent> [unite]j  :<C-u>Unite jazzradio<CR>
endif

if dein#tap('DrawIt')
  map <Leader>di  <Plug>DrawItStart
  map <Leader>ds  <Plug>DrawItStop
endif

if dein#tap('vim-sugarpot')
  let g:sugarpot_convert = get(g:private, 'imagemagick_path', 'convert')
  let g:sugarpot_convert_resize = '50%x25%'
endif

if dein#tap('vim-clipboard')
  nnoremap <silent> ,<Space>  :<C-u>PutClip<CR>
  nnoremap <silent> <Space>,  :<C-u>GetClip<CR>
  if has('unnamedplus')
    let g:clipboard#clip_register = '@+'
  endif
endif

if dein#tap('vim-kotemplate')
  augroup KoTemplate
    autocmd!
    autocmd BufNewFile * call dein#source('vim-kotemplate') | call kotemplate#auto_action()
  augroup END
  function! s:kotemplate_on_source() abort
    function! s:get_filename(tag) abort
      let filename = fnamemodify(expand('%'), ':t')
      return filename ==# '' ? a:tag : filename
    endfunction
    function! s:get_basefilename(tag) abort
      let basefilename = fnamemodify(expand('%'), ':t:r')
      return basefilename ==# '' ? a:tag : basefilename
    endfunction
    function! s:get_filename_camel2capital(tag) abort
      let basefilename = fnamemodify(expand('%'), ':t:r')
      let basefilename = toupper(substitute(basefilename, '.\zs\(\u\)', '_\l\1', 'g'))
      return basefilename ==# '' ? a:tag : basefilename
    endfunction
    function! s:get_filename_snake2pascal(tag) abort
      let basefilename = fnamemodify(expand('%'), ':t:r')
      let basefilename = substitute(basefilename, '^\(\l\)', '\u\1', '')
      let basefilename = substitute(basefilename, '_\(\l\)', '\u\1', 'g')
      return basefilename ==# '' ? a:tag : basefilename
    endfunction
    function! s:get_include_guard(tag) abort
      return s:get_filename_camel2capital(a:tag) . '_' . toupper(fnamemodify(expand('%'), ':e'))
    endfunction
    function! s:move_cursor(tag) abort
      if search(a:tag)
        normal! "_da>
      endif
      return ''
    endfunction
    let g:kotemplate#filter = {
          \ 'pattern': {
          \   'c': ['*.{c,h}'],
          \   'cpp': ['*.{c,cc,cpp,cxx,h,hpp}'],
          \   'cs': ['*.cs'],
          \   'go': ['*.go'],
          \   'kuin': ['*.kn'],
          \   'lua': ['*.lua'],
          \   'lisp': ['*.lisp'],
          \   'scheme': ['*.scm'],
          \   'html': ['*.html'],
          \   'java': ['*.java'],
          \   'javascript': ['*.js'],
          \   'make': ['Makefile/*', 'Makefile', '*.mk'],
          \   'markdown': ['*.md'],
          \   'perl': ['*.perl'],
          \   'php': ['*.php'],
          \   'python': ['*.py'],
          \   'ruby': ['*.rb'],
          \   'sh': ['*.sh'],
          \   'vim': ['*.vim'],
          \   'xml': ['*.xml'],
          \ },
          \ 'function': 'glob'
          \}
    let g:kotemplate#enable_autocmd = 1
    let g:kotemplate#auto_filetypes = keys(g:kotemplate#filter.pattern)
    let g:kotemplate#autocmd_function = 'unite'
    " let g:kotemplate#autocmd_function = 'unite'
    let g:kotemplate#dir = '~/github/kotemplate/'
    let g:kotemplate#tag_actions = [{
          \ '<+AUTHOR+>': 'koturn',
          \ '<+MAIL_ADDRESS+>': get(g:private, 'gmail_address', ''),
          \ '<+DATE+>': 'strftime("%Y %m/%d")',
          \ '<+DATEFULL+>': 'strftime("%Y-%m-%d %H:%M:%S")',
          \ '<+YEAR+>': 'strftime("%Y")',
          \ '<+FILE+>': function('s:get_filename'),
          \ '<+FILEBASE+>': function('s:get_basefilename'),
          \ '<+FILE_CAPITAL+>': function('s:get_filename_camel2capital'),
          \ '<+FILE_PASCAL+>': function('s:get_filename_snake2pascal'),
          \ '<+INCLUDE_GUARD+>': function('s:get_include_guard'),
          \ '<+DIR+>': 'split(expand("%:p:h"), "/")[-1]',
          \ '<%=\(.\{-}\)%>': 'eval(submatch(1))',
          \}, {
          \ '<+CURSOR+>': function('s:move_cursor'),
          \}]
    let vim_project_expr = 'fnamemodify(substitute(%%PROJECT%%, "^vim-", "", "g"), ":t:r") . ".vim"'
    let g:kotemplate#projects = {
          \ 'vim': {
          \   'autoload': {vim_project_expr : 'Vim/autoload.vim'},
          \   'plugin': {vim_project_expr : 'Vim/plugin.vim'},
          \   'README.md': 'Markdown/ReadMe.md',
          \   'LICENSE': 'LicenseFile/MIT'
          \ }, 'vim-vital': {
          \   'autoload/vital/__latest__/Altcomplete.vim': 'Vim/vital.vim',
          \ }, 'java': {
          \   'src': {'Main.java': 'Java/Main.java'},
          \   'bin': {},
          \   'build.xml': 'Java/build.xml',
          \   'Makefile': 'Makefile/java.mk',
          \   '.gitignore': 'gitfile/java.gitignore'
          \ }, 'web': {
          \   'index.html': 'HTML/html5.html',
          \   'css/main.css': {},
          \   'js/main.js': 'JavaScript/module.js'
          \ }, 'electron': {
          \   'index.html': 'HTML/html5.html',
          \   'main.js': 'JavaScript/electron.js',
          \   'release.js': 'JavaScript/electron_release.js',
          \   'package.json': 'Json/electron_package.json'
          \ }, 'qt': {
          \   'main.cpp': 'Cpp/Qt/main.cpp',
          \   'MainWindow.cpp': 'Cpp/Qt/MainWindow.cpp',
          \   'MainWindow.h': 'Cpp/Qt/MainWindow.h',
          \   'MainWindow.ui': 'QtFiles/MainWindow.ui',
          \   'Template.pro': 'QtFiles/Project.pro',
          \   '.gitignore': 'gitfile/qt.gitignore'
          \ }
          \}
  endfunction
  call dein#set_hook(g:dein#name, 'hook_source', function('s:kotemplate_on_source'))
endif

if dein#tap('vim-mplayer')
  if g:is_windows
    let mplayer#mplayer = 'C:/CommonUtil/mplayer/mplayer.exe'
  else
    let mplayer#mplayer = '/c/CommonUtil/mplayer/mplayer.exe'
    let mplayer#use_win_mplayer_in_cygwin = 1
  endif
  let g:mplayer#suffixes = ['mp3', 'wav', 'ogg', 'flv', 'wmv', 'mp4']
  let g:mplayer#default_dir = '~/Music/'
endif

if dein#tap('movewin.vim')
  map  <Left>   <Plug>(movewin-left)
  map! <Left>   <Plug>(movewin-left)
  map  <Down>   <Plug>(movewin-down)
  map! <Down>   <Plug>(movewin-down)
  map  <Up>     <Plug>(movewin-up)
  map! <Up>     <Plug>(movewin-up)
  map  <Right>  <Plug>(movewin-right)
  map! <Right>  <Plug>(movewin-right)
endif

if dein#tap('vim-resizewin')
  map  <F11>      <Plug>(resizewin-toggle-fullscreen)
  map! <F11>      <Plug>(resizewin-toggle-fullscreen)
  map  <M-F11>    <Plug>(resizewin-toggle-fullscreen)
  map! <M-F11>    <Plug>(resizewin-toggle-fullscreen)
  map  <S-Left>   <Plug>(resizewin-contract-columns)
  map! <S-Left>   <Plug>(resizewin-contract-columns)
  map  <S-Down>   <Plug>(resizewin-expand-lines)
  map! <S-Down>   <Plug>(resizewin-expand-lines)
  map  <S-Up>     <Plug>(resizewin-contract-lines)
  map! <S-Up>     <Plug>(resizewin-contract-lines)
  map  <S-Right>  <Plug>(resizewin-expand-columns)
  map! <S-Right>  <Plug>(resizewin-expand-columns)
endif

if dein#tap('vim-podcast')
  let podcast#verbose = 1
endif

if dein#tap('vim-rebuildfm')
  let rebuildfm#play_command = mplayer#mplayer
  let rebuildfm#verbose = 1
endif

if dein#tap('vim-mozaicfm')
  let mozaicfm#play_command = mplayer#mplayer
  let mozaicfm#verbose = 1
endif

if dein#tap('vim-nicovideo')
  let nicovideo#mplayer = 'C:/CommonUtil/smplayer/mplayer/mplayer'
  let nicovideo#mail_address = g:private.gmail_address
  let nicovideo#password = g:private.nicovideo_password
  let nicovideo#crt_file = expand('~/curl-ca-bundle.crt')
endif

if dein#tap('vim-brainfuck')
  autocmd MyAutoCmd BufNewFile,BufRead *.b,*.brainfuck  setfiletype brainfuck
  let g:brainfuck#verbose = 1
  let g:brainfuck#use_lua = 1
endif
" }}}
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
  colorscheme hybrid
else
  colorscheme default
endif
set hlsearch
set secure
" }}}
