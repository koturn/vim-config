" ============================================================================
" FILE: vimrc.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" Last Modified: 2019 04/19
" DESCRIPTION: {{{
" descriptions.
" }}}
" ============================================================================
if exists('g:loaded_vimrc')
  finish
endif
let g:loaded_vimrc = 1
let s:save_cpo = &cpo
set cpo&vim


command! -bar -bang -range=% -nargs=?  RetabHead  call vimrc#retab_head(<bang>0, add([<f-args>], &l:tabstop)[0], <line1>, <line2>)
command! -bar -bang -range=% ToggleTabSpace  call vimrc#toggle_tab_space(<bang>0, &l:tabstop, <line1>, <line2>)
command! -bang -bar -nargs=1 Indent  call vimrc#change_indent(<bang>0, <q-args>)
command! -bar -nargs=? -complete=command SmartSplit  call vimrc#smart_split(<q-args>)
if v:version > 704 || (v:version == 704 && has('patch1738'))
  command! -bar Clear  messages clear
else
  command! -bar Clear  call vimrc#clear_message()
endif
command! -bar -bang -nargs=? MessagesHead  call vimrc#messages_head(<bang>0, <f-args>)
command! -bar -bang -nargs=? MessagesTail  call vimrc#messages_tail(<bang>0, <f-args>)
command! -bar -nargs=1 Which  call vimrc#cmd_which(<q-args>)
command! -bar -nargs=0 -count=0 Lcd  call vimrc#cmd_lcd(<count>)
command! -bar Ebd  call vimrc#buf_delete()
command! -bar -bang -nargs=* -complete=buffer BwipeoutAll  call vimrc#bwipeout_all('<bang>', <f-args>)
command! -bar -bang BwipeoutAllNoname  call vimrc#bwipeout_all('<bang>', '')
command! -bar DiffOrig  call vimrc#difforig()
command! -bar -nargs=+ -complete=file Diff  call vimrc#vimdiff_in_newtab(<f-args>)
command! -bar -nargs=+ -complete=file Compare  call vimrc#compare(<f-args>)
command! -bang -bar SpeedUp  call vimrc#speed_up(<bang>0)
command! -bar -range=% CommaPeriod  call vimrc#comma_period(<line1>, <line2>)
command! -bar -range=% Kutouten  call vimrc#kutouten(<line1>, <line2>)
command! -bar -range=% DevideSentence  call vimrc#devide_sentence(<line1>, <line2>)
command! -bang -bar JunkBuffer  call vimrc#make_junk_buffer(<bang>0)
command! -bar -range=% DeleteTrailingWhitespace  call vimrc#delete_match_pattern('\s\+$', <line1>, <line2>)
command! -bar -range=% DeleteTrailingCR  call vimrc#delete_match_pattern('\r$', <line1>, <line2>)
command! -bar -range=% DeleteBlankLines  call vimrc#delete_blank_lines(<line1>, <line2>)
command! -bar ClearUndo  call vimrc#clear_undo()
command! -bar -range=% MakeVimLFoldings  call vimrc#make_viml_foldings(<line1>, <line2>)
command! -bar TabInfo call vimrc#show_tab_info()
command! -bar CheckInterpVersion  call vimrc#show_interp_version()
" command! -bar -nargs=+ -complete=customlist,vimrc#dein_name_complete DeinUpdate  call dein#update([<f-args>])
command! -bar -nargs=* -complete=customlist,vimrc#git_gc_option_complete DeinGitGc  call vimrc#dein_git_gc(<f-args>)
if exists('*win_gotoid')
  command! -bar -nargs=1 -complete=buffer Buffer  call vimrc#buf_open_existing(<f-args>, <q-mods>)
else
  command! -bar -nargs=1 -complete=buffer Buffer  call vimrc#buf_open_existing(<f-args>)
endif
command! -bar -nargs=? -complete=customlist,vimrc#complete_term_bufname Terminal  call vimrc#term_open_existing(<q-mods>, <f-args>)
command! -bar -count -nargs=1 KeywordprgMan  call vimrc#open_man(expand(<q-args>))
command! -bar ShowHlGroup  call vimrc#show_highlight_info(line('.'), col('.'))
command! -bar ShowFileSize  call vimrc#show_file_size()
command! -bar -bang -nargs=* PluginTest  call vimrc#plugin_test(<bang>0, <q-args>, 0)
command! -bar -bang -nargs=* PluginTestCUI  call vimrc#plugin_test(0, <q-args>, 0)
command! -bar -bang -nargs=* PluginTestGUI  call vimrc#plugin_test(1, <q-args>, 0)
if !has('gui_running') && has('win32')
  command! -bar -bang -nargs=* PluginTestCUISameWindow  call vimrc#plugin_test(0, <q-args>, 1)
endif

command! -bar -bang ShowMemoryUsage  call vimrc#show_memory_usage()
command! -bar -bang -nargs=? -complete=file Write  call vimrc#save_as_root('<bang>', <q-args>)
command! -bar -bang -range=% -nargs=? Jq  <line1>,<line2>call vimrc#jq(<bang>0, <f-args>)
command! -bar -complete=file -nargs=1 Pdf  call vimrc#pdftotext(<q-args>)
command! -bar BinaryRead  call vimrc#read_binary()
command! -bar BinaryWrite  call vimrc#write_binary()
command! -bar BinaryDecode  call vimrc#decode_binary()
command! -bar -nargs=1 GitGrep  call vimrc#gitgrep(<f-args>)
command! -bar FindConflict  /^[<>=]\{7\}


let &cpo = s:save_cpo
unlet s:save_cpo
