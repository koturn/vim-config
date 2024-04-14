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
let g:is_windows =  has('win32')
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

function! s:get_sid_prefix() abort " {{{
  return matchstr(expand('<sfile>'), '\zs<SNR>\d\+_\zeget_sid_prefix$')
endfunction " }}}
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

if !exists('$MYGVIMRC')
  let $MYGVIMRC = expand('~/.vim/gvimrc')
endif
let $DOTVIM = expand('~/.vim')
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

augroup MyAutoCmd " {{{
  autocmd!
augroup END " }}}

if has('reltime') && g:at_startup
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

  function! s:Timer.new(name) abort " {{{
    let timer = copy(self)
    let timer.name = a:name
    call timer.start()
    return timer
  endfunction " }}}

  function! s:Timer.start() abort dict " {{{
    if self.is_stopped
      let self.is_stopped = 0
      let self.start_time = reltime()
    endif
  endfunction " }}}

  function! s:Timer.stop() abort dict " {{{
    if !self.is_stopped
      let self.elapsed_time += str2float(reltimestr(reltime(self.start_time)))
      let self.is_stopped = 1
    endif
  endfunction " }}}

  function! s:Timer.get_elapsed_time() abort dict " {{{
    return self.elapsed_time + (self.is_stopped ? 0.0 : str2float(reltimestr(reltime(self.start_time))))
  endfunction " }}}

  function! s:Timer.show() abort dict " {{{
    let t = s:convert_time(self.get_elapsed_time())
    echo printf('%16s: %2d days %02d:%02d:%02d.%1d', self.name, t.day, t.hour, t.minute, t.second, t.msec)
  endfunction " }}}

  function! s:convert_time(time) abort " {{{
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
  endfunction " }}}

  let s:startupdate = strftime('%Y/%m/%d(%a) %H:%M:%S')
  let s:timer_launched = s:Timer.new('Launched Time')
  let s:timer_active = s:Timer.new('Active Time')
  let s:timer_used = s:Timer.new('Used Time')
  unlet s:Timer

  function! s:show_time_info() abort " {{{
    echo 'Launched at:' s:startupdate
    call s:timer_launched.show()
    call s:timer_active.show()
    call s:timer_used.show()
  endfunction " }}}
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

" ------------------------------------------------------------------------------
" Basic settings {{{
" ------------------------------------------------------------------------------
let s:_executable = {}
function! s:executable(cmd) abort " {{{
  if !has_key(s:_executable, a:cmd)
    let s:_executable[a:cmd] = executable(a:cmd)
  endif
  return s:_executable[a:cmd]
endfunction " }}}

if !s:is_nvim
  packadd! matchit
  " source $VIMRUNTIME/macros/matchit.vim
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
  autocmd MyAutoCmd FileType c,man,sh,zsh  setlocal keywordprg=:KeywordprgMan
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
  setglobal grepprg=ag\ --vimgrep\ -iS
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

