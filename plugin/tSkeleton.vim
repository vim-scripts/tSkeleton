" tSkeleton.vim
" @Author:      Thomas Link (samul AT web.de)
" @Website:     http://members.a1.net/t.link/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     21-Sep-2004.
" @Last Change: 19-Dez-2004.
" @Revision:    1.0.1

if &cp || exists("loaded_tskeleton") "{{{2
    finish
endif
let loaded_tskeleton = 100

if !exists("g:tskelDir")
    if has("win16") || has("win32") || has("win64")
        let g:tskelDir = $VIM ."/vimfiles/skeletons/"
    else
        let g:tskelDir = $HOME ."/.vim/skeletons/"
    endif
endif

if !exists("g:tskelLicense")
    let g:tskelLicense = "GPL (see http://www.gnu.org/licenses/gpl.txt)"
endif

if !exists("g:tskelDateFormat") | let g:tskelDateFormat = "%d-%b-%Y"    | endif
if !exists("g:tskelUserName")   | let g:tskelUserName   = "<+NAME+>"    | endif
if !exists("g:tskelUserAddr")   | let g:tskelUserAddr   = "<+ADDRESS+>" | endif
if !exists("g:tskelUserEmail")  | let g:tskelUserEmail  = "<+EMAIL+>"   | endif
if !exists("g:tskelUserWWW")    | let g:tskelUserWWW    = "<+WWW+>"     | endif

if !exists("g:tskelDontSetup")
    autocmd BufNewFile *.bat     call TSkeletonSetup("batch.bat", 0)
    autocmd BufNewFile *.tex     call TSkeletonSetup("latex.tex", 0)
    autocmd BufNewFile *.rb      call TSkeletonSetup("ruby.rb", 0)
    autocmd BufNewFile *.rbx     call TSkeletonSetup("ruby.rb", 0)
    autocmd BufNewFile *.sh      call TSkeletonSetup("shell.sh", 0)
    autocmd BufNewFile *.txt     call TSkeletonSetup("text.txt", 0)
    autocmd BufNewFile *.vim     call TSkeletonSetup("plugin.vim", 0)
    autocmd BufNewFile *.inc.php call TSkeletonSetup("php.inc.php", 0)
    autocmd BufNewFile *.php     call TSkeletonSetup("php.php", 0)
endif

fun! <SID>TSkeletonExec(arg)
    exec "return ". a:arg
endf

fun! TSkeletonFillIn()
    let title = input("Please describe the project: ")
    let note  = title != "" ? " -- ".title : ""
    %s*@{FILE NAME ROOT}*\=expand("%:t:r")*ge
    %s*@{FILE NAME}*\=expand("%:t")*ge
    %s*@{NOTE}*\=note*ge
    %s*@{DATE}*\=strftime(g:tskelDateFormat)*ge
    %s*@{AUTHOR}*\=g:tskelUserName*ge
    %s*@{EMAIL}*\=substitute(g:tskelUserEmail, "@"," AT ", "g")*ge
    %s*@{WEBSITE}*\=g:tskelUserWWW*ge
    %s*@{LICENSE}*\=g:tskelLicense*ge
    %s*@{&\(.\{-}\)}*\=<SID>TSkeletonExec("&".submatch(1))*ge
    %s*@{g:\(.\{-}\)}*\=<SID>TSkeletonExec("g:".submatch(1))*ge
    %s*@{b:\(.\{-}\)}*\=<SID>TSkeletonExec("b:".submatch(1))*ge
    %s*@@**e
endf

fun! TSkeletonSetup(template, anyway)
    if a:anyway || !exists("b:tskelDidFillIn") || !b:tskelDidFillIn
        let cpoptions = &cpoptions
        set cpoptions-=a
        exe "0read ". g:tskelDir . a:template
        let &cpoptions = cpoptions
        call TSkeletonFillIn()
        let b:tskelDidFillIn = 1
    endif
endf

if exists("*browse")
    fun! <SID>TSkeletonBrowse(save, title, initdir, default)
        return browse(a:save, a:title, a:initdir, a:default)
    endf
else
    fun! <SID>TSkeletonBrowse(save, title, initdir, default)
        let dir = substitute(a:initdir, '\\', '/', "g")
        let files = substitute(glob(dir. "*"), '\V\(\_^\|\n\)\zs'. dir, '', 'g')
        let files = substitute(files, "\n", ", ", "g")
        echo files
        let tpl = input(a:title ." -- choose file: ")
        return a:initdir. tpl
    endf
endif

" TSkeletonEdit(?dir)
fun! TSkeletonEdit(...)
    let tpl  = <SID>TSkeletonBrowse(0, "Template", g:tskelDir, "")
    if tpl != ""
        let tpl = a:0 >= 1 && a:1 ? g:tskelDir.a:1 : fnamemodify(tpl, ":p")
        exe "edit ". tpl
    end
endf
command! -nargs=* TSkeletonEdit call TSkeletonEdit(<f-args>)

" TSkeletonNewFile(?template, ?dir, ?fileName)
fun! TSkeletonNewFile(...)
    if a:0 >= 1 && a:1 != ""
        let tpl = g:tskelDir. a:1
        echom "Template: ". tpl
    else
        let tpl = <SID>TSkeletonBrowse(0, "Template", g:tskelDir, "")
        if tpl == ""
            return
        else
            let tpl = fnamemodify(tpl, ":p")
        endif
    endif
    if a:0 >= 2 && a:2 != ""
        let dir = a:2
        echom "Template: ". dir
    else
        let dir = getcwd()
    endif
    if a:0 >= 3
        let fn = a:3
    else
        let fn = <SID>TSkeletonBrowse(1, "New File", dir, "new.".fnamemodify(tpl, ":e"))
        if fn == ""
            return
        else
            let fn = fnamemodify(fn, ":p")
        endif
    endif
    if fn != "" && tpl != ""
        exe 'edit '. tpl
        exe 'saveas '. fn
        call TSkeletonFillIn()
        exe "bdelete ". tpl
    endif
endf
command! -nargs=* TSkeletonNewFile call TSkeletonNewFile(<f-args>)

