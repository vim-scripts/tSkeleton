" tSkeleton.vim
" @Author:      Thomas Link (samul AT web.de)
" @Website:     http://members.a1.net/t.link/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     21-Sep-2004.
" @Last Change: 20-Jän-2005.
" @Revision:    1.1.208

if &cp || exists("loaded_tskeleton")
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

let g:tskelBitsDir = g:tskelDir ."bits/"

if !exists("g:tskelLicense")
    let g:tskelLicense = "GPL (see http://www.gnu.org/licenses/gpl.txt)"
endif

if !exists("g:tskelPatternLeft")   | let g:tskelPatternLeft   = "<+"         | endif
if !exists("g:tskelPatternRight")  | let g:tskelPatternRight  = "+>"         | endif
if !exists("g:tskelPatternCursor") | let g:tskelPatternCursor = "<+CURSOR+>" | endif
if !exists("g:tskelDateFormat")    | let g:tskelDateFormat = "%d-%b-%Y"      | endif
if !exists("g:tskelUserName")      | let g:tskelUserName   = "<+NAME+>"      | endif
if !exists("g:tskelUserAddr")      | let g:tskelUserAddr   = "<+ADDRESS+>"   | endif
if !exists("g:tskelUserEmail")     | let g:tskelUserEmail  = "<+EMAIL+>"     | endif
if !exists("g:tskelUserWWW")       | let g:tskelUserWWW    = "<+WWW+>"       | endif

if !exists("g:tskelRevisionMarkerRx")  | let g:tskelRevisionMarkerRx = '@Revision:\s\+' | endif
if !exists("g:tskelRevisionVerRx")     | let g:tskelRevisionVerRx = '\(pre\d*\|p\d\+\|-\?\d\+\)\.' | endif
if !exists("g:tskelRevisionGrpIdx")    | let g:tskelRevisionGrpIdx = 3 | endif

if !exists("g:tskelDontSetup")
    autocmd BufNewFile *.bat     TSkeletonSetup batch.bat
    autocmd BufNewFile *.tex     TSkeletonSetup latex.tex
    autocmd BufNewFile *.rb      TSkeletonSetup ruby.rb
    autocmd BufNewFile *.rbx     TSkeletonSetup ruby.rb
    autocmd BufNewFile *.sh      TSkeletonSetup shell.sh
    autocmd BufNewFile *.txt     TSkeletonSetup text.txt
    autocmd BufNewFile *.vim     TSkeletonSetup plugin.vim
    autocmd BufNewFile *.inc.php TSkeletonSetup php.inc.php
    autocmd BufNewFile *.php     TSkeletonSetup php.php
endif

fun! TSkeletonFillIn(bit)
    " try
        silent norm! gg
        call <SID>GetBitProcess("before", "b:tskelBitProcess_")
        call <SID>GetBitProcess("after", "b:tskelBitProcess_")
        if exists("b:tskelBitProcess_before")
            exec b:tskelBitProcess_before
            unlet b:tskelBitProcess_before
        endif
        silent exec '%s/'. g:tskelPatternLeft .'&\(.\{-}\)'. g:tskelPatternRight 
                    \ .'/\=<SID>Modify(<SID>Exec("&".submatch(1)), submatch(2))/ge'
        silent exec '%s/'. g:tskelPatternLeft .'g:\(.\{-}\)'. g:tskelPatternRight 
                    \ .'/\=<SID>Modify(<SID>Exec("g:".submatch(1)), submatch(2))/ge'
        silent exec '%s/'. g:tskelPatternLeft .'b:\(.\{-}\)'. g:tskelPatternRight 
                    \ .'/\=<SID>Modify(<SID>Exec("b:".submatch(1)), submatch(2))/ge'
        exec '%s/'. g:tskelPatternLeft .'\([A-Z ]\+\)\(: *.\{-} *\)\?'. g:tskelPatternRight 
                    \ .'/\=<SID>Modify(<SID>Dispatch(submatch(1)), submatch(2))/ge'
        exec '%s/'. g:tskelPatternLeft .'?\(.\{-}\)'. g:tskelPatternRight 
                    \ .'/\=<SID>Modify(<SID>Query(submatch(1)), submatch(2))/ge'
        if !a:bit
            call <SID>SetCursor("%")
        endif
        if exists("b:tskelBitProcess_after")
            exec b:tskelBitProcess_after
            unlet b:tskelBitProcess_after
        endif
    " catch
    "     echom "An error occurred in TSkeletonFillIn() ... ignored"
    " endtry
endf

fun! <SID>SetCursor(range, ...)
    let findOnly = a:0 >= 1 ? a:0 : 0
    let l = search(g:tskelPatternCursor)
    if l > 0
        if !findOnly
            let c = col(".")
            silent exec a:range .'s/'. g:tskelPatternCursor .'//e'
            silent exec "norm! ". c ."|"
        endif
    endif
    return l
endf

fun! <SID>Exec(arg)
    exec "return ". a:arg
endf

fun! TSkelIncreaseIndex(var)
    exec "let ". a:var ."=". a:var ."+1"
    return a:var
endf

