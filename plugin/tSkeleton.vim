" tSkeleton.vim
" @Author:      Thomas Link (samul AT web.de)
" @Website:     http://members.a1.net/t.link/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     21-Sep-2004.
" @Last Change: 14-Mai-2005.
" @Revision:    1.4.199
"
" vimscript #1160
"
" TODO:

if &cp || exists("loaded_tskeleton") "{{{2
    finish
endif
let loaded_tskeleton = 104

if !exists('loaded_multvals') "{{{2
    runtime plugin/genutils.vim
    if !exists('loaded_genutils')
        echoerr "tSkeleton: genutils (vimscript #197) is required"
        finish
    endif
endif

if !exists("g:tskelDir") "{{{2
    if has("win16") || has("win32") || has("win64")
        let g:tskelDir = $VIM ."/vimfiles/skeletons/"
    else
        let g:tskelDir = $HOME ."/.vim/skeletons/"
    endif
endif

let g:tskelBitsDir = g:tskelDir ."bits/"

if !exists("g:tskelLicense") "{{{2
    let g:tskelLicense = "GPL (see http://www.gnu.org/licenses/gpl.txt)"
endif

if !exists("g:tskelMapLeader")     | let g:tskelMapLeader     = "<Leader>#"   | endif "{{{2
if !exists("g:tskelPatternLeft")   | let g:tskelPatternLeft   = "<+"          | endif "{{{2
if !exists("g:tskelPatternRight")  | let g:tskelPatternRight  = "+>"          | endif "{{{2
if !exists("g:tskelPatternCursor") | let g:tskelPatternCursor = "<+CURSOR+>"  | endif "{{{2
if !exists("g:tskelDateFormat")    | let g:tskelDateFormat    = "%d-%b-%Y"    | endif "{{{2
if !exists("g:tskelUserName")      | let g:tskelUserName      = "<+NAME+>"    | endif "{{{2
if !exists("g:tskelUserAddr")      | let g:tskelUserAddr      = "<+ADDRESS+>" | endif "{{{2
if !exists("g:tskelUserEmail")     | let g:tskelUserEmail     = "<+EMAIL+>"   | endif "{{{2
if !exists("g:tskelUserWWW")       | let g:tskelUserWWW       = "<+WWW+>"     | endif "{{{2

if !exists("g:tskelRevisionMarkerRx") | let g:tskelRevisionMarkerRx = '@Revision:\s\+' | endif "{{{2
if !exists("g:tskelRevisionVerRx")    | let g:tskelRevisionVerRx = '\(RC\d*\|pre\d*\|p\d\+\|-\?\d\+\)\.' | endif "{{{2
if !exists("g:tskelRevisionGrpIdx")   | let g:tskelRevisionGrpIdx = 3 | endif "{{{2

if !exists("g:tskelMaxRecDepth") | let g:tskelMaxRecDepth = 10 | endif "{{{2
if !exists("g:tskelChangeDir")   | let g:tskelChangeDir   = 1  | endif "{{{2

if !exists("g:tskelDontSetup") "{{{2
    autocmd BufNewFile *.bat       TSkeletonSetup batch.bat
    autocmd BufNewFile *.tex       TSkeletonSetup latex.tex
    autocmd BufNewFile tc-*.rb     TSkeletonSetup tc-ruby.rb
    autocmd BufNewFile *.rb        TSkeletonSetup ruby.rb
    autocmd BufNewFile *.rbx       TSkeletonSetup ruby.rb
    autocmd BufNewFile *.sh        TSkeletonSetup shell.sh
    autocmd BufNewFile *.txt       TSkeletonSetup text.txt
    autocmd BufNewFile *.vim       TSkeletonSetup plugin.vim
    autocmd BufNewFile *.inc.php   TSkeletonSetup php.inc.php
    autocmd BufNewFile *.class.php TSkeletonSetup php.class.php
    autocmd BufNewFile *.php       TSkeletonSetup php.php
    autocmd BufNewFile *.tpl       TSkeletonSetup smarty.tpl
    autocmd BufNewFile *.html      TSkeletonSetup html.html
