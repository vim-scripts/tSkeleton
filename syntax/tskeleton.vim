" tskeleton.vim
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     30-Dez-2003.
" @Last Change: 07-Mär-2005.
" @Revision: 0.481

if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

try
    exec "runtime! syntax/". expand("%:p:h:t") .".vim"
    unlet b:current_syntax
catch
endtry

syntax include @Vim syntax/vim.vim
syn region tskeletonProcess matchgroup=tskeletonProcessMarker
            \ start='^\s*<\z(tskel:[a-z_:]\+\)>\s*$' end='^\s*</\z1>\s*$'
            \ contains=@Vim

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_tskeleton_syntax_inits")
    if version < 508
        let did_tskeleton_syntax_inits = 1
        command! -nargs=+ HiLink hi link <args>
    else
        command! -nargs=+ HiLink hi def link <args>
    endif
    
    HiLink tskeletonProcessMarker Statement
    
    delcommand HiLink
endif

