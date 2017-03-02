let s:save_cpo = &cpo
set cpo&vim
scriptencoding utf-8


function! pluginconfig#quickrun() abort
  let g:quickrun_config = {
        \ '_': {
        \   'outputter': 'error',
        \   'outputter/error': 'quickfix',
        \   'outputter/error/success': 'buffer',
        \   'outputter/buffer/split': ':botright',
        \   'runner': 'job',
        \   'outputter/buffer/close_on_empty': 1,
        \   'hook/shebang/enable': !has('win32') && !has('win64')
        \ },
        \ 'c': {
        \   'outputter': 'quickfix',
        \   'command': 'gcc',
        \   'cmdopt': '-Wall -Wextra -fsyntax-only',
        \   'exec': '%C %o %S'
        \ },
        \ 'cpp': {
        \   'outputter': 'quickfix',
        \   'command': 'g++',
        \   'cmdopt': '-Wall -Wextra -fsyntax-only',
        \   'exec': '%C %o %S'
        \ },
        \ 'cs': {
        \   'command': 'csc',
        \   'cmdopt': '/out:quickrunOutput.exe',
        \   'exec': '%C %o %S',
        \ },
        \ 'kuin': {
        \   'command': 'kuincl',
        \   'cmdopt': '-e cui -r',
        \   'exec': ['%C -i %S -o quickrunOutput.exe %o', 'quickrunOutput.exe'],
        \   'hook/output_encode/enable': 1,
        \   'hook/output_encode/encoding': &termencoding,
        \ },
        \
        \ 'lisp': executable('sbcl') ? {
        \   'command': 'sbcl',
        \   'exec': '%C --script %S',
        \ } : {
        \   'command': 'clisp',
        \   'exec': '%C %S',
        \ },
        \ 'html': {
        \   'outputter': 'browser',
        \   'command': 'open',
        \   'exec': '%C %S',
        \ },
        \ 'scheme': {
        \   'command': executable('gosh') ? 'gosh' : 'guile',
        \   'exec': '%C %S',
        \ },
        \ 'python': {
        \   'command': 'python',
        \   'exec': '%C %S',
        \ },
        \ 'ruby': {
        \   'command': 'ruby',
        \   'exec': '%C %S',
        \ },
        \ 'r': {
        \   'command': 'Rscript',
        \   'exec': '%C %S',
        \ },
        \ 'tex': {
        \   'command': 'platex',
        \   'exec': '%C %S',
        \ },
        \ 'make': {
        \   'outputter': 'error:buffer:quickfix',
        \   'command': 'make',
        \   'exec': '%c %o'
        \ }
        \}
  nnoremap <expr><silent><C-c> quickrun#is_running() ? quickrun#sweep_sessions() : "\<C-c>"
  nnoremap <Leader>r  :<C-u>QuickRun -exec '%C %S'<CR>
  " \ }, 'html': {
  " \   'command': 'cat',
  " \   'outputter': 'browser',
endfunction

