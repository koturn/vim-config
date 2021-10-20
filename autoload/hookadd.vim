let s:save_cpo = &cpo
set cpo&vim


function! s:get_sid_prefix() abort " {{{
  return matchstr(expand('<sfile>'), '\zs<SNR>\d\+_\zeget_sid_prefix$')
endfunction " }}}
let s:sid_prefix = s:get_sid_prefix()
delfunction s:get_sid_prefix

function! hookadd#lightline() abort " {{{
  set laststatus=2
  let g:lightline = {
        \ 'colorscheme': 'iceberg',
        \ 'separator': { 'left': "\u2b80", 'right': "\u2b82" },
        \ 'subseparator': {  'left': "\u2b81", 'right': "\u2b83" },
        \ 'mode_map': {'c': 'NORMAL'},
        \ 'active': {
        \   'left': [['mode', 'eskk_status', 'paste'], ['fugitive', 'filename']],
        \   'right': [['lineinfo'], ['percent'], ['fileformat', 'fileencoding', 'filetype'], ['time']]
        \ },
        \ 'component_function': {
        \   'modified': s:sid_prefix . 'll_modified',
        \   'eskk_status': s:sid_prefix . 'll_eskk_status',
        \   'readonly': s:sid_prefix . 'll_readonly',
        \   'fugitive': s:sid_prefix . 'll_fugitive',
        \   'filename': s:sid_prefix . 'll_filename',
        \   'fileformat': s:sid_prefix . 'll_fileformat',
        \   'filetype': s:sid_prefix . 'll_filetype',
        \   'fileencoding': s:sid_prefix . 'll_fileencoding',
        \   'mode': s:sid_prefix . 'll_mode',
        \   'time': s:sid_prefix . 'll_time'
        \ }
        \}
  function! s:ll_modified() abort " {{{
    return &ft =~ 'help\|vimfiler\|gundo' ? '' : &modified ? '+' : &modifiable ? '' : '-'
  endfunction " }}}
  function! s:ll_readonly() abort " {{{
    return &ft !~? 'help\|vimfiler\|gundo' && &readonly ? 'x' : ''
  endfunction " }}}
  function! s:ll_filename() abort " {{{
    return ('' !=# s:ll_readonly() ? s:ll_readonly() . ' ' : '') .
          \ (&ft ==# 'vimfiler' ? vimfiler#get_status_string() :
          \  &ft ==# 'unite' ? unite#get_status_string() :
          \  &ft ==# 'vimshell' ? vimshell#get_status_string() :
          \ '' !=# expand('%:t') ? expand('%:t') : '[No Name]') .
          \ ('' !=# s:ll_modified() ? ' ' . s:ll_modified() : '')
  endfunction " }}}
  function! s:ll_fugitive() abort " {{{
    try
      if &ft !~? 'vimfiler\|gundo' && exists('*fugitive#head')
        return fugitive#head()
      endif
    catch
    endtry
    return ''
  endfunction " }}}
  function! s:ll_fileformat() abort " {{{
    return winwidth(0) > 70 ? &fileformat : ''
  endfunction " }}}
  function! s:ll_filetype() abort " {{{
    return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype : 'no ft') : ''
  endfunction " }}}
  function! s:ll_fileencoding() abort " {{{
    return winwidth(0) > 70 ? ((strlen(&fenc) ? &fenc : &enc) . (&bomb ? ' (BOM)' : '')) : ''
  endfunction " }}}
  function! s:ll_mode() abort " {{{
    return winwidth(0) > 60 ? lightline#mode() : ''
  endfunction " }}}
  function! s:ll_time() abort " {{{
    return winwidth(0) > 80 ? strftime('%Y/%m/%d(%a) %H:%M:%S') : ''
  endfunction " }}}
  function! s:ll_eskk_status() abort " {{{
    return winwidth(0) > 60 && lightline#mode() ==# 'INSERT' && exists('*eskk#statusline') ? eskk#statusline() ==# '[eskk:あ]' ? '[あ]' : '[--]' : '[--]'
  endfunction " }}}
endfunction " }}}

function! hookadd#eskk() abort " {{{
  function! s:toggle_ime() abort " {{{
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
  endfunction " }}}
  let s:is_ime = 0
  call s:toggle_ime()
  command! -bar ToggleIME  call s:toggle_ime()

  function! s:update_skk_dict() abort " {{{
    call eskk#is_initialized()
    let dict_url = 'http://openlab.jp/skk/dic/SKK-JISYO.L.gz'
    let dl_client = executable('wget') ? 'wget'
          \ : executable('curl') ? 'curl'
          \ : ''
    if dl_client ==# ''
      echoerr 'Download client, wget or curl is not available'
      return
    endif
    let dstpath = fnamemodify(expand(g:eskk#large_dictionary.path), ':h') . '/SKK-JISYO.L.gz'
    if dl_client ==# 'wget'
      echo vimrc#system(printf('wget %s -O "%s"', dict_url, dstpath))
    else
      echo vimrc#system(printf('curl -O %s -o "%s"', dict_url, dstpath))
    endif
    echomsg 'Downloaded SKK-JISYO.L.gz: ' . dstpath
    if !executable('gzip')
      echoerr 'command: gzip is not available'
      return
    endif
    echo vimrc#system('gzip -df ' . dstpath)
    echomsg 'Decompressed SKK-JISYO.L.gz'
    if tolower(g:eskk#large_dictionary.encoding) !=# 'euc-jp'
      let fname = fnamemodify(dstpath, ':r')
      call writefile(map(readfile(fname), 'iconv(v:val, "euc-jp", g:eskk#large_dictionary.encoding)'), fname)
      echomsg 'Convert character code: euc-jp -> ' . g:eskk#large_dictionary.encoding
    endif
  endfunction " }}}
  command! -bar UpdateSkkDict call s:update_skk_dict()
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo
