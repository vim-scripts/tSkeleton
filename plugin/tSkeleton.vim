" tSkeleton.vim
" @Author:      Thomas Link (samul AT web.de)
" @Website:     http://members.a1.net/t.link/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     21-Sep-2004.
" @Last Change: 02-Mär-2005.
" @Revision:    1.2.259
"
" vimscript #1160
"
" TODO:

if &cp || exists("loaded_tskeleton")
    finish
endif
let loaded_tskeleton = 102

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

if !exists("g:tskelPatternLeft")   | let g:tskelPatternLeft   = "<+"          | endif
if !exists("g:tskelPatternRight")  | let g:tskelPatternRight  = "+>"          | endif
if !exists("g:tskelPatternCursor") | let g:tskelPatternCursor = "<+CURSOR+>"  | endif
if !exists("g:tskelDateFormat")    | let g:tskelDateFormat    = "%d-%b-%Y"    | endif
if !exists("g:tskelUserName")      | let g:tskelUserName      = "<+NAME+>"    | endif
if !exists("g:tskelUserAddr")      | let g:tskelUserAddr      = "<+ADDRESS+>" | endif
if !exists("g:tskelUserEmail")     | let g:tskelUserEmail     = "<+EMAIL+>"   | endif
if !exists("g:tskelUserWWW")       | let g:tskelUserWWW       = "<+WWW+>"     | endif

if !exists("g:tskelRevisionMarkerRx") | let g:tskelRevisionMarkerRx = '@Revision:\s\+' | endif
if !exists("g:tskelRevisionVerRx")    | let g:tskelRevisionVerRx = '\(RC\d*\|pre\d*\|p\d\+\|-\?\d\+\)\.' | endif
if !exists("g:tskelRevisionGrpIdx")   | let g:tskelRevisionGrpIdx = 3 | endif

if !exists("g:tskelMaxRecDepth") | let g:tskelMaxRecDepth = 10 | endif

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
    autocmd BufNewFile *.html    TSkeletonSetup html.html
endif

let s:tskelScratchIdx = 0
let s:tskelScratchMax = 0
let s:tskelDestBufNr  = -1
let s:tskelPattern = g:tskelPatternLeft ."\\(\\(".
            \ "?[^:]\\+\\|b:[^:]\\+\\|g:[^:]\\+\\|bit:[^:]\\+".
            \ "\\|call:\\('[^']*'\\|\"\\(\\\\\"\\|[^\"]\\)*\"\\|[bgs]:\\|.\\)\\{-1,}\\)".
            \ "\\|[a-zA-Z ]\\+".
            \ "\\)\\(: *.\\{-} *\\)\\?". g:tskelPatternRight