function! pluginconfig#ref() abort
  " A Setting for the site of webdict.
  let g:ref_source_webdict_sites = {
        \ 'je': {'url': 'http://dictionary.infoseek.ne.jp/jeword/%s'},
        \ 'ej': {'url': 'http://dictionary.infoseek.ne.jp/ejword/%s'},
        \ 'Ej': {'url': 'http://ejje.weblio.jp/content/%s'},
        \ 'dn': {'url': 'http://dic.nicovideo.jp/a/%s'},
        \ 'alc': {'url': 'http://eow.alc.co.jp/search?q=%s'},
        \ 'wiki_en': {'url': 'http://en.wikipedia.org/wiki/%s'},
        \ 'wiki': {'url': 'http://ja.wikipedia.org/wiki/%s'}
        \}
  autocmd MyAutoCmd Filetype ref-webdict setlocal number
  " if g:is_cygwin
  "   autocmd MyAutoCmd Filetype ref-webdict setlocal enc=cp932
  " endif
  let g:ref_open = 'split'

  " If you don't specify a following setting, webdict-results are garbled.
  let pauth = get(g:private, 'pauth', '')
  let lynx = get(g:private, 'lynx', 'lynx')
  if pauth ==# ''
    let g:ref_source_webdict_cmd = lynx . ' -dump -nonumbers %s'
  else
    let g:ref_source_webdict_cmd = lynx . ' -dump -nonumbers -pauth=' . pauth . ' %s'
  endif
  unlet pauth lynx

  " Default webdict site
  let g:ref_source_webdict_sites.default = 'ej'
  " Filters for output. Remove the first few lines.
  function! g:ref_source_webdict_sites.je.filter(output)
    let idx = strridx(a:output, '   (C) SHOGAKUKAN')
    return join(split(a:output[: idx - 1], "\n")[15 :], "\n")
  endfunction
  function! g:ref_source_webdict_sites.ej.filter(output)
    if v:shell_error
      echoerr 'shellerror:' v:shell_error
    endif
    let idx = strridx(a:output, '   (C) SHOGAKUKAN')
    let g:output = a:output
    return join(split(a:output[: idx - 1], "\n")[15 :], "\n")
  endfunction
  function! g:ref_source_webdict_sites.Ej.filter(output)
    let idx = strridx(a:output, '統計情報')
    return join(split(a:output[: idx - 1], "\n")[70 :], "\n")
  endfunction
  function! g:ref_source_webdict_sites.dn.filter(output)
    let idx = strridx(a:output, "\n   [l_box_b]\n")
    return join(split(a:output[: idx], "\n")[16 :], "\n")
  endfunction
  function! g:ref_source_webdict_sites.wiki.filter(output)
    let idx = strridx(a:output, "\n案内メニュー\n")
    return join(split(a:output[: idx], "\n")[17 :], "\n")
  endfunction
  function! g:ref_source_webdict_sites.wiki_en.filter(output)
    let idx = strridx(a:output, "\nNavigation menu\n")
    return join(split(a:output[: idx], "\n")[17 :], "\n")
  endfunction
  function! g:ref_source_webdict_sites.alc.filter(output)
    let list = split(a:output, "\n")
    let list = list[match(list, '   英辞郎データ提供元 EDP のサイトへ') + 3 :]
    let list = list[: match(list, '   ＊ データの転載は禁じられています。') - 3]
    return join(filter(list, 'v:val !=# "       単語帳"'), "\n")
  endfunction
endfunction


function! pluginconfig#switch() abort
  let g:switch_custom_definitions = [
        \ ['yes', 'no'],
        \ ['left', 'right'],
        \ ['true', 'false'],
        \ ['if', 'unless'],
        \ ['while', 'until'],
        \ ['signed', 'unsigned'],
        \ [100, ':continue', ':information'],
        \ [101, ':switching_protocols'],
        \ [102, ':processing'],
        \ [200, ':ok', ':success'],
        \ [201, ':created'],
        \ [202, ':accepted'],
        \ [203, ':non_authoritative_information'],
        \ [204, ':no_content'],
        \ [205, ':reset_content'],
        \ [206, ':partial_content'],
        \ [207, ':multi_status'],
        \ [208, ':already_reported'],
        \ [226, ':im_used'],
        \ [300, ':multiple_choices'],
        \ [301, ':moved_permanently'],
        \ [302, ':found'],
        \ [303, ':see_other'],
        \ [304, ':not_modified'],
        \ [305, ':use_proxy'],
        \ [306, ':reserved'],
        \ [307, ':temporary_redirect'],
        \ [308, ':permanent_redirect'],
        \ [400, ':bad_request'],
        \ [401, ':unauthorized'],
        \ [402, ':payment_required'],
        \ [403, ':forbidden'],
        \ [404, ':not_found'],
        \ [405, ':method_not_allowed'],
        \ [406, ':not_acceptable'],
        \ [407, ':proxy_authentication_required'],
        \ [408, ':request_timeout'],
        \ [409, ':conflict'],
        \ [410, ':gone'],
        \ [411, ':length_required'],
        \ [412, ':precondition_failed'],
        \ [413, ':request_entity_too_large'],
        \ [414, ':request_uri_too_long'],
        \ [415, ':unsupported_media_type'],
        \ [416, ':requested_range_not_satisfiable'],
        \ [417, ':expectation_failed'],
        \ [422, ':unprocessable_entity'],
        \ [423, ':precondition_required'],
        \ [424, ':too_many_requests'],
        \ [426, ':request_header_fields_too_large'],
        \ [500, ':internal_server_error'],
        \ [501, ':not_implemented'],
        \ [502, ':bad_gateway'],
        \ [503, ':service_unavailable'],
        \ [504, ':gateway_timeout'],
        \ [505, ':http_version_not_supported'],
        \ [506, ':variant_also_negotiates'],
        \ [507, ':insufficient_storage'],
        \ [508, ':loop_detected'],
        \ [510, ':not_extended'],
        \ [511, ':network_authentication_required'],
        \]
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