if s:is_cui && exists('&termguicolors') && ($COLORTERM ==# 'truecolor' || g:is_windows && has('vtp'))
  if s:is_tmux && !has('nvim')
    let &t_8f = "\e[38;2;%lu;%lu;%lum"
    let &t_8b = "\e[48;2;%lu;%lu;%lum"
  endif
  set termguicolors
endif

if !s:is_cui
  set guioptions=M
endif

if has('balloon_eval') || has('balloon_eval_term')
  function! s:balloon_expr() abort " {{{
    return vimrc#get_highlight_info_lines(v:beval_lnum, v:beval_col)
  endfunction " }}}
  let &g:balloonexpr = s:sid_prefix . 'balloon_expr()'
  set ballooneval
  if has('balloon_eval_term')
    set balloonevalterm
  endif
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
set wildignore+=*.meta
set wildmenu wildmode=longest:full,full
if has('patch-8.2.4325')
  set wildoptions=pum
else
  set wildoptions=tagfile
endif
set showcmd
set cmdheight=2
set history=200
set incsearch
if has('mouse')
  set mouse=a mousemodel=popup
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
" Configuration for custom patches {{{
" ------------------------------------------------------------------------------
if has('clpum')
  set wildmenu wildmode=longest,popup
  set clpumheight=40
  autocmd MyAutoCmd ColorScheme * highlight! link ClPmenu Pmenu
endif

if has('tabsidebar')
  function! s:tabsidebar() abort
    try
      return join([printf('TabPage:%d', g:actual_curtabpage)] + map(
            \ filter(getwininfo(), 'v:val.tabnr == g:actual_curtabpage'),
            \ "printf('  %s', v:val.terminal ? '[Terminal]' : v:val.quickfix ? '[QuickFix]' : v:val.loclist ? '[LocList]' : fnamemodify(bufname(v:val.bufnr), ':t'))"), "\n")
    catch
      return string(v:exception)
    endtry
  endfunction
  set showtabsidebar=1
  set tabsidebarcolumns=20
  set tabsidebarwrap
  execute 'set tabsidebar=%!' . s:sid_prefix . 'tabsidebar()'
  nnoremap <silent> <Space>t  :<C-u>let &showtabsidebar = &showtabsidebar ? 0 : 1<CR>
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


function! s:set_term_mintty() abort " {{{
  let &t_ti .= "\e[2 q"
  let &t_SI .= "\e[6 q"
  let &t_EI .= "\e[2 q"
  let &t_te .= "\e[0 q"
  set ttymouse=sgr
endfunction " }}}

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
function! s:checktime() abort " {{{
  if bufname('%') !~# '^\%(\|[Command Line]\)$' && &filetype !~# '^\%(help\|qf\)$'
    checktime
  endif
endfunction " }}}
autocmd MyAutoCmd WinEnter,FocusGained * call s:checktime()

autocmd MyAutoCmd FileType help,qf  call vimrc#map_easy_close()
autocmd MyAutoCmd CmdwinEnter *  call vimrc#map_easy_close()

let s:dict_base_dir = '~/github/VimDict/'
function! s:add_dictionary() abort " {{{
  let &l:dictionary .= ','
  execute 'setlocal dictionary+=' . s:dict_base_dir . &filetype . '.txt'
endfunction " }}}
autocmd MyAutoCmd FileType *  call s:add_dictionary()
" }}}

" ------------------------------------------------------------------------------
" Commands and autocmds {{{
" ------------------------------------------------------------------------------
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


nnoremap <silent> <Leader><Tab>  :<C-u>call vimrc#toggle_tab_space(1, &l:tabstop, 1, line('$'))<CR>
nnoremap <C-w><Space> :<C-u>SmartSplit<CR>

autocmd MyAutoCmd BufWritePre * call vimrc#auto_mkdir(expand('<afile>:p:h'), v:cmdbang)
autocmd MyAutoCmd FileType c,cpp
      \ command! -bar -bang -range=% -buffer FormatCProgram
      \ <line1>,<line2>call vimrc#format_c_program(<bang>0)

if exists('##TerminalOpen')
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
endif
nnoremap <silent> zp  :<C-u>call vimrc#preview_fold(&previewheight)<CR>


if s:executable('chmod')
  augroup Permission " {{{
    autocmd!
    autocmd BufNewFile * autocmd Permission BufWritePost <buffer>  call s:permission_644()
  augroup END " }}}
  function! s:permission_644() abort " {{{
    autocmd! Permission BufWritePost <buffer>
    silent call s:system((stridx(getline(1), '#!') ? 'chmod 644 ' : 'chmod 755 ') . shellescape(expand('%')))
  endfunction " }}}
elseif s:executable('icacls')
  augroup Permission " {{{
    autocmd!
    autocmd BufNewFile * autocmd Permission BufWritePost <buffer>  call s:permission_644()
  augroup END " }}}
  function! s:permission_644() abort " {{{
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
  endfunction " }}}
endif


xnoremap <silent> <Leader>e  :<C-u>call vimrc#exec_selected_text()<CR>
xnoremap ,r  :<C-u>call vimrc#store_selected_text()<CR>:<C-u>.,$s/<C-r>"//gc<Left><Left><Left>
xnoremap ,R  :<C-u>call vimrc#store_selected_text(0)<CR>:<C-u>.,$s/\M<C-r>"//gc<Left><Left><Left>
xnoremap ,<C-r>  :<C-u>call vimrc#store_selected_text(1)<CR>:<C-u>.,$s/\M<C-r>"//gc<Left><Left><Left>
xnoremap ,<M-r>  :<C-u>call vimrc#store_selected_text(2)<CR>:<C-u>.,$s/\M<C-r>"//gc<Left><Left><Left>
xnoremap ,s  :<C-u>call vimrc#store_selected_text()<CR>/<C-u><C-r>"<CR>N
xnoremap ,S  :<C-u>call vimrc#store_selected_text(0)<CR>/<C-u>\m<C-r>"<CR>N
xnoremap ,<C-s>  :<C-u>call vimrc#store_selected_text(1)<CR>/<C-u>\M<C-r>"<CR>N
xnoremap ,<M-s>  :<C-u>call vimrc#store_selected_text(2)<CR>/<C-u>\v<C-r>"<CR>N
xnoremap ,g  :<C-u>call vimrc#store_selected_text()<CR>:<C-u>vimgrep /<C-r>"/ **/*<Left><Left><Left><Left><Left><Left>

nnoremap <silent> <M-p>  :<C-u>call vimrc#complete_xml_tag()<CR>
inoremap <silent> <M-p>  <Esc>:call vimrc#complete_xml_tag()<CR>
autocmd MyAutoCmd FileType ant,html,xml  inoremap <buffer> </     </<C-x><C-o>
autocmd MyAutoCmd FileType ant,html,xml  inoremap <buffer> <M-a>  </<C-x><C-o>
autocmd MyAutoCmd FileType ant,html,xml  inoremap <buffer> <M-i>  </<C-x><C-o><Esc>%i

" Highlight cursor position vertically and horizontally.
command! -bar ToggleCursorHighlight
      \   if !&cursorline || !&cursorcolumn
      \ |   set   cursorline   cursorcolumn
      \ | else
      \ |   set nocursorline nocursorcolumn
      \ | endif
nnoremap <silent> <Leader>h  :<C-u>ToggleCursorHighlight<CR>
autocmd MyAutoCmd CursorHold,CursorHoldI,WinEnter *  set cursorline cursorcolumn
autocmd MyAutoCmd CursorMoved,CursorMovedI,WinLeave *  set nocursorline nocursorcolumn

vnoremap <silent> /  :<C-u>call vimrc#range_search('/')<CR>
vnoremap <silent> ?  :<C-u>call vimrc#range_search('?')<CR>

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
function! s:set_listchars() abort " {{{
  if &enc !=# 'utf-8'
    set list listchars=eol:$,extends:>,nbsp:%,precedes:<,tab:\|\ ,trail:-
    set showbreak=>
    return
  else
    set list listchars=eol:$,extends:»,nbsp:%,precedes:«,tab:¦\ ,trail:-
    set showbreak=»
  endif
endfunction " }}}
call s:set_listchars()
delfunction s:set_listchars

function! s:matchadd(group, pattern, ...) abort " {{{
  if index(map(getmatches(), 'v:val.group'), a:group) != -1 || expand('%:h:t') ==# 'doc' || &filetype ==# 'help'
    return
  endif
  call call('matchadd', extend([a:group, a:pattern], a:000))
endfunction " }}}
function! s:matchdelete(groups) abort " {{{
  for group in type(a:groups) == type('') ? [a:groups] : a:groups
    let matches = getmatches()
    let idx = index(map(copy(matches), 'v:val.group'), group)
    if idx != -1
      call matchdelete(matches[idx].id)
    endif
  endfor
endfunction " }}}

augroup MyHighlight " {{{
  au ColorScheme * hi WhitespaceEOL term=underline ctermbg=Blue guibg=Blue
  au VimEnter,BufRead * call s:matchadd('WhitespaceEOL', ' \+$') | au MyHighlight WinEnter <buffer> call s:matchadd('WhitespaceEOL', ' \+$')

  au ColorScheme * hi TabEOL term=underline ctermbg=DarkGreen guibg=DarkGreen
  au VimEnter,BufRead * call s:matchadd('TabEOL', '\t\+$') | au MyHighlight WinEnter <buffer> call s:matchadd('TabEOL', '\t\+$')

  au ColorScheme * hi SpaceTab term=underline ctermbg=Magenta guibg=Magenta guisp=Magenta
  au VimEnter,BufRead * call s:matchadd('SpaceTab', ' \+\ze\t\|\t\+\ze ') | au MyHighlight WinEnter <buffer> call s:matchadd('SpaceTab', ' \+\ze\t\|\t\+\ze ')

  au Colorscheme * hi link JPSpace Error
  au VimEnter,WinEnter,BufRead * call s:matchadd('JPSpace', '　')  " \%u3000

  au FileType {defx,help,vimshell,presen,rogue,showtime,vimcastle} call s:matchdelete(['WhitespaceEOL', 'TabEOL', 'SpaceTab']) | au! MyHighlight WinEnter <buffer>
augroup END " }}}
" }}}

" ------------------------------------------------------------------------------
" Setting for languages. {{{
" ------------------------------------------------------------------------------
let g:c_gnu = 1  " Enable highlight gnu-C keyword in C-mode.
augroup MyAutoCmd " {{{
  au FileType awk           setlocal                      cindent cinkeys-=0#
  au FileType c             setlocal                      cindent cinoptions& cinoptions+=g0,l0,N-s,t0 cinkeys-=0#
  au FileType cpp           setlocal                      cindent cinoptions& cinoptions+=g0,j1,l0,N-s,t0,ws,Ws,(0 cinkeys-=0#
  " )
  au FileType cs            setlocal sw=4 ts=4 sts=4 et   cindent foldmethod=syntax
  au FileType java          setlocal sw=4 ts=4 sts=4 noet cindent cinoptions& cinoptions+=j1
  au FileType javascript    setlocal sw=2 ts=2 sts=2      cindent cinoptions& cinoptions+=j1,J1,(s
  " )
  au FileType make          setlocal sw=4 ts=4 sts=4
  au FileType kuin          setlocal sw=2 ts=2 sts=2 noet
  au FileType python        setlocal sw=4 ts=8 sts=4      cindent cinkeys-=0#
  au FileType make          setlocal sw=4 ts=4 sts=4 noet
  au FileType markdown      setlocal sw=4 ts=4 sts=4 conceallevel=0
  au FileType plaintex,tex  setlocal sw=2 ts=2 sts=2 conceallevel=0
augroup END " }}}

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

nnoremap <expr> m  vimrc#hint_cmd_output('m', 'marks')
nnoremap <expr> `  vimrc#hint_cmd_output('`', 'marks') . 'zz'
nnoremap <expr> '  vimrc#hint_cmd_output("'", 'marks') . 'zz'
nnoremap <expr> "  vimrc#hint_cmd_output('"', 'registers')
if exists('*reg_recording')
  nnoremap <expr> q  reg_recording() ==# '' ? vimrc#hint_cmd_output('q', 'registers') : 'q'
else
  nnoremap <expr> q  vimrc#hint_cmd_output('q', 'registers')
endif
nnoremap <expr> @  vimrc#hint_cmd_output('@', 'registers')

if g:is_windows
  au MyAutoCmd Filetype html nnoremap <buffer> <F5>  :<C-u>lcd %:h<CR>:<C-u>silent !start cmd /c call chrome %<CR>
endif

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
" inoremap <expr> j  getline('.')[col('.') - 2] ==# 'j' ? "\<BS>\<ESC>" : 'j'
" No wait for <Esc>.
if g:is_unix && s:is_cui
  inoremap <silent> <ESC>  <ESC>
endif

inoremap <expr> <C-x>  vimrc#hint_i_ctrl_x()


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
if s:is_cui && !g:is_windows
  " Disable move with cursor-key.
  noremap  <Left> <Nop>
  noremap! <Left> <Nop>
  nnoremap <Left> :<C-u>call vimrc#echo_keymsg(0)<CR>
  inoremap <Left> <Esc>:call vimrc#echo_keymsg(0)<CR>a

  noremap  <Down> <Nop>
  noremap! <Down> <Nop>
  nnoremap <Down> :<C-u>call vimrc#echo_keymsg(1)<CR>
  inoremap <Down> <Esc>:call vimrc#echo_keymsg(1)<CR>a

  noremap  <Up> <Nop>
  noremap! <Up> <Nop>
  nnoremap <Up> :<C-u>call vimrc#echo_keymsg(2)<CR>
  inoremap <Up> <Esc>:call vimrc#echo_keymsg(2)<CR>a

  noremap  <Right> <Nop>
  noremap! <Right> <Nop>
  nnoremap <Right> :<C-u>call vimrc#echo_keymsg(3)<CR>
  inoremap <Right> <Esc>:call vimrc#echo_keymsg(3)<CR>a
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
nnoremap <Del> :<C-u>call vimrc#echo_keymsg(4)<CR>
inoremap <Del> <Esc>:call vimrc#echo_keymsg(4)<CR>a
" Disable delete with <BS>.
" But available in command-line mode.
noremap  <BS> <Nop>
inoremap <BS> <Nop>
nnoremap <BS> :<C-u>call vimrc#echo_keymsg(5)<CR>
inoremap <BS> <Esc>:call vimrc#echo_keymsg(5)<CR>a
" }}}

" ------------------------------------------------------------------------------
" Plugins {{{
" ------------------------------------------------------------------------------
" ------------------------------------------------------------------------------
" Disable default plugins {{{
" ------------------------------------------------------------------------------
let g:loaded_gzip = 1
let g:loaded_logiPat = 1
let g:loaded_rrhelper = 1
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
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1
let g:loaded_netrwSettings = 1
let g:loaded_netrwFileHandlers = 1
" }}}
" ------------------------------------------------------------------------------
" Plugin lists and dein-configuration {{{
" ------------------------------------------------------------------------------
let s:deindir = expand('~/.cache/dein')
let s:dein_install_dir = s:deindir . '/repos/github.com/Shougo/dein.vim'
let &rtp = s:dein_install_dir . ',' . &rtp
if !isdirectory(s:dein_install_dir)
  command! -bar DeinInit  call vimrc#dein_install(s:dein_install_dir)
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

let s:system_name = has('win64') ? 'win64' : has('win32') ? 'win32' : g:is_cygwin ? 'win32unix' : ''
let s:vim_name = s:is_nvim ? 'nvim' : s:is_cui ? 'vim' : 'gvim'
let g:dein#cache_directory = expand(s:deindir . '/cache/' . s:system_name . '_' . s:vim_name)
unlet s:system_name s:vim_name
if dein#load_state(s:deindir)
  call dein#begin(s:deindir)
  call dein#load_toml(expand('~/.vim/dein.toml'), {'lazy': 0})
  call dein#load_toml(expand('~/.vim/dein_lazy.toml'), {'lazy': 1})
  call dein#end()
  let s:on_source_action = "echomsg 'sourced' g:dein#plugin.name"
  for s:plugin in values(dein#get())
    if has_key(s:plugin, 'hook_source')
      let s:plugin.hook_source .= "\n" . s:on_source_action
    else
      let s:plugin.hook_source = s:on_source_action
    endif
  endfor
  unlet s:on_source_action s:plugin
  call dein#save_state()
endif

set packpath+=$VIMRUNTIME/runtime
packadd termdebug
" }}}
" ------------------------------------------------------------------------------
" Plugin-configurations {{{
" ------------------------------------------------------------------------------
if !dein#tap('lightline.vim')
  setglobal statusline=%<%f\ %m\ %r%h%w%{'[fenc='.(&fenc!=#''?&fenc:&enc).']\ [ff='.&ff.']\ [ft='.(&ft==#''?'null':&ft).']\ [ascii=0x'}%B]%=\ (%v,%l)/%L%8P
  if has('syntax')
    augroup MyAutoCmd " {{{
      au InsertEnter * call s:hi_statusline(1)
      au InsertLeave * call s:hi_statusline(0)
      au ColorScheme * silent! let s:highlight_cmd = 'highlight ' . s:get_highlight('StatusLine')
    augroup END " }}}
  endif

  function! s:hi_statusline(mode) abort " {{{
    if a:mode == 1
      highlight StatusLine guifg=white guibg=MediumOrchid gui=none ctermfg=white ctermbg=DarkRed cterm=none
    else
      highlight clear StatusLine
      silent execute s:highlight_cmd
    endif
  endfunction " }}}

  function! s:get_highlight(hi) abort " {{{
    return substitute(substitute(s:redir('highlight ' . a:hi), 'xxx', '', ''), '[\r\n]', '', 'g')
  endfunction " }}}
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
if &t_Co > 2 || !s:is_cui
  syntax enable
  set hlsearch
endif
if !s:is_cui || &t_Co == 256
  function! s:customize_iceberg() abort " {{{
    hi! Function ctermfg=216 guifg=#e2a478
    hi! String ctermfg=109 guifg=#89b8c2
    hi! Type ctermfg=109 gui=NONE guifg=#89b8c2
  endfunction " }}}
  autocmd MyAutoCmd ColorScheme iceberg call s:customize_iceberg()
  colorscheme iceberg
else
  colorscheme default
endif
set secure
" }}}
