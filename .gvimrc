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
let g:did_install_default_menus = 1
if has('kaoriya')
  set guioptions=
else
  set guioptions=
endif
set winaltkeys=no
set guicursor+=a:blinkon0

" function! s:get_sid_prefix() abort
"   return matchstr(expand('<sfile>'), '^function \zs<SNR>\d\+_\zeget_sid_prefix$')
" endfun
" let s:sid_prefix = s:get_sid_prefix()
" delfunction s:get_sid_prefix

" function! s:balloon_expr() abort
"   let lnum = foldclosed(v:beval_lnum)
"   if lnum == -1
"     return ''
"   endif
"   let lines = getline(lnum, foldclosedend(lnum))
"   return iconv(join(len(lines) > &lines ? lines[: &lines] : lines, "\n"), &enc, &tenc)
" endfunction
" let &balloonexpr = s:sid_prefix . 'balloon_expr()'
" set ballooneval

if has('multi_byte_ime') || has('xim')
  autocmd MyAutoCmd Colorscheme * hi CursorIM guifg=NONE guibg=Orange
  set iminsert=0 imsearch=0
endif

if exists('+antialias')
  set antialias
endif

if g:is_windows
  set guifont=Ricty_Diminished_Discord:h10,Consolas:h10
  set guifontwide=Ricty_Diminished_Discord:h10,MS_Gothic:h9
  set renderoptions=type:directx,renmode:5
  " set langmenu=ja_jp.utf-8
  " source $VIMRUNTIME/delmenu.vim
  " source $VIMRUNTIME/menu.vim
elseif has('xfontset')
  set guifontset=a14,r14,k14
elseif g:is_mac
  set guifont=Osaka-Mono:h14
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
  function! s:toggle_transparency() abort
    let s:transparencies = s:transparency_pair[s:transparencies is s:transparency_pair[0]]
    doautocmd FocusGained
  endfunction
  command! -bar ToggleTransparency  call s:toggle_transparency()
  augroup MyAutoCmd
    autocmd FocusGained,WinEnter * let &transparency = s:transparencies[0]
    autocmd FocusLost * let &transparency = s:transparencies[1]
  augroup END
endif
set t_vb=
