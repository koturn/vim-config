" ============================================================
"     __         __                      ____
"    / /______  / /___  ___________     / __ \ _
"   / //_/ __ \/ __/ / / / ___/ __ \   / / / /(_)
"  / ,< / /_/ / /_/ /_/ / /  / / / /  / /_/ / _
" /_/|_|\____/\__/\__,_/_/  /_/ /_/   \____/ ( )
"                                            |/
"
" The setting file for GUI only.
" ============================================================
" ------------------------------------------------------------
" Basic settings
" ------------------------------------------------------------
scriptencoding utf-8

set winaltkeys=no
set guicursor+=a:blinkon0

function! s:get_sid_prefix() abort " {{{
  return matchstr(expand('<sfile>'), '^function \zs<SNR>\d\+_\zeget_sid_prefix$')
endfun " }}}
let s:sid_prefix = s:get_sid_prefix()
delfunction s:get_sid_prefix

" Change cursor color depending on state of IME.
if has('multi_byte_ime') || has('xim')
  autocmd MyAutoCmd Colorscheme * hi CursorIM guifg=NONE guibg=Orange
  set iminsert=0 imsearch=0
endif

if exists('+antialias')
  set antialias
endif

if g:is_windows
  set guifont=Ricty_Diminished_Discord_for_Po:h10:qANTIALIASED,Consolas:h10:qANTIALIASED guifontwide=Ricty_Diminished_Discord_for_Po:h10:qANTIALIASED,MS_Gothic:h9:qANTIALIASED
  set renderoptions=type:directx,renmode:5
  " set langmenu=ja_jp.utf-8
  " source $VIMRUNTIME/delmenu.vim
  " source $VIMRUNTIME/menu.vim
elseif has('xfontset')
  set guifontset=a14,r14,k14
elseif g:is_mac
  set guifont=Osaka-Mono:h14
else
  set guifont=Ricty\ Diminished\ for\ Powerline\ 10
  set guifontwide=Ricty\ Diminished\ for\ Powerline\ 10
endif


" ------------------------------------------------------------
" Setting written in gvimrc of KaoriYa-vim
" ------------------------------------------------------------
set linespace=1
set mousehide nomousefocus




" ------------------------------------------------------------
" END of .gvimrc
" ------------------------------------------------------------
if exists('+transparency')
  gui
  let s:transparency_pair = g:is_windows ? [[240, 210], [255, 255]] : [[15, 30], [0, 0]]
  let s:transparencies = s:transparency_pair[0]
  function! s:toggle_transparency() abort " {{{
    let s:transparencies = s:transparency_pair[s:transparencies is s:transparency_pair[0]]
    doautocmd FocusGained
  endfunction " }}}
  command! -bar ToggleTransparency  call s:toggle_transparency()
  augroup MyAutoCmd " {{{
    autocmd FocusGained,WinEnter * let &transparency = s:transparencies[0]
    autocmd FocusLost * let &transparency = s:transparencies[1]
  augroup END " }}}
endif
if v:version > 704 || v:version == 704 && has('patch793')
  set belloff=all
else
  set t_vb=
endif