endif

autocmd BufNewFile,BufRead */skeletons/*    setf tskeleton

let s:tskelScratchIdx = 0
let s:tskelScratchMax = 0
let s:tskelDestBufNr  = -1
let s:tskelPattern = g:tskelPatternLeft ."\\("
            \ ."&.\\{-}\\|b:.\\{-}\\|g:.\\{-}\\|bit:.\\{-}"
            \ ."\\|?.\\{-}?"
            \ ."\\|call:\\('[^']*'\\|\"\\(\\\\\"\\|[^\"]\\)*\"\\|[bgs]:\\|.\\)\\{-1,}"
            \ ."\\|[a-zA-Z ]\\+"
            \ ."\\)\\(: *.\\{-} *\\)\\?". g:tskelPatternRight

fun! TSkeletonFillIn(bit, ...) "{{{3
    " try
        let b:tskelFiletype = a:0 >= 1 && a:1 != "" ? a:1 : ""
        let ft = b:tskelFiletype != "" ? ", '". b:tskelFiletype ."'" : ""
        call <SID>GetBitProcess("before", "b:tskelBitProcess_")
        call <SID>GetBitProcess("after", "b:tskelBitProcess_")
        call <SID>GetBitProcess("here_before", "b:tskelBitProcess_")
        call <SID>GetBitProcess("here_after", "b:tskelBitProcess_")
        call <SID>EvalBitProcess("before", 1)
        call <SID>EvalBitProcess("here_before", 0)
        silent norm! G$
        let next = search(s:tskelPattern, "w")
        while next > 0
            let col  = virtcol(".")
            let line = strpart(getline("."), col - 1)
            let text = substitute(line, s:tskelPattern .'.*$', '\1', '')
            let mod  = substitute(line, s:tskelPattern .'.*$', '\4', '')
            let s:tskelPostExpand = ""
            let repl = <SID>HandleTag(text, b:tskelFiletype)
            if repl != "" && line =~ '\V\^'. escape(repl, '\')
                norm! l
            else
                let repl = <SID>Modify(repl, mod)
                let repl = substitute(repl, "\<c-j>", "", "g")
                silent exec 's/\%'. col .'v'. s:tskelPattern .'/'. escape(repl, '/')
            endif
            if s:tskelPostExpand != ""
                exec s:tskelPostExpand
                let s:tskelPostExpand = ""
            end
            let next = search(s:tskelPattern, "W")
		endwhile
        if !a:bit
            call <SID>SetCursor("%", "")
        endif
        call <SID>EvalBitProcess("here_after", 0)
        call <SID>EvalBitProcess("after", 1)
    " catch
    "     echom "An error occurred in TSkeletonFillIn() ... ignored"
    " endtry
endf

fun! <SID>HandleTag(match, filetype) "{{{3
    if a:match =~ '^[bg]:'
        return <SID>Exec(a:match)
    elseif a:match =~ '\C^\([A-Z ]\+\)'
        return <SID>Dispatch(a:match)
    elseif a:match[0] == '&'
        return <SID>Exec(a:match)
    elseif a:match[0] == '?'
        return <SID>Query(strpart(a:match, 1))
    elseif strpart(a:match, 0, 4) =~ 'bit:'
        return <SID>Expand(strpart(a:match, 4), a:filetype)
    elseif strpart(a:match, 0, 5) =~ 'call:'
        return <SID>Call(strpart(a:match, 5))
    else
        return a:match
    end
endf

fun! <SID>SetCursor(from, to, ...) "{{{3
    let findOnly = a:0 >= 1 ? a:1 : (s:tskelScratchIdx > 1)
    let c = virtcol(".")
    let l = line(".")
    if a:to == ""
        if a:from == "%"
            silent norm! gg
        else
            exec a:from
        endif
    else
        exec a:to
    end
    if line(".") == 1
        norm! G$
        let l = search(g:tskelPatternCursor, "w")
    else
        norm! k$
        let l = search(g:tskelPatternCursor, "W")
    end
    if l == 0
        silent exec "norm! ". c ."|". l ."G"
        return 0
    elseif !findOnly
        let c = col(".")
        silent exec 's/'. g:tskelPatternCursor .'//e'
        " silent exec 's/'. g:tskelPatternCursor .'//e'
        silent exec "norm! ". c ."|"
    endif
    return l
endf

fun! <SID>Exec(arg) "{{{3
    return TSkeletonEvalInDestBuffer(a:arg)
endf

fun! TSkelIncreaseIndex(var) "{{{3
    exec "let ". a:var ."=". a:var ."+1"
    return a:var
endf

fun! <SID>Query(arg) "{{{3
    let sepx = match(a:arg, "|")
    let var  = strpart(a:arg, 0, sepx)
    let text = substitute(strpart(a:arg, sepx + 1), ':?$', ':', '')
    if var != ""
        if !TSkeletonEvalInDestBuffer("exists('". var ."')")
            echom "Unknown choice variable: ". var
        else
            let b:tskelQueryIndex = 0
            let val = TSkeletonEvalInDestBuffer(var)
            echo "Choices:"
            let val = substitute("\n". val. "\n", "\n\\zs\\(.\\{-}\\)\\ze\n", "\\=<SID>QuerySeparator(submatch(1))", "g")
            unlet b:tskelQueryIndex
            let sel = input(text. " ")
            if sel != ""
                let rv = matchstr(val, "\n". sel .": \\zs\\(.\\{-}\\)\\ze\n")
                if rv == val
                    return sel
                else
                    return rv
                endif
            else
                return ""
            endif
        endif
    endif
    return input(text. " ")
endf

fun! <SID>QuerySeparator(txt)
    let b:tskelQueryIndex = b:tskelQueryIndex + 1
    let rv = b:tskelQueryIndex .": ". a:txt
    echo rv
    return rv
endf

fun! <SID>SaveBitProcess(name, var, match) "{{{3
    " call TSkeletonExecInDestBuffer('let '. a:var . a:name .'_'. s:tskelScratchIdx .' = substitute("normal :'. escape(a:match, '"\') .'", "\n", "\n:", "g") ."\n"')
    call TSkeletonExecInDestBuffer('let '. a:var . a:name .'_'. s:tskelScratchIdx .' = "'. escape(a:match, '"\') .'"')
    return ""
endf

fun! <SID>GetBitProcess(name, var) "{{{3
    silent norm! gg
    exec 's/^\s*<tskel:'. a:name .'>\s*\n\(\(.\{-}\n\)\{-}\)\s*<\/tskel:'. a:name .'>\s*\n/\=<SID>SaveBitProcess("'. a:name .'", "'. a:var .'", submatch(1))/e'
endf

fun! <SID>EvalBitProcess(name, evalInDestBuffer) "{{{3
    if TSkeletonEvalInDestBuffer('exists("b:tskelBitProcess_'. a:name .'_'. s:tskelScratchIdx .'")')
        if a:evalInDestBuffer
            call TSkeletonExecInDestBuffer('exec b:tskelBitProcess_'. a:name .'_'. s:tskelScratchIdx)
        else
            exec TSkeletonEvalInDestBuffer('b:tskelBitProcess_'. a:name .'_'. s:tskelScratchIdx)
        endif
        call TSkeletonExecInDestBuffer('unlet b:tskelBitProcess_'. a:name .'_'. s:tskelScratchIdx)
    endif
endf

fun! <SID>Modify(text, modifier) "{{{3
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

fun! <SID>Dispatch(name) "{{{3
    let name = substitute(a:name, '^ *\(.\{-}\) *$', '\1', '')
    let name = substitute(name, " ", "_", "g")
    if exists("*TSkeleton_". name)
        return TSkeleton_{name}()
    else
        return g:tskelPatternLeft . a:name . g:tskelPatternRight
    endif
endf

fun! <SID>Call(fn) "{{{3
    return TSkeletonEvalInDestBuffer(a:fn)
endf

fun! <SID>Expand(bit, ...) "{{{3
    let ft = a:0 >= 1 && a:0 != "" ? a:1 : &filetype
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
        let indent   = <SID>GetIndent(getline("."))
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
        return @t
    finally
        let @t = t
    endtry
endf

fun! TSkeletonGetVar(name, ...) "{{{3
    if TSkeletonEvalInDestBuffer('exists("b:'. a:name .'")')
        return TSkeletonEvalInDestBuffer('b:'. a:name)
    elseif a:0 >= 1
        exec "return ". a:1
    else
        exec "return g:". a:name
    endif
endf

fun! TSkeletonEvalInDestBuffer(code) "{{{3
    return TSkeletonExecInDestBuffer("return ". a:code)
endf

fun! TSkeletonExecInDestBuffer(code) "{{{3
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

fun! TSkeleton_FILE_DIRNAME() "{{{3
    return TSkeletonEvalInDestBuffer('expand("%:p:h")')
endf

fun! TSkeleton_FILE_SUFFIX() "{{{3
    return TSkeletonEvalInDestBuffer('expand("%:e")')
endf

fun! TSkeleton_FILE_NAME_ROOT() "{{{3
    return TSkeletonEvalInDestBuffer('expand("%:t:r")')
endf

fun! TSkeleton_FILE_NAME() "{{{3
    return TSkeletonEvalInDestBuffer('expand("%:t")')
endf

fun! TSkeleton_NOTE() "{{{3
    let title = TSkeletonGetVar("tskelTitle", 'input("Please describe the project: ")')
    let note  = title != "" ? " -- ".title : ""
    return note
endf

fun! TSkeleton_DATE() "{{{3
    return strftime(TSkeletonGetVar("tskelDateFormat"))
endf

fun! TSkeleton_TIME() "{{{3
    return strftime("%X")
endf

fun! TSkeleton_AUTHOR() "{{{3
    return TSkeletonGetVar("tskelUserName")
endf

fun! TSkeleton_EMAIL() "{{{3
    let email = TSkeletonGetVar("tskelUserEmail")
    " return substitute(email, "@"," AT ", "g")
    return email
endf

fun! TSkeleton_WEBSITE() "{{{3
    return TSkeletonGetVar("tskelUserWWW")
endf

fun! TSkeleton_LICENSE() "{{{3
    return TSkeletonGetVar("tskelLicense")
endf

fun! TSkeletonSetup(template, ...) "{{{3
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
        if g:tskelChangeDir
            exec "cd ". substitute(expand("%:p:h"), '\', '/', 'g')
        endif
        let b:tskelDidFillIn = 1
    endif
endf

fun! TSkeletonSelectTemplate(ArgLead, CmdLine, CursorPos) "{{{3
    if a:CmdLine =~ '^.\{-}\s\+.\{-}\s'
        return ""
    else
        return <SID>GlobBits(g:tskelDir ."/,". g:tskelDir ."prefab/")
    endif
endf

command! -nargs=* -complete=custom,TSkeletonSelectTemplate TSkeletonSetup 
            \ call TSkeletonSetup(<f-args>)

if exists("*browse") "{{{2
    fun! <SID>TSkeletonBrowse(save, title, initdir, default) "{{{3
        return browse(a:save, a:title, a:initdir, a:default)
    endf
else
    fun! <SID>TSkeletonBrowse(save, title, initdir, default) "{{{3
        let dir = substitute(a:initdir, '\\', '/', "g")
        let files = substitute(glob(dir. "*"), '\V\(\_^\|\n\)\zs'. dir, '', 'g')
        let files = substitute(files, "\n", ", ", "g")
        echo files
        let tpl = input(a:title ." -- choose file: ")
        return a:initdir. tpl
    endf
endif

" TSkeletonEdit(?dir)
fun! TSkeletonEdit(...) "{{{3
    let tpl  = <SID>TSkeletonBrowse(0, "Template", g:tskelDir, "")
    if tpl != ""
        let tpl = a:0 >= 1 && a:1 ? g:tskelDir.a:1 : fnamemodify(tpl, ":p")
        exe "edit ". tpl
    end
endf
command! -nargs=* -complete=custom,TSkeletonSelectTemplate TSkeletonEdit 
            \ call TSkeletonEdit(<f-args>)

" TSkeletonNewFile(?template, ?dir, ?fileName)
fun! TSkeletonNewFile(...) "{{{3
    if a:0 >= 1 && a:1 != ""
        let tpl = g:tskelDir. a:1
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



fun! <SID>GlobBits(path, ...) "{{{3
    let pt = a:0 >= 1 ? a:1 : "*"
    let rv = globpath(a:path, pt)
    let rv = "\n". substitute(rv, '\\', '/', 'g') ."\n"
    let rv = substitute(rv, '\n\zs.\{-}/\([^/]\+\)\ze\n', '\1', 'g')
    return strpart(rv, 1)
endf

" <SID>PrepareBits(?filetype=&ft)
fun! <SID>PrepareBits(...) "{{{3
    if a:0 >= 1
        let filetype   = a:1
        let use_cached = 1
    else
        let filetype   = &filetype
        let use_cached = 0
    endif
    if !use_cached || !exists("g:tskelBits". filetype)
        let g:tskelBits{filetype} = <SID>GlobBits(g:tskelBitsDir . &filetype ."/,". g:tskelBitsDir ."general/")
    endif
    let b:tskelBits = g:tskelBits{filetype}
endf

fun! <SID>ResetBits() "{{{3
    unlet b:tskelBits
endf

fun! TSkeletonSelectBit(ArgLead, CmdLine, CursorPos) "{{{3
    call <SID>PrepareBits()
    return b:tskelBits
endf

" <SID>RetrieveBit(bit, indent, ?filetype) => setCursor?; @t=expanded template bit
fun! <SID>RetrieveBit(bit, indent, ...) "{{{3
    let ft = a:0 >= 1 ? a:1 : &filetype
    let @t = ""
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
    let setCursor = 0
    try
        let tsbnr = bufnr(s:tskelScratchNr{s:tskelScratchIdx})
        if tsbnr >= 0
            " silent split
            silent exec "sbuffer ". tsbnr
        else
            silent split
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
        let setCursor = <SID>SetCursor("%", "", 1)
        silent norm! ggvGk$"ty
    finally
        let &cpoptions = cpoptions
        " if s:tskelScratchIdx > 0
            " let s:tskelScratchNr{s:tskelScratchIdx} = -1
            " bwipeout!
            wincmd c
        " endif
        let s:tskelScratchIdx = s:tskelScratchIdx - 1
        if s:tskelScratchIdx == 0
            silent exec "buffer ". s:tskelDestBufNr
            let s:tskelDestBufNr = -1
        else
            silent exec "buffer ". s:tskelScratchNr{s:tskelScratchIdx}
        endif
    endtry
    return setCursor
endf

if exists("g:tskelSimpleBits") && g:tskelSimpleBits "{{{2
    fun! <SID>InsertBit(bit) "{{{3
        let cpoptions = &cpoptions
        set cpoptions-=a
        exe "read ". a:bit
        let &cpoptions = cpoptions
    endf
else
    fun! <SID>InsertBit(bit) "{{{3
        set cpoptions-=a
        let t = @t
        try
            let c  = virtcol(".")
            let e  = virtcol("$")
            let l  = line(".")
            let li = getline(l)
            " Adjust for vim idiocracy
            if c == e - 1 && li[c - 1] == " "
                let e = e - 1
            endif
            let i = <SID>GetIndent(l)
            let setCursor = <SID>RetrieveBit(a:bit, i)
            " silent norm! $"tgp
            exec 'silent norm! '. c .'|'
            if c == e
                silent norm! "tgp
            else
                silent norm! "tgP
            end
            if setCursor
                let ll = l + setCursor - 1
                call <SID>SetCursor(l, ll)
            endif
        finally
            let @t = t
        endtry
    endf
endif

fun! <SID>GetIndent(line) "{{{3
    return matchstr(a:line, '^\(\s*\)')
endf

fun! <SID>IndentLines(from, to, indent) "{{{3
    silent exec a:from.",".a:to."s/^/". escape(a:indent, '/\') .'/'
endf

fun! <SID>SelectBitInSubdir(subdir, bit) "{{{3
    if a:subdir == "" || a:bit == ""
        return 0
    else
        let ffbits = "\n". <SID>GlobBits(g:tskelBitsDir . a:subdir ."/") ."\n"
        if ffbits =~ "\\V\n". a:bit ."\n"
            return g:tskelBitsDir . a:subdir ."/". a:bit
        else
            return ""
        endif
    endif
endf

fun! <SID>SelectBit(bit, ...) "{{{3
    let ft = a:0 >= 1 ? a:1 : &filetype
    let bf = <SID>SelectBitInSubdir(ft, a:bit)
    if bf == ""
        let bf = <SID>SelectBitInSubdir("general", a:bit)
    endif
    return bf
endf

fun! TSkeletonBit(bit) "{{{3
    call SaveWindowSettings2('tSkeleton', 1)
    try
        let bf = <SID>SelectBit(a:bit)
        if bf != ""
            call <SID>InsertBit(bf)
            return 1
        else
            " echom "TSkeletonBit: Unknown bit '". a:bit ."'"
            return 0
        endif
        " catch
        "     echom "An error occurred in TSkeletonBit() ... ignored"
    finally
        call RestoreWindowSettings2('tSkeleton')
    endtry
endf

command! -nargs=1 -complete=custom,TSkeletonSelectBit TSkeletonBit
            \ call TSkeletonBit(<q-args>)

if !hasmapto("TSkeletonBit") "{{{2
    " noremap <unique> <Leader>tt ""diw:TSkeletonBit <c-r>"
    exec "noremap <unique> ". g:tskelMapLeader ."t :TSkeletonBit "
endif

fun! TSkeletonExpandBitUnderCursor() "{{{3
    echo
    call <SID>PrepareBits()
    let t = @t
    try
        let @t = ""
        silent norm! "tdiw
        let bit = @t
        if TSkeletonBit(bit) == 1
            " silent norm! "tP
            return 1
        elseif has("menu")
            let rx = "\n\\zs". bit .".\\{-}\\ze\n"
            let t = "\n". b:tskelBits
            let m = strlen(t)
            let i = 0
            let e = 0
            let j = 0
            try
                aunmenu ]TSkeleton
            catch
            endtry
            while 1
                let i = match(t, rx, e)
                if i >= 0
                    let j = j + 1
                    let e = matchend(t, rx, i - 1)
                    let p = strpart(t, i, e - i)
                    let x = substitute(j, '\(.\)$', '\&\1', '')
                    exec "amenu ]TSkeleton.". j .'\ '. p ." :TSkeletonBit ". p ."<cr>"
                else
                    break
                endif
            endwh
            if j == 1
                exec "TSkeletonBit ". p
            elseif j > 0
                popup ]TSkeleton
            else
                echom "TSkeletonBit: Unknown bit '". bit ."'"
                silent norm! u
                " silent norm! "tP
            endif
        endif
        return 0
    finally
        let @t = t
    endtry
endf

if !hasmapto("TSkeletonExpandBitUnderCursor") "{{{2
    exec "nnoremap <unique> ". g:tskelMapLeader ."# :call TSkeletonExpandBitUnderCursor()<cr>"
    nnoremap <unique> <Leader># :call TSkeletonExpandBitUnderCursor()<cr>
endif


" misc utilities
fun! TSkeletonIncreaseRevisionNumber() "{{{3
    let rev = exists("b:revisionRx") ? b:revisionRx : g:tskelRevisionMarkerRx
    let ver = exists("b:versionRx")  ? b:versionRx  : g:tskelRevisionVerRx
    normal m`
    exe '%s/'.rev.'\('.ver.'\)*\zs\(-\?\d\+\)/\=(submatch(g:tskelRevisionGrpIdx) + 1)/e'
    normal ``
endfun

" fun! ToirtoiseSvnLogMsg() "{{{3
"     let rev = exists("b:revisionRx") ? b:revisionRx : g:tskelRevisionMarkerRx
"     let ver = exists("b:versionRx")  ? b:versionRx  : g:tskelRevisionVerRx
"     normal m`
"     let rv = ''
"     exe '%g/'.rev.'\(\('.ver.'\)*-\?\d\+\)/let rv=getline(".")'
"     normal ``
"     return rv
" endf

" autocmd BufWritePre * call TSkeletonIncreaseRevisionNumber()

fun! TSkeletonCleanUpBibEntry()
    '{,'}s/^.*<+.\{-}+>.*\n//e
    if exists('*TSkeletonCleanUpBibEntry_User')
        call TSkeletonCleanUpBibEntry_User()
    endif
endf
command! TSkeletonCleanUpBibEntry call TSkeletonCleanUpBibEntry()
autocmd FileType bib if !hasmapto(":TSkeletonCleanUpBibEntry") | exec "noremap <buffer> ". g:tskelMapLeader ."c :TSkeletonCleanUpBibEntry<cr>" | endif

fun! TSkeletonGoToNextTag()
    let rx = '<+.\{-}+>'
    " let x  = search(rx, 'W')
    let x  = search(rx)
    if x > 0
        let ll = exists('b:tskelLastLine') ? b:tskelLastLine : 0
        let lc = exists('b:tskelLastCol')  ? b:tskelLastCol  : 0
        let l  = strpart(getline(x), lc)
        let mb = match(l, rx) + lc + 1
        let me = matchend(l, rx) + lc - mb + 1
        exec 'norm! v'. me .'l'
    endif
endf

fun! TSkeletonMapGoToNextTag()
    noremap <c-j> :call TSkeletonGoToNextTag()<cr>
    vnoremap <c-j> <C-\><C-N>:call TSkeletonGoToNextTag()<cr>
    inoremap <c-j> <c-o>:call TSkeletonGoToNextTag()<cr>
endf

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

1.3
- TSkeletonCleanUpBibEntry (mapped to <Leader>tc for bib files)
- complete set of bibtex entries
- fixed problem with [&bg]: tags
- fixed typo that caused some slowdown
- other bug fixes
- a query must be enclosed in question marks as in <+?Which ID?+>
- the "test_tSkeleton" skeleton can be used to test if tSkeleton is working
- and: after/before blocks must not contain function definitions

1.4
- Popup menu with possible completions if TSkeletonExpandBitUnderCursor() is 
called for an unknown code skeleton (if there is only one possible completion, 
this one is automatically selected)
- Make sure not to change the alternate file and not to distort the window 
layout (requires genutils)
- Syntax highlighting for code skeletons
- Skeleton bits can now be expanded anywhere in the line. This makes it 
possible to sensibly use small bits like date or time.
- Minor adjustments
- g:tskelMapLeader for easy customization of key mapping (changed the map 
leader to "<Leader>#" in order to avoid a conflict with Align; set 
g:tskelMapLeader to "<Leader>t" to get the old mappings)
- Utility function: TSkeletonGoToNextTag(); imaps.vim like key bindings via TSkeletonMapGoToNextTag()