fun! <SID>Query(arg)
    let sepx = match(a:arg, "|")
    let var  = strpart(a:arg, 0, sepx)
    let text = strpart(a:arg, sepx + 1)
    if var != "" && exists("b:tskelChoices_". var)
        echo b:tskelChoices_{var}
    endif
    return input(text. " ")
endf

fun! <SID>SaveBitProcess(name, var, match)
    exec 'let '. a:var.a:name .' = "'. escape(a:match, '"') .'"'
    return ""
endf

fun! <SID>GetBitProcess(name, var)
    exec 's/^\s*<tskel:'. a:name .'>\s*\n\(\_.\{-}\)\n\s*<\/tskel:'. a:name .'>\s*\n/\=<SID>SaveBitProcess("'. a:name .'", "'. a:var .'", submatch(1))/e'
endf

fun! <SID>Modify(text, modifier)
    let rv = escape(a:text, '\&~')
    let premod = '^[:ulcs]\{-}'
    if a:modifier =~? premod.'u'
        let rv = toupper(rv)
    endif
    if a:modifier =~? premod.'l'
        let rv = tolower(rv)
    endif
    if a:modifier =~? premod.'c'
        let rv = toupper(rv[0]) . tolower(strpart(rv, 1))
    endif
    if a:modifier =~? premod.'s'
        let mod  = substitute(a:modifier, '^[^s]*s\(.*\)$', '\1', '')
        let sep  = mod[0]
        let esep = escape(sep, '\')
        let pat  = '\(\[^'. sep .']\*\)'
        let rx   = '\V\^'. esep . pat . esep . pat . esep .'\$'
        let from = substitute(mod, rx, '\1', '')
        let to   = substitute(mod, rx, '\2', '')
        let rv   = substitute(rv, '\V'. from, to, 'g')
    endif
    return rv
endf

fun! <SID>Dispatch(name)
    let name = substitute(a:name, '^ *\(.\{-}\) *$', '\1', '')
    let name = substitute(name, " ", "_", "g")
    if exists("*TSkeleton_". name)
        return TSkeleton_{name}()
    else
        " echom "Unknown template tag: ". a:name
        return g:tskelPatternLeft . a:name . g:tskelPatternRight
    endif
endf

fun! TSkeletonGetVar(name, ...)
    if exists("b:". a:name)
        exec "return b:". a:name
    elseif a:0 >= 1
        exec "return ". a:1
    else
        exec "return g:". a:name
    endif
endf

fun! TSkeleton_FILE_NAME_ROOT()
    return expand("%:t:r")
endf

fun! TSkeleton_FILE_NAME()
    return expand("%:t")
endf

fun! TSkeleton_NOTE()
    " let title = exists("b:tskelTitle") ? b:tskelTitle : input("Please describe the project: ")
    let title = TSkeletonGetVar("tskelTitle", 'input("Please describe the project: ")')
    let note  = title != "" ? " -- ".title : ""
    return note
endf

fun! TSkeleton_DATE()
    return strftime(TSkeletonGetVar("tskelDateFormat"))
endf

fun! TSkeleton_AUTHOR()
    return TSkeletonGetVar("tskelUserName")
endf

fun! TSkeleton_EMAIL()
    " let email = TSkeletonGetVar("tskelUserEmail")
    " return substitute(email, "@"," AT ", "g")
    return TSkeletonGetVar("tskelUserEmail")
endf

fun! TSkeleton_WEBSITE()
    return TSkeletonGetVar("tskelUserWWW")
endf

fun! TSkeleton_LICENSE()
    return TSkeletonGetVar("tskelLicense")
endf

fun! TSkeletonSetup(template, ...)
    let anyway = a:0 >= 1 ? a:1 : 0
    if anyway || !exists("b:tskelDidFillIn") || !b:tskelDidFillIn
        let cpoptions = &cpoptions
        set cpoptions-=a
        if filereadable(g:tskelDir . a:template)
            let tf = g:tskelDir . a:template
        elseif filereadable(g:tskelDir ."prefab/". a:template)
            let tf = g:tskelDir ."prefab/". a:template
        else
            echoerr "Unknown skeleton: ". a:template
        endif
        exe "0read ". tf
        let &cpoptions = cpoptions
        call TSkeletonFillIn(0)
        let b:tskelDidFillIn = 1
    endif
endf

fun! TSkeletonSelectTemplate(ArgLead, CmdLine, CursorPos)
    if a:CmdLine =~ '^.\{-}\s\+.\{-}\s'
        return ""
    else
        return <SID>GlobBits(g:tskelDir ."/,". g:tskelDir ."prefab/")
    endif
endf

command! -nargs=* -complete=custom,TSkeletonSelectTemplate TSkeletonSetup 
            \ call TSkeletonSetup(<f-args>)

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
command! -nargs=* -complete=custom,TSkeletonSelectTemplate TSkeletonEdit 
            \ call TSkeletonEdit(<f-args>)

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
        call TSkeletonFillIn(0)
        exe "bdelete ". tpl
    endif
endf
command! -nargs=* -complete=custom,TSkeletonSelectTemplate TSkeletonNewFile 
            \ call TSkeletonNewFile(<f-args>)



" this is inspired by templates.vim (vimscript #982)
fun! <SID>GlobBits(path, ...)
    let pt = a:0 >= 1 ? a:1 : "*"
    let rv = globpath(a:path, pt)
    let rv = "\n". substitute(rv, '\\', '/', 'g') ."\n"
    let rv = substitute(rv, '\n\zs.\{-}/\([^/]\+\)\ze\n', '\1', 'g')
    return strpart(rv, 1)
endf

fun! <SID>PrepareBits()
    if !exists("b:tskelBits")
        let b:tskelBits = <SID>GlobBits(g:tskelBitsDir . &filetype ."/,". g:tskelBitsDir ."general/")
    endif
endf

fun! TSkeletonSelectBit(ArgLead, CmdLine, CursorPos)
    call <SID>PrepareBits()
    return b:tskelBits
endf

if exists("g:tskelSimpleBits") && g:tskelSimpleBits
    fun! <SID>InsertBit(bit)
        let cpoptions = &cpoptions
        set cpoptions-=a
        exe "read ". a:bit
        let &cpoptions = cpoptions
    endf
else
    let s:tskelScratchNr = -1
    fun! <SID>InsertBit(bit)
        let cpoptions = &cpoptions
        set cpoptions-=a
        let t = @t
        try
            let cb=bufnr("%")
            let tsbnr = bufnr(s:tskelScratchNr)
            if tsbnr >= 0
                exec "buffer ". tsbnr
            else
                edit [TSkeletonScratch]
                setlocal buftype=nofile
                setlocal bufhidden=hide
                setlocal noswapfile
                setlocal nobuflisted
                let s:tskelScratchNr = bufnr("%")
            endif
            silent norm! ggdG
            silent exe "0read ". a:bit
            call TSkeletonFillIn(1)
            let setCursor = <SID>SetCursor(".,$", 1)
            silent norm! ggvG$"ty
            " trick |alternate-file|
            try
                silent edit #2
            catch
                throw "This is the first anonymous buffer ... aborting"
            endtry
            silent exec "buffer ". cb
            let l = line(".")
            silent norm! "tgp
            " exec 'norm! v'.l.'G=`>'
            silent exec 'norm! ='.l.'G'
            if setCursor
                call <SID>SetCursor(".,$")
            endif
        finally
            let @t = t
            let &cpoptions = cpoptions
        endtry
    endf
endif

fun! <SID>SelectBit(subdir, bit)
    let ffbits = "\n". <SID>GlobBits(g:tskelBitsDir . a:subdir ."/") ."\n"
    if ffbits =~ "\\V\n". a:bit ."\n"
        call <SID>InsertBit(g:tskelBitsDir . a:subdir ."/". a:bit)
        return 1
    else
        return 0
    endif
endf

fun! TSkeletonBit(bit)
    " try
        if <SID>SelectBit(&filetype, a:bit) || <SID>SelectBit("general", a:bit)
            return 1
        else
            echom "TSkeletonBit: Unknown bit '". a:bit ."'"
            return 0
        endif
    " catch
    "     echom "An error occurred in TSkeletonBit() ... ignored"
    " endtry
endf

command! -nargs=1 -complete=custom,TSkeletonSelectBit TSkeletonBit
            \ call TSkeletonBit(<q-args>)

fun! TSkeletonExpandBitUnderCursor()
    call <SID>PrepareBits()
    let t = @t
    silent norm! "tdiw
    if !TSkeletonBit(@t)
        silent norm! "tP
    endif
    let @t = t
endf

if !hasmapto("TSkeletonExpandBitUnderCursor")
    nnoremap <unique> <Leader># :call TSkeletonExpandBitUnderCursor()<cr>
endif


" misc utilities
fun! TSkeletonIncreaseRevisionNumber()
    let rev = exists("b:revisionRx") ? b:revisionRx : g:tskelRevisionMarkerRx
    let ver = exists("b:versionRx")  ? b:versionRx  : g:tskelRevisionVerRx
    normal m`
    exe '%s/'.rev.'\('.ver.'\)*\zs\(-\?\d\+\)/\=(submatch(g:tskelRevisionGrpIdx) + 1)/e'
    normal ``
endfun

" autocmd BufWritePre * call TSkeletonIncreaseRevisionNumber()


finish
1.0
- Initial release

1.1
- User-defined tags
- Modifiers <+NAME:MODIFIERS+> (c=capitalize, u=toupper, l=tolower, s//=substitute)
- Skeleton bits
- the default markup for tags has changed to <+TAG+> (for "compatibility" with 
imaps.vim), the cursor position is marked as <+CURSOR+> (but this can be 
changed by setting g:tskelPatternLeft, g:tskelPatternRight, and 
g:tskelPatternCursor)
- in the not so simple mode, skeleton bits can contain vim code that is 
evaluated after expanding the template tags (see .../skeletons/bits/vim/if for 
an example)
- function TSkeletonExpandBitUnderCursor(), which is mapped to <Leader>#
- utility function: TSkeletonIncreaseRevisionNumber()