fun! TSkeletonFillIn(bit, ...)
    " try
        let filetype = a:0 >= 1 && a:1 != "" ? a:1 : ""
        let ft       = filetype != "" ? ", '". filetype ."'" : ""
        " echom "DBG TSkeletonFillIn: filetype=". filetype
        call <SID>GetBitProcess("before", "b:tskelBitProcess_")
        call <SID>GetBitProcess("after", "b:tskelBitProcess_")
        if exists("b:tskelBitProcess_before")
            exec b:tskelBitProcess_before
            unlet b:tskelBitProcess_before
        endif
        " Work-around for interesting vim-behaviour
        silent norm! ggO
        while search(s:tskelPattern, "W") > 0
            let col  = virtcol(".")
            let line = strpart(getline("."), col - 1)
            let text = substitute(line, s:tskelPattern .'.*$', '\1', '')
            let mod  = substitute(line, s:tskelPattern .'.*$', '\5', '')
            let s:tskelPostExpand = ""
            " echom "DBG text=". text
            let repl = <SID>HandleTag(text, filetype)
            if repl != "" && line =~ '\V\^'. escape(repl, '\')
                norm! l
            else
                let repl = <SID>Modify(repl, mod)
                let repl = substitute(repl, "\<c-j>", "", "g")
                silent exec 's/\%'. col .'v'. s:tskelPattern .'/'. escape(repl, '/')
            endif
            " echom "DBG ". s:tskelPostExpand
            if s:tskelPostExpand != ""
                exec s:tskelPostExpand
                let s:tskelPostExpand = ""
            end
		endwhile
        " Undo Work-around
        silent norm! ggdd
        if !a:bit
            call <SID>SetCursor("%")
        endif
        if exists("b:tskelBitProcess_after")
            " echom "DBG ". b:tskelBitProcess_after
            exec b:tskelBitProcess_after
            unlet b:tskelBitProcess_after
        endif
    " catch
    "     echom "An error occurred in TSkeletonFillIn() ... ignored"
    " endtry
endf

fun! <SID>HandleTag(match, filetype)
    " echom "DBG HandleTag: ". a:match ." ". a:filetype
    if a:match[0] == '&'
        " echom "DBG Exec ". a:match
        return <SID>Exec("&".a:match)
    elseif a:match =~ '^[bg]:'
        " echom "DBG Exec ". a:match
        return <SID>Exec("&".a:match)
    elseif a:match =~ '\C^\([A-Z ]\+\)'
        " echom "DBG Dispatch ". a:match
        return <SID>Dispatch(a:match)
    " elseif a:match =~ '^?'
    elseif a:match[0] == '?'
        " echom "DBG Query ". strpart(a:match, 1)
        return <SID>Query(strpart(a:match, 1))
    " elseif a:match =~ '^bit:'
    elseif strpart(a:match, 0, 4) =~ 'bit:'
        " echom "DBG BIT ". strpart(a:match, 4) ." ". a:filetype
        return <SID>Expand(strpart(a:match, 4), a:filetype)
    " elseif a:match =~ '^call:'
    elseif strpart(a:match, 0, 5) =~ 'call:'
        " echom "DBG Call ". strpart(a:match, 5) ." ". a:filetype
        return <SID>Call(strpart(a:match, 5))
    else
        " echom "DBG ??? ". a:match
        return a:match
    end
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
    let {a:var}{a:name} = substitute("silent normal :". a:match, "\n", "\n:", "g") ."\n"
    " echom "DBG SaveBitProcess: ". {a:var}{a:name}
    return ""
endf

fun! <SID>GetBitProcess(name, var)
    silent norm! gg
    " echom "DBG GetBitProcess ". a:name
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
    if a:modifier =~? premod.'C'
        let rv = substitute(rv, '\(^\|[^a-zA-Z0-9_]\)\(.\)', '\u\2', 'g')
    endif
    if a:modifier =~? premod.'s'
        let mod  = substitute(a:modifier, '^[^s]*s\(.*\)$', '\1', '')
        " let rxm  = '\V'
        let rxm  = ''
        let sep  = mod[0]
        let esep = escape(sep, '\')
        let pat  = '\(\[^'. sep .']\*\)'
        let rx   = '\V\^'. esep . pat . esep . pat . esep .'\$'
        let from = substitute(mod, rx, '\1', '')
        let to   = substitute(mod, rx, '\2', '')
        let rv   = substitute(rv, rxm . from, to, 'g')
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

fun! <SID>Call(fn)
    return TSkeletonExecInDestBuffer("return ". a:fn)
endf

fun! <SID>Expand(bit, ...)
    let ft = a:0 >= 1 && a:0 != "" ? a:1 : &filetype
    " echom "DBG Expand: ". a:bit ." ". ft
    call <SID>PrepareBits(ft)
    let t = @t
    try
        let sepx = match(a:bit, "|")
        if sepx == -1
            let name    = a:bit
            let default = ""
        else
            let name    = strpart(a:bit, 0, sepx)
            let default = strpart(a:bit, sepx + 1)
        endif
        let @t = ""
        let bitfname = <SID>SelectBit(name, ft)
        let indent   = <SID>GetIndent(line("."))
        if bitfname != ""
            let setCursor = <SID>RetrieveBit(bitfname, indent, ft)
        endif
        if @t == ""
            if default =~ '".*"'
                let @t = substitute(default, '^"\(.*\)"$', '\1', '')
            elseif default != ""
                let s:tskelPostExpand = s:tskelPostExpand .'|norm '. default
            else
                let @t = '<+bit:'.a:bit.'+>'
            endif
        endif
        " echom "DBG bit=". a:bit ." ft=". ft ." bitfname=". bitfname ." :: ". @t
        return @t
    finally
        let @t = t
    endtry
endf

fun! TSkeletonGetVar(name, ...)
    if TSkeletonExecInDestBuffer('return exists("b:'. a:name .'")')
        return TSkeletonExecInDestBuffer('return b:'. a:name)
    elseif a:0 >= 1
        exec "return ". a:1
    else
        exec "return g:". a:name
    endif
endf

fun! TSkeletonExecInDestBuffer(code)
    let cb = bufnr("%")
    try
        if s:tskelDestBufNr >= 0
            silent exec "buffer ". s:tskelDestBufNr
        endif
        exec a:code
    finally
        if bufnr("%") != cb
            silent exec "buffer ". cb
        endif
    endtry
endf

fun! TSkeleton_FILE_DIRNAME()
    return TSkeletonExecInDestBuffer('return expand("%:p:h")')
endf

fun! TSkeleton_FILE_SUFFIX()
    return TSkeletonExecInDestBuffer('return expand("%:e")')
endf

fun! TSkeleton_FILE_NAME_ROOT()
    return TSkeletonExecInDestBuffer('return expand("%:t:r")')
endf

fun! TSkeleton_FILE_NAME()
    return TSkeletonExecInDestBuffer('return expand("%:t")')
endf

fun! TSkeleton_NOTE()
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
    let email = TSkeletonGetVar("tskelUserEmail")
    " return substitute(email, "@"," AT ", "g")
    return email
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
        if filereadable(g:tskelDir . a:template)
            let tf = g:tskelDir . a:template
        elseif filereadable(g:tskelDir ."prefab/". a:template)
            let tf = g:tskelDir ."prefab/". a:template
        else
            echoerr "Unknown skeleton: ". a:template
        endif
        try
            let cpoptions = &cpoptions
            set cpoptions-=a
            exe "0read ". tf
            norm! Gdd
        finally
            let &cpoptions = cpoptions
        endtry
        call TSkeletonFillIn(0, &filetype)
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
        " echom "Template: ". tpl
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
        " echom "Template: ". dir
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
        call TSkeletonFillIn(0, &filetype)
        exe "bdelete ". tpl
    endif
endf
command! -nargs=* -complete=custom,TSkeletonSelectTemplate TSkeletonNewFile 
            \ call TSkeletonNewFile(<f-args>)



fun! <SID>GlobBits(path, ...)
    let pt = a:0 >= 1 ? a:1 : "*"
    let rv = globpath(a:path, pt)
    let rv = "\n". substitute(rv, '\\', '/', 'g') ."\n"
    let rv = substitute(rv, '\n\zs.\{-}/\([^/]\+\)\ze\n', '\1', 'g')
    return strpart(rv, 1)
endf

" <SID>PrepareBits(?filetype=&ft)
fun! <SID>PrepareBits(...)
    if a:0 >= 1
        let filetype   = a:1
        let use_cached = 1
    else
        let filetype   = &filetype
        let use_cached = 0
    endif
    if !use_cached || !exists("g:tskelBits_". filetype)
        let g:tskelBits{filetype} = <SID>GlobBits(g:tskelBitsDir . &filetype ."/,". g:tskelBitsDir ."general/")
    endif
    let b:tskelBits = g:tskelBits{filetype}
endf

fun! <SID>ResetBits()
    unlet b:tskelBits
endf

fun! TSkeletonSelectBit(ArgLead, CmdLine, CursorPos)
    call <SID>PrepareBits()
    return b:tskelBits
endf

" <SID>RetrieveBit(bit, indent, ?filetype) => setCursor?; @t=expanded template bit
fun! <SID>RetrieveBit(bit, indent, ...)
    let ft = a:0 >= 1 ? a:1 : &filetype
    let @t = ""
    " echom "DBG RetrieveBit: ft=". ft
    if s:tskelScratchIdx >= g:tskelMaxRecDepth
        return 0
    endif
    let cpoptions = &cpoptions
    if s:tskelScratchIdx == 0
        let s:tskelDestBufNr = bufnr("%")
    endif
    let s:tskelScratchIdx = s:tskelScratchIdx + 1
    if s:tskelScratchIdx > s:tskelScratchMax
        let s:tskelScratchMax = s:tskelScratchIdx
        let s:tskelScratchNr{s:tskelScratchIdx} = -1
    endif
    " echom "DBG RetrieveBit ". s:tskelScratchIdx . ": ". a:bit
    try
        let tsbnr = bufnr(s:tskelScratchNr{s:tskelScratchIdx})
        if tsbnr >= 0
            silent exec "buffer ". tsbnr
        else
            silent exec "edit [TSkeletonScratch_". s:tskelScratchIdx ."]"
            let s:tskelScratchNr{s:tskelScratchIdx} = bufnr("%")
        endif
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        setlocal nobuflisted
        if ft != ""
            call <SID>PrepareBits(ft)
        endif
        silent norm! ggdG
        set cpoptions-=a
        silent exe "0read ". a:bit
        call <SID>IndentLines(1, line("$"), a:indent)
        silent norm! gg
        call TSkeletonFillIn(1, ft)
        let setCursor = <SID>SetCursor(".,$", 1)
        silent norm! ggvGk$"ty
        return setCursor
    finally
        let &cpoptions = cpoptions
        " exec "bwipeout ". s:tskelScratchNr{s:tskelScratchIdx}
        " let s:tskelScratchNr{s:tskelScratchIdx} = -1
        let s:tskelScratchIdx = s:tskelScratchIdx - 1
        " trick |alternate-file|
        " try
        "     silent edit #2
        " catch
        "     if expand("%") == ""
        "         throw "This is the first anonymous buffer ... aborting"
        "     endif
        " endtry
        if s:tskelScratchIdx == 0
            silent exec "buffer ". s:tskelDestBufNr
            let s:tskelDestBufNr = -1
        else
            silent exec "buffer ". s:tskelScratchNr{s:tskelScratchIdx}
        endif
    endtry
endf

if exists("g:tskelSimpleBits") && g:tskelSimpleBits
    fun! <SID>InsertBit(bit)
        let cpoptions = &cpoptions
        set cpoptions-=a
        exe "read ". a:bit
        let &cpoptions = cpoptions
    endf
else
    " let s:tskelScratchNr{s:tskelScratchIdx} = -1
    fun! <SID>InsertBit(bit)
        " echom "DBG InsertBit: ". a:bit
        set cpoptions-=a
        let t = @t
        try
            let l = line(".")
            let i = <SID>GetIndent(l)
            let setCursor = <SID>RetrieveBit(a:bit, i)
            silent norm! $"tgp
            if setCursor
                call <SID>SetCursor(".,$")
            endif
        finally
            let @t = t
        endtry
    endf
endif

fun! <SID>GetIndent(line)
    return matchstr(getline(a:line), '^\(\s*\)')
endf

fun! <SID>IndentLines(from, to, indent)
    silent exec a:from.",".a:to."s/^/". escape(a:indent, '/\') .'/'
endf

fun! <SID>SelectBitInSubdir(subdir, bit)
    if a:subdir == "" || a:bit == ""
        return 0
    else
        let ffbits = "\n". <SID>GlobBits(g:tskelBitsDir . a:subdir ."/") ."\n"
        " echom "DBG ". a:subdir .": ". ffbits ." -> ". (ffbits =~ "\\V\n". a:bit ."\n")
        if ffbits =~ "\\V\n". a:bit ."\n"
            return g:tskelBitsDir . a:subdir ."/". a:bit
        else
            return ""
        endif
    endif
endf

fun! <SID>SelectBit(bit, ...)
    let ft = a:0 >= 1 ? a:1 : &filetype
    " echom "DBG SelectBit: bit=". a:bit ." ft=". ft
    let bf = <SID>SelectBitInSubdir(ft, a:bit)
    if bf == ""
        let bf = <SID>SelectBitInSubdir("general", a:bit)
    endif
    return bf
endf

fun! TSkeletonBit(bit)
    " try
        let bf = <SID>SelectBit(a:bit)
        if bf != ""
            call <SID>InsertBit(bf)
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

if !hasmapto("TSkeletonBit")
    noremap <unique> <Leader>tt :TSkeletonBit 
endif

fun! TSkeletonExpandBitUnderCursor()
    echo
    call <SID>PrepareBits()
    let t = @t
    silent norm! "tdiw
    if !TSkeletonBit(@t)
        silent norm! "tP
    endif
    let @t = t
endf

if !hasmapto("TSkeletonExpandBitUnderCursor")
    nnoremap <unique> <Leader>t# :call TSkeletonExpandBitUnderCursor()<cr>
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

1.2
- new pseudo tags: bit (recursive code skeletons), call (insert function result)
- before & after sections in bit definitions may contain function definitions
- fixed: no bit name given in <SID>SelectBit()
- don't use ={motion} to indent text, but simply shift it

