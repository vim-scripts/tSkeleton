" tSkeleton.vim
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     21-Sep-2004.
" @Last Change: 2007-05-13.
" @Revision:    3.2.3277
"
" vimscript #1160
" http://www.vim.org/scripts/script.php?script_id=1160
"
" TODO:
" - :TSkeletonPurgeCache ... delete old cache files
" - Check for tskel:after, tskel:before when first reading the skeleton 
"   (not every time it is expanded)
" - If g:tskelMenuPrefix == '', then the tskel isn't properly set up
" - Minibits defined in map files insert a superfluous carriage return
" - <form in php mode funktioniert nicht
" - FIX: minibits are not included in the popup menu or offered for 
"   completion
" - CHANGE: Use expand("<cword>")
" - FIX: No popup menu when nothing is selected in insert mode & cursor 
"   at last position (bibtex mode)
" - ADD: More latex & html bits
" - ADD: <tskel:post> embedded tag (evaluate some vim code on the visual 
"   region covering the final expansion)
" - FIX: The \section bit either moves the cursor after the closing 
"   curly brace or (when applying some correction) before the opening 
"   CB. This is very confusing.

if &cp || exists("loaded_tskeleton") "{{{2
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 4
    echoerr "tSkeleton requires tlib >= 0.4"
    finish
endif
if !exists('loaded_genutils')
    runtime plugin/genutils.vim
    if !exists('loaded_genutils') || loaded_genutils < 203
        echoerr 'genutils (vimscript #197) >= 2.3 is required'
        finish
    endif
endif
let loaded_tskeleton = 302

if !exists(':TAssert') "{{{2
    command! -nargs=* -bang TAssert :
    command! -nargs=* -bang TAssertBegin :
    command! -nargs=* -bang TAssertEnd :
else
    exec TAssertInit()
endif

if !exists("g:tskelDir") "{{{2
    let g:tskelDir = get(split(globpath(&rtp, 'skeletons/'), '\n'), 0, '')
endif
if !isdirectory(g:tskelDir) "{{{2
    echoerr 'tSkeleton: g:tskelDir ('. g:tskelDir .') isn''t readable. See :help tSkeleton-install for details!'
    finish
endif
let g:tskelDir = tlib#DirName(g:tskelDir)

let g:tskelBitsDir = g:tskelDir .'bits/'
call tlib#EnsureDirectoryExists(g:tskelBitsDir)

if !exists('g:tskelLicense') "{{{2
    let g:tskelLicense = 'GPL (see http://www.gnu.org/licenses/gpl.txt)'
endif

if !exists("g:tskelMapLeader")     | let g:tskelMapLeader     = "<Leader>#"   | endif "{{{2
if !exists("g:tskelMapInsert")     | let g:tskelMapInsert     = '<c-\><c-\>'  | endif "{{{2
if !exists("g:tskelAddMapInsert")  | let g:tskelAddMapInsert  = 0             | endif "{{{2
if !exists("g:tskelPatternLeft")   | let g:tskelPatternLeft   = "<+"          | endif "{{{2
if !exists("g:tskelPatternRight")  | let g:tskelPatternRight  = "+>"          | endif "{{{2
if !exists("g:tskelPatternCursor") | let g:tskelPatternCursor = "<+CURSOR+>"  | endif "{{{2
if !exists("g:tskelDateFormat")    | let g:tskelDateFormat    = '%Y-%m-%d'    | endif "{{{2
if !exists("g:tskelUserName")      | let g:tskelUserName      = "<+NAME+>"    | endif "{{{2
if !exists("g:tskelUserAddr")      | let g:tskelUserAddr      = "<+ADDRESS+>" | endif "{{{2
if !exists("g:tskelUserEmail")     | let g:tskelUserEmail     = "<+EMAIL+>"   | endif "{{{2
if !exists("g:tskelUserWWW")       | let g:tskelUserWWW       = "<+WWW+>"     | endif "{{{2

if !exists("g:tskelRevisionMarkerRx") | let g:tskelRevisionMarkerRx = '@Revision:\s\+' | endif "{{{2
if !exists("g:tskelRevisionVerRx")    | let g:tskelRevisionVerRx = '\(RC\d*\|pre\d*\|p\d\+\|-\?\d\+\)\.' | endif "{{{2
if !exists("g:tskelRevisionGrpIdx")   | let g:tskelRevisionGrpIdx = 3 | endif "{{{2

if !exists("g:tskelMaxRecDepth") | let g:tskelMaxRecDepth = 10 | endif "{{{2
if !exists("g:tskelChangeDir")   | let g:tskelChangeDir   = 1  | endif "{{{2
if !exists("g:tskelMapComplete") | let g:tskelMapComplete = 1  | endif "{{{2

if !exists("g:tskelMenuPrefix")     | let g:tskelMenuPrefix  = 'TSke&l'    | endif "{{{2
if !exists("g:tskelMenuCache")      | let g:tskelMenuCache = '.tskelmenu'  | endif "{{{2
if !exists("g:tskelMenuPriority")   | let g:tskelMenuPriority = 90         | endif "{{{2
if !exists("g:tskelMenuMiniPrefix") | let g:tskelMenuMiniPrefix = 'etc.'   | endif "{{{2

if !exists("g:tskelUseBufferCache") | let g:tskelUseBufferCache = 1             | endif "{{{2
if !exists("g:tskelBufferCacheDir") | let g:tskelBufferCacheDir = '.tskeleton'  | endif "{{{2

if !exists("g:tskelTypes") "{{{2
    " let g:tskelTypes = ['skeleton', 'tags', 'functions']
    let g:tskelTypes = ['skeleton']
endif

if !exists("g:tskelMenuPrefix_tags") | let g:tskelMenuPrefix_tags = 'Tags.' | endif "{{{2

if !exists("g:tskelQueryType") "{{{2
    " if has('gui_win32') || has('gui_win32s') || has('gui_gtk')
    "     let g:tskelQueryType = 'popup'
    " else
        let g:tskelQueryType = 'query'
    " end
endif

if !exists("g:tskelPopupNumbered") | let g:tskelPopupNumbered = 1 | endif "{{{2

" set this to v for using visual mode when calling TSkeletonGoToNextTag()
if !exists("g:tskelSelectTagMode") | let g:tskelSelectTagMode = 's' | endif "{{{2

if !exists("g:tskelKeyword_bib")  | let g:tskelKeyword_bib  = '[@[:alnum:]]\{-}'       | endif "{{{2
if !exists("g:tskelKeyword_html") | let g:tskelKeyword_html = '<\?[^>[:blank:]]\{-}'   | endif "{{{2
if !exists("g:tskelKeyword_sh")   | let g:tskelKeyword_sh   = '[\[@${([:alpha:]]\{-}'  | endif "{{{2
if !exists("g:tskelKeyword_tex")  | let g:tskelKeyword_tex  = '\\\?\w\{-}'             | endif "{{{2
if !exists("g:tskelKeyword_viki") | let g:tskelKeyword_viki = '\(#\|{\)\?[^#{[:blank:]]\{-}' | endif "{{{2

if !exists("g:tskelBitGroup_php") "{{{2
    let g:tskelBitGroup_php = ['php', 'html']
endif

let s:tskelScratchIdx  = 0
let s:tskelScratchMax  = 0
let s:tskelDestBufNr   = -1
let s:tskelBuiltMenu   = 0
let s:tskelSetFiletype = 1
let s:tskelLine        = 0
let s:tskelCol         = 0
let s:tskelProcessing  = 0
let s:tskelPattern     = g:tskelPatternLeft ."\\("
            \ ."&.\\{-}\\|b:.\\{-}\\|g:.\\{-}\\|bit:.\\{-}\\|tskel:.\\{-}"
            \ ."\\|?.\\{-}?"
            \ ."\\|call:\\('[^']*'\\|\"\\(\\\\\"\\|[^\"]\\)*\"\\|[bgs]:\\|.\\)\\{-1,}"
            \ ."\\|[a-zA-Z ]\\+"
            \ ."\\)\\(: *.\\{-} *\\)\\?". g:tskelPatternRight

function! TSkeletonFillIn(bit, ...) "{{{3
    " try
        " TLogVAR a:bit
        let ft = a:0 >= 1 && a:1 != '' ? a:1 : ''
        " TLogVAR ft
        call s:PrepareBits(ft)
        " TLogDBG string(getline(1, '$'))
        let bitdef = get(b:tskelBitDefs, a:bit, {})
        " TLogVAR bitdef
        let meta = get(bitdef, 'meta', {})
        " TLogVAR meta
        if !empty(meta)
            let msg = get(meta, 'msg', '')
            if !empty(msg)
                echom msg
            endif
            call s:EvalBitProcess(get(meta, 'before'), 1)
            call s:EvalBitProcess(get(meta, 'here_before'), 0)
        endif
        " TLogDBG string(getline(1, '$'))
        " silent norm! G$
        silent norm! gg0
        " call TLogDBG(s:tskelPattern)
        let s:tskelLine_{s:tskelScratchIdx} = search(s:tskelPattern, 'cW')
        while s:tskelLine_{s:tskelScratchIdx} > 0
            " call TLogDBG(s:tskelLine_{s:tskelScratchIdx})
            " let col  = virtcol(".")
            let col  = col('.')
            let line = strpart(getline('.'), col - 1)
            let text = substitute(line, s:tskelPattern .'.*$', '\1', '')
            " TLogVAR text
            let s:tskelPostExpand = ''
            let [postprocess, repl] = s:HandleTag(text, b:tskelFiletype)
            " TLogVAR postprocess
            " TLogVAR repl
            if postprocess
                if repl != '' && line =~ '\V\^'. escape(repl, '\')
                    norm! l
                else
                    let mod  = substitute(line, s:tskelPattern .'.*$', '\4', '')
                    let repl = s:Modify(repl, mod)
                    let repl = substitute(repl, "\<c-j>", "", "g")
                    " silent exec 's/\%'. col .'v'. s:tskelPattern .'/'. escape(repl, '/')
                    silent exec 's/\%'. col .'c'. s:tskelPattern .'/'. escape(repl, '/&~')
                endif
            endif
            if s:tskelPostExpand != ''
                " call TLogDBG(s:tskelPostExpand)
                exec s:tskelPostExpand
                let s:tskelPostExpand = ''
            end
            if s:tskelLine_{s:tskelScratchIdx} > 0
                " call TLogDBG('search(s:tskelPattern, "W")')
                let s:tskelLine_{s:tskelScratchIdx} = search(s:tskelPattern, 'cW')
            endif
		endwh
        " TLogDBG "endwhile"
        if !empty(meta)
            call s:EvalBitProcess(get(meta, 'here_after'), 0)
            call s:EvalBitProcess(get(meta, 'after'), 1)
        endif
        if empty(a:bit)
            " TLogDBG "s:SetCursor"
            call s:SetCursor('%', '')
        endif
        " TLogDBG "done"
    " catch
    "     echom "An error occurred in TSkeletonFillIn() ... ignored"
    " endtry
endf

function! s:ExtractMeta(text)
    let meta = {}
    let [text, meta.msg]         = s:GetBitProcess(a:text, 'msg', 2)
    let [text, meta.before]      = s:GetBitProcess(text, 'before', 1)
    " TLogVAR meta.before
    let [text, meta.after]       = s:GetBitProcess(text, 'after', 1)
    " TLogVAR meta.after
    let [text, meta.here_before] = s:GetBitProcess(text, 'here_before', 0)
    " TLogVAR meta.here_before
    let [text, meta.here_after]  = s:GetBitProcess(text, 'here_after', 0)
    " TLogVAR meta.here_after
    return [text, meta]
endf

function! s:HandleTag(match, filetype) "{{{3
    " TLogDBG "match=". a:match
    if a:match =~ '^[bg]:'
        return [1, s:Var(a:match)]
    " elseif a:match =~ '^if '
    "     return [0, s:SwitchIf(strpart(a:match, 3))]
    " elseif a:match =~ '^elseif '
    "     return [0, s:SwitchElseif(strpart(a:match, 7))]
    " elseif a:match =~ '^else'
    "     return [0, s:SwitchElse()]
    " elseif a:match =~ '^endif '
    "     return [0, s:SwitchEndif()]
    " elseif a:match =~ '^foreach '
    "     return [0, s:SwitchForeach()]
    elseif a:match =~ '\C^\([A-Z ]\+\)'
        return [1, s:Dispatch(a:match)]
    elseif a:match[0] == '&'
        return [1, s:Exec(a:match)]
    elseif a:match[0] == '?'
        return [1, s:Query(strpart(a:match, 1, strlen(a:match) - 2))]
    elseif strpart(a:match, 0, 4) =~ 'bit:'
        return [1, s:Expand(strpart(a:match, 4), a:filetype)]
    elseif strpart(a:match, 0, 6) =~ 'tskel:'
        return [1, s:Expand(strpart(a:match, 6), a:filetype)]
    elseif strpart(a:match, 0, 5) =~ 'call:'
        return [1, s:Call(strpart(a:match, 5))]
    else
        return [1, a:match]
    end
endf

" s:SetCursor(from, to, ?mode='n', ?findOnly)
function! s:SetCursor(from, to, ...) "{{{3
    " TLogVAR a:from
    " TLogVAR a:to
    let mode     = a:0 >= 1 ? a:1 : 'n'
    let findOnly = a:0 >= 2 ? a:2 : (s:tskelScratchIdx > 1)
    let c = col('.')
    " if s:IsEOL(mode) && s:IsInsertMode(mode)
    "     let c += 1
    " end
    let l = line('.')
    if a:to == ''
        if a:from == '%'
            silent norm! gg
        else
            exec a:from
        endif
    else
        exec a:to
    end
    if line('.') == 1
        norm! G$
        let l = search(g:tskelPatternCursor, 'w')
    else
        norm! k$
        let l = search(g:tskelPatternCursor, 'W')
    end
    if l == 0
        " silent exec "norm! ". c ."|". l ."G"
        call cursor(l, c)
        return 0
    elseif !findOnly
        let c = col('.')
        silent exec 's/'. g:tskelPatternCursor .'//e'
        " silent exec 's/'. g:tskelPatternCursor .'//e'
        " silent exec "norm! ". c ."|"
        call cursor(0, c)
    endif
    " TLogVAR l
    return l
endf

" function! s:SwitchIf(text)
" endf
" 
" function! s:SwitchElseif(text)
" endf
" 
" function! s:SwitchElse()
" endf
" 
" function! s:SwitchEndif()
" endf
" 
" function! s:RemoveBranch()
" endf

function! s:Var(arg) "{{{3
    if exists(a:arg)
        exec 'return '.a:arg
    else
        return TSkeletonEvalInDestBuffer(a:arg)
    endif
endf

function! s:Exec(arg) "{{{3
    return TSkeletonEvalInDestBuffer(a:arg)
endf

function! TSkelIncreaseIndex(var) "{{{3
    exec 'let '. a:var .'='. a:var .'+1'
    return a:var
endf

function! s:Query(arg) "{{{3
    let sepx = stridx(a:arg, '|')
    let var  = strpart(a:arg, 0, sepx)
    " let text = substitute(strpart(a:arg, sepx + 1), ':?$', ':', '')
    let text = strpart(a:arg, sepx + 1)
    let tsep = stridx(text, '|')
    if tsep == -1
        let repl = ''
    else
        let repl = strpart(text, tsep + 1)
        let text = strpart(text, 0, tsep)
    endif
    if var != ''
        if !TSkeletonEvalInDestBuffer('exists('. string(var) .')')
            echom 'Unknown choice variable: '. var
        else
            let val0 = TSkeletonEvalInDestBuffer(var)
            if type(val0) == 3
                let val = val0
            else
                let val = split(val0, '\n')
            endif
            " TAssert IsList(val)
            let val = sort(copy(val))
            " TLogVAR val
            let rv = tlib#InputList('s', 'Choices:', val)
            " TLogVAR rv
            if repl != '' && rv != ''
                let rv = s:sprintf1(repl, rv)
            endif
            " TLogVAR rv
            return rv
        endif
    endif
    let rv = input(text. ' ', '')
    if rv != '' && repl != ''
        let rv = s:sprintf1(repl, rv)
    endif
    return rv
endf

function! s:GetVarName(name, global) "{{{3
    if a:global == 2
        return 's:tskelBitProcess_'. a:name
    elseif a:global == 1
        return 's:tskelBitProcess_'. s:tskelScratchIdx .'_'. a:name
    else
        return 'b:tskelBitProcess_'. a:name
    endif
endf

function! s:SaveBitProcess(name, match, global) "{{{3
    let s:tskelGetBit = a:match
    return ''
endf

function! s:GetBitProcess(text, name, global) "{{{3
    let s:tskelGetBit = ''
    let text = substitute(a:text, '^\s*<tskel:'. a:name .'>\s*\n\(\(.\{-}\n\)\{-}\)\s*<\/tskel:'. a:name .'>\s*\n', '\=s:SaveBitProcess("'. a:name .'", submatch(1), '. a:global .')', '')
    return [text, s:tskelGetBit]
endf

function! s:EvalBitProcess(eval, global) "{{{3
    " TLogVAR a:eval
    " TLogVAR a:global
    if !empty(a:eval)
        if a:global
            call TSkeletonExecInDestBuffer(a:eval)
        else
            exec a:eval
        endif
    endif
    " TLogVAR 'done'
endf

function! s:Modify(text, modifier) "{{{3
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

function! s:Dispatch(name) "{{{3
    let name = substitute(a:name, '^ *\(.\{-}\) *$', '\1', '')
    let name = substitute(name, ' ', '_', 'g')
    if exists('*TSkeleton_'. name)
        return TSkeleton_{name}()
    else
        return g:tskelPatternLeft . a:name . g:tskelPatternRight
    endif
endf

function! s:Call(fn) "{{{3
    return TSkeletonEvalInDestBuffer(a:fn)
endf

" <+TBD+> Switch to minibits
function! s:Expand(bit, ...) "{{{3
    " TLogVAR a:bit
    let ft = a:0 >= 1 && a:0 != '' ? a:1 : &filetype
    " TLogVAR ft
    " TLogVAR b:tskelFiletype
    call s:PrepareBits(ft)
    let t = @t
    try
        let sepx = match(a:bit, '|')
        if sepx == -1
            let name    = a:bit
            let default = ''
        else
            let name    = strpart(a:bit, 0, sepx)
            let default = strpart(a:bit, sepx + 1)
        endif
        let @t = ''
        " TLogDBG 'name='. name .' default='. default
        " TLogDBG string(keys(b:tskelBitDefs))
        let indent = s:GetIndent(getline('.'))
        if s:IsDefined(name)
            let setCursor = s:RetrieveBit('text', name, indent, ft)
            " TLogVAR setCursor
        endif
        if @t == ''
            if default =~ '".*"'
                let @t = substitute(default, '^"\(.*\)"$', '\1', '')
            elseif default != ''
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

function! TSkeletonGetVar(name, ...) "{{{3
    if TSkeletonEvalInDestBuffer('exists("b:'. a:name .'")')
        return TSkeletonEvalInDestBuffer('b:'. a:name)
    elseif a:0 >= 1
        exec 'return '. a:1
    else
        exec 'return g:'. a:name
    endif
endf

function! TSkeletonEvalInDestBuffer(code) "{{{3
    return TSkeletonExecInDestBuffer('return '. a:code)
endf

function! TSkeletonExecInDestBuffer(code) "{{{3
    let cb = bufnr('%')
    let wb = bufwinnr('%')
    " TLogVAR cb
    let sb = s:tskelDestBufNr >= 0 && s:tskelDestBufNr != cb
    let lazyredraw = &lazyredraw
    set lazyredraw
    if sb
        let ws = bufwinnr(s:tskelDestBufNr)
        if ws != -1
            try
                exec ws.'wincmd w'
                exec a:code
            finally
                exec wb.'wincmd w'
            endtry
        else
            try
                silent exec 'sbuffer! '. s:tskelDestBufNr
                exec a:code
            finally
                wincmd c
            endtry
        endif
    else
        exec a:code
    endif
    let &lazyredraw = lazyredraw
    " TLogDBG 'done'
endf

if !exists('*TSkeleton_FILE_DIRNAME') "{{{2
    function! TSkeleton_FILE_DIRNAME() "{{{3
        return TSkeletonEvalInDestBuffer('expand("%:p:h")')
    endf
endif

if !exists('*TSkeleton_FILE_SUFFIX') "{{{2
    function! TSkeleton_FILE_SUFFIX() "{{{3
        return TSkeletonEvalInDestBuffer('expand("%:e")')
    endf
endif

if !exists('*TSkeleton_FILE_NAME_ROOT') "{{{2
    function! TSkeleton_FILE_NAME_ROOT() "{{{3
        return TSkeletonEvalInDestBuffer('expand("%:t:r")')
    endf
endif

if !exists('*TSkeleton_FILE_NAME') "{{{2
    function! TSkeleton_FILE_NAME() "{{{3
        return TSkeletonEvalInDestBuffer('expand("%:t")')
    endf
endif

if !exists('*TSkeleton_NOTE') "{{{2
    function! TSkeleton_NOTE() "{{{3
        let title = TSkeletonGetVar("tskelTitle", 'input("Please describe the project: ")', '')
        let note  = title != "" ? " -- ".title : ""
        return note
    endf
endif

if !exists('*TSkeleton_DATE') "{{{2
    function! TSkeleton_DATE() "{{{3
        return strftime(TSkeletonGetVar('tskelDateFormat'))
    endf
endif

if !exists('*TSkeleton_TIME') "{{{2
    function! TSkeleton_TIME() "{{{3
        return strftime('%X')
    endf
endif

if !exists('*TSkeleton_AUTHOR') "{{{2
    function! TSkeleton_AUTHOR() "{{{3
        return TSkeletonGetVar('tskelUserName')
    endf
endif

if !exists('*TSkeleton_EMAIL') "{{{2
    function! TSkeleton_EMAIL() "{{{3
        let email = TSkeletonGetVar('tskelUserEmail')
        " return substitute(email, "@"," AT ", "g")
        return email
    endf
endif

if !exists('*TSkeleton_WEBSITE') "{{{2
    function! TSkeleton_WEBSITE() "{{{3
        return TSkeletonGetVar('tskelUserWWW')
    endf
endif

if !exists('*TSkeleton_LICENSE') "{{{2
    function! TSkeleton_LICENSE() "{{{3
        return TSkeletonGetVar('tskelLicense')
    endf
endif

function! TSkeletonSetup(template, ...) "{{{3
    let anyway = a:0 >= 1 ? a:1 : 0
    " TLogDBG "template=". a:template
    " TLogDBG "anyway=". anyway
    if anyway || !exists('b:tskelDidFillIn') || !b:tskelDidFillIn
        if filereadable(g:tskelDir . a:template)
            let tf = g:tskelDir . a:template
        " elseif filereadable(g:tskelDir .'prefab/'. a:template)
        "     let tf = g:tskelDir .'prefab/'. a:template
        else
            echoerr 'Unknown skeleton: '. a:template
            return
        endif
        call s:Read0(tf)
        call TSkeletonFillIn('', &filetype)
        if g:tskelChangeDir
            let cd = substitute(expand('%:p:h'), '\', '/', 'g')
            let cd = substitute(cd, '//\+', '/', 'g')
            exec 'cd '. tlib#ExArg(cd)
        endif
        let b:tskelDidFillIn = 1
    endif
endf

function! s:GetTemplates(aslist) "{{{3
    " let files = split(glob(g:tskelDir. '*'), '\n') + split(glob(g:tskelDir .'prefab/*'), '\n')
    let files = split(glob(g:tskelDir. '*'), '\n')
    call filter(files, '!isdirectory(v:val)')
    call map(files, 'fnamemodify(v:val, ":t")')
    if a:aslist
        return files
    else
        return join(files, "\n")
    endif
endf

function! TSkeletonSelectTemplate(ArgLead, CmdLine, CursorPos) "{{{3
    if a:CmdLine =~ '^.\{-}\s\+.\{-}\s'
        return ''
    else
        return s:GetTemplates(0)
    endif
endf

command! -nargs=* -complete=custom,TSkeletonSelectTemplate TSkeletonSetup 
            \ call TSkeletonSetup(<f-args>)

function! s:TSkeletonBrowse(save, title, initdir, default) "{{{3
    let tpl = tlib#InputList('s', 'Select template', s:GetTemplates(1), [
                \ {'display_format': 'filename'},
                \ ])
    return tpl
endf

" TSkeletonEdit(?dir)
function! TSkeletonEdit(...) "{{{3
    let tpl = a:0 >= 1 && !empty(a:1) ? a:1 : s:TSkeletonBrowse(0, "Template", g:tskelDir, "")
    if !empty(tpl)
        exe 'edit '. g:tskelDir . tpl
    end
endf
command! -nargs=? -complete=custom,TSkeletonSelectTemplate TSkeletonEdit 
            \ call TSkeletonEdit(<q-args>)

" TSkeletonNewFile(?template, ?dir, ?fileName)
function! TSkeletonNewFile(...) "{{{3
    if a:0 >= 1 && a:1 != ""
        let tpl = g:tskelDir. a:1
    else
        let tpl = s:TSkeletonBrowse(0, "Template", g:tskelDir, "")
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
        let fn = s:TSkeletonBrowse(1, "New File", dir, "new.".fnamemodify(tpl, ":e"))
        if fn == ""
            return
        else
            let fn = fnamemodify(fn, ":p")
        endif
    endif
    if fn != "" && tpl != ""
        exe 'edit '. tpl
        exe 'saveas '. fn
        call TSkeletonFillIn('', &filetype)
        exe "bdelete ". tpl
    endif
endf
command! -nargs=* -complete=custom,TSkeletonSelectTemplate TSkeletonNewFile 
            \ call TSkeletonNewFile(<f-args>)


" GlobBits(path, ?mode=1)
function! s:GlobBits(path, ...) "{{{3
    let mode = a:0 >= 1 ? a:1 : 1
    let pt   = "*"
    let rvs  = globpath(a:path, pt)
    let rvs  = substitute(rvs, '\\', '/', 'g')
    let rv   = split(rvs, "\n")
    if mode == 0
        call map(rv, 'fnamemodify(v:val, ":t")')
    elseif mode == 1
        call map(rv, 's:PurifyBit(v:val)')
    elseif mode == 2
    else
        echoerr 'tSkeleton: Unknown mode: '. mode
    endif
    " TAssert IsList(rv)
    return rv
endf

function! s:PrepareMiniBit(dict, def, buildmenu) "{{{3
    " TAssert IsDictionary(a:dict)
    " TAssert IsString(a:def)
    if !empty(a:def)
        let bit = matchstr(a:def, '^\S\+\ze\s')
        let exp = matchstr(a:def, '\s\zs.\+$')
        " TAssert IsString(exp)
        let a:dict[bit] = {'text': exp, 'menu': g:tskelMenuMiniPrefix . bit}
        if a:buildmenu
            call s:NewBufferMenuItem(b:tskelBufferMenu, bit)
        endif
        " TAssert IsNotEmpty(a:dict[bit])
    endif
endf

function! s:NewBufferMenuItem(menu, bit, subpriority)
    " TLogVAR a:menu
    " TLogVAR a:bit
    " TLogVAR a:subpriority
    let min = s:PrepareMenuEntry(a:bit, a:subpriority, "n")
    " TLogVAR min
    let mii = s:PrepareMenuEntry(a:bit, a:subpriority, "i")
    " TLogVAR mii
    call add(a:menu, min)
    call add(a:menu, mii)
endf

function! s:FetchMiniBits(dict, filename, buildmenu) "{{{3
    " TAssert IsDictionary(a:dict)
    " TLogDBG 'filename='. a:filename
    let c = s:ReadFile(a:filename)
    if c =~ '\S'
        for line in split(c, "\n")
            call s:PrepareMiniBit(a:dict, line, a:buildmenu)
        endfor
    endif
    return a:dict
endf

function! s:ExpandMiniBit(bit) "{{{3
    let rv = ''
    if s:IsDefined(a:bit)
        let rv = b:tskelBitDefs[a:bit]['text']
    endif
    " TAssert IsString(rv)
    return rv
endf

function! s:sprintf1(string, arg) "{{{3
    let rv = substitute(a:string, '\C\(^\|%%\|[^%]\)\zs%s', escape(a:arg, '"\'), 'g')
    let rv = substitute(rv, '%%', '%', 'g')
    return rv
    " return printf(a:string, a:arg)
endf

function! s:GetBitGroup(filetype, ...) "{{{3
    let general_first = a:0 >= 1 ? a:1 : 0
    let filetype = substitute(a:filetype, '\W', '_', 'g')
    if exists('g:tskelBitGroup_'. filetype)
        let bg = g:tskelBitGroup_{filetype}
        if type(bg) == 1
            echom 'tSkeleton: g:tskelBitGroup_'. filetype .' should be a list'
            let rv = split(bg, "\n")
        else
            let rv = copy(bg)
        endif
    else
        let rv = [filetype]
    endif
    " TAssert IsList(rv)
    if filetype != 'general'
        if general_first
            call insert(rv, 'general')
        else
            call add(rv, 'general')
        endif
    endif
    return rv
endf

function! s:PurifyBit(bit) "{{{3
    let rv = a:bit
    let rv = substitute(rv, '^[^[:cntrl:]]\{-}[/.]\([^/.[:cntrl:]]\{-}\)$', '\1', 'g')
    let rv = tlib#DecodeURL(rv)
    let rv = substitute(rv, '&', '', 'g')
    return rv
endf

function! s:DidSetup(filetype) "{{{3
    return exists('g:tskelBits_'. a:filetype)
endf

function! s:ToBeInitialized(list, filetype) "{{{3
    return index(a:list, a:filetype) != -1
endf

function! s:FiletypesToBeInitialized(ftgroup, explicit_reset) "{{{3
    if a:explicit_reset
        return a:ftgroup
    endif
    return filter(copy(a:ftgroup), 's:FiletypeToBeInitialized(v:val)')
endf

function! s:FiletypeToBeInitialized(ft) "{{{3
    if !s:DidSetup(a:ft)
        return 1
    else
        let ftm = s:GetMenuCacheFilename(a:ft)
        if empty(ftm)
            return 0
        else
            return !filereadable(ftm)
        endif
    endif
endf

" s:PrepareMenu(type, ?menuprefix='')
function! s:PrepareMenu(type, ...) "{{{3
    if g:tskelMenuCache == '' || g:tskelMenuPrefix == ''
        return
    endif
    " TLogVAR a:type
    let menu_file = s:GetMenuCacheFilename(a:type)
    " TLogVAR menu_file
    if menu_file != ''
        let sub = a:0 >= 1 ? a:1 : ''
        let tskelMenuPrefix = g:tskelMenuPrefix
        let verbose    = &verbose
        let lazyredraw = &lazyredraw
        let backup     = &backup
        let patchmode  = &patchmode
        let s:tskelSetFiletype = 0
        set lazyredraw
        set nobackup
        set patchmode=
        set verbose&
        try
            let menu = s:MakeMenuEntry(keys(g:tskelBits_{a:type}), sub)
            exec 'redir! > '. menu_file
            if exists('*TSkelMenuCacheEditHook')
                silent! call TSkelMenuCacheEditHook()
            endif
            silent! echo join(menu, "\n")
            if exists('*TSkelMenuCachePostWriteHook')
                silent! call TSkelMenuCachePostWriteHook()
            endif
            redir END
        catch
            echohl Error
            echom v:errmsg
            echohl NONE
        finally
            let &verbose    = verbose
            let &lazyredraw = lazyredraw
            let &backup     = backup
            let &patchmode  = patchmode
            let s:tskelSetFiletype = 1
            let g:tskelMenuPrefix = tskelMenuPrefix
        endtry
    endif
endf

function! s:MakeMenuEntry(items, ...)
    let sub = a:0 >= 1 ? a:1 : ''
    " TLogVAR a:items
    " TAssert IsList(a:items)
    if sub != ''
        let g:tskelMenuPrefix = g:tskelMenuPrefix .'.'. sub
        let subpriority = 10
    else
        let subpriority = 20
    endif
    let menu = []
    call filter(copy(a:items), 's:NewBufferMenuItem(menu, v:val, subpriority)')
    " TLogVAR menu
    return menu
endf

function! s:GetCacheFilename(type, what) "{{{3
    " TLogVAR a:type
    if a:type == ''
        return ''
    endif
    let d = g:tskelBitsDir . a:type .'/'
    " TLogVAR d
    if !isdirectory(d)
        return ''
    endif
    let md = g:tskelDir . a:what .'/'
    call tlib#EnsureDirectoryExists(md)
    return md . a:type
endf

function! s:GetMenuCacheFilename(filetype) "{{{3
    return s:GetCacheFilename(a:filetype, 'cache_menu')
endf

function! s:GetFiletypeBitsCacheFilename(filetype) "{{{3
    return s:GetCacheFilename(a:filetype, 'cache_bits')
endf

function! s:ResetBufferCacheForFiletype(filetype) "{{{3
    let dir   = s:GetCacheFilename(a:filetype, 'cache_bbits')
    if !empty(dir)
        let files = split(globpath(dir, '**'), '\n')
        for fname in files
            if !isdirectory(fname)
                " TLogVAR fname
                call delete(fname)
            endif
        endfor
    endif
endf

function! s:GetBufferCacheFilename(filetype, ...) "{{{3
    if g:tskelUseBufferCache
        let create_dir = a:0 >= 1 ? a:1 : 0
        let dir = s:GetCacheFilename(a:filetype, 'cache_bbits')
        if !empty(dir)
            let dir = tlib#FileJoin([
                        \ dir,
                        \ substitute(expand('%:p:h'), '[:&<>]\|//\+\|\\\\\+', '_', 'g')
                        \ ])
            " TLogVAR dir
            if create_dir
                call tlib#EnsureDirectoryExists(dir)
            endif
            " let fname = expand('%:t') .'.'. a:filetype
            let fname = expand('%:t')
            return tlib#FileJoin([dir, fname])
        endif
    endif
    return ''
endf

function! s:PrepareMenuEntry(name, subpriority, mode) "{{{3
    " TLogVAR a:name
    if a:name =~ '\S'
        " TLogVAR a:mode
        let bit   = get(b:tskelBitDefs, a:name, [])
        " TLogVAR bit
        let mname = empty(bit) ? a:name : get(bit, 'menu', a:name)
        " let mname = escape(mname, ' 	\')
        let mname = escape(mname, ' 	')
        " TLogVAR mname
        let spri  = stridx(mname, '.') >= 0 ? a:subpriority - 1 : a:subpriority
        " TLogVAR spri
        let pri   = g:tskelMenuPriority .'.'. spri
        " TLogVAR pri
        if a:mode == 'i'
            return "imenu". pri .' '. g:tskelMenuPrefix .'.'. mname .
                        \ ' <c-\><c-o>:call TSkeletonExpandBitUnderCursor("i", '. string(a:name) .')<cr>'
        else
            return  'menu '. pri .' '. g:tskelMenuPrefix .'.'. mname .
                        \ ' :call TSkeletonExpandBitUnderCursor("n", '. string(a:name) .')<cr>'
        endif
    else
        return ''
    endif
endf

function! s:InitBufferMenu()
    if !exists('b:tskelBufferMenu')
        let b:tskelBufferMenu = []
    endif
endf

function! s:BuildBufferMenu(prepareBits) "{{{3
    if !s:tskelProcessing && &filetype != '' && g:tskelMenuCache != '' && g:tskelMenuPrefix != ''
        if a:prepareBits
            call s:PrepareBits()
        endif
        if s:tskelBuiltMenu == 1
            try
                silent exec 'aunmenu '. g:tskelMenuPrefix
            finally
            endtry
        endif
        let pri = g:tskelMenuPriority .'.'. 5
        exec 'amenu '. pri .' '. g:tskelMenuPrefix .'.Reset :TSkeletonBitReset<cr>'
        exec 'amenu '. pri .' '. g:tskelMenuPrefix .'.-tskel1- :'
        let bg = s:GetBitGroup(&filetype, 1)
        call map(bg, 's:GetMenuCache(v:val)')
        if exists('b:tskelBufferMenu')
            for m in b:tskelBufferMenu
                exec m
            endfor
        endif
        let s:tskelBuiltMenu = 1
    endif
endf

function! s:GetMenuCache(type) "{{{3
    let pg = s:GetMenuCacheFilename(a:type)
    if filereadable(pg)
        exec 'source '. pg
    endif
endf

" s:PrepareBits(?filetype=&ft, ?reset=0)
function! s:PrepareBits(...) "{{{3
    let filetype = a:0 >= 1 && a:1 != '' ? a:1 : &filetype
    if filetype == ''
        let b:tskelFiletype = ''
        return
    endif
    let explicit_reset = a:0 >= 2 ? a:2 : 0
    if explicit_reset
        for idx in range(1, s:tskelScratchMax)
            exec 'bdelete! '. bufnr(s:tskelScratchNr{idx})
        endfor
        if g:tskelUseBufferCache
            call s:ResetBufferCacheForFiletype(filetype)
        endif
    endif
    " TLogVAR explicit_reset
    let init_buffer    = !exists('b:tskelFiletype') || b:tskelFiletype != filetype
    " TLogVAR init_buffer
    if !explicit_reset && !init_buffer
        return
    endif
    " TLogVAR filetype
    let ft_group = s:GetBitGroup(filetype)
    " TAssert IsList(ft_group)
    " TLogVAR ft_group
    let to_be_initialized = s:FiletypesToBeInitialized(ft_group, explicit_reset)
    " TAssert IsList(to_be_initialized)
    " TLogVAR to_be_initialized
    if init_buffer || !empty(to_be_initialized)
        if !explicit_reset && g:tskelUseBufferCache && s:HasCachedBufferBits(filetype)
            call s:PrepareBufferFromCache(filetype)
        else
            let b:tskelBitDefs  = {}
            let b:tskelBitNames = []
            for ft in ft_group
                let reset = s:ToBeInitialized(to_be_initialized, ft)
                let resetcache = explicit_reset || !s:FiletypeInCache(ft)
                if reset
                    if resetcache
                        call s:PrepareFiletype(ft, reset)
                    else
                        call s:PrepareFiletypeFromCache(ft)
                    endif
                endif
                call s:ExtendBitDefs(b:tskelBitDefs, ft)
                call s:PrepareFiletypeMap(ft, reset)
                if reset
                    if resetcache
                        call s:CacheFiletypeBits(ft)
                    endif
                    call s:PrepareFiletypeMenu(ft)
                endif
            endfor
            " if s:PrepareBuffer(filetype) && empty(&buftype)
            if s:PrepareBuffer(filetype) && g:tskelUseBufferCache
                call s:CacheBufferBits(filetype)
            endif
        endif
        " TAssert IsList(b:tskelBitNames)
        " TAssert IsDictionary(b:tskelBitDefs)
        let b:tskelBitNames = keys(b:tskelBitDefs)
        let b:tskelBitNames = tlib#Compact(tlib#Flatten(b:tskelBitNames))
        if g:tskelPopupNumbered
            call map(b:tskelBitNames, "substitute(v:val, '&', '', 'g')")
        endif
        call s:BuildBufferMenu(0)
        let b:tskelFiletype = filetype
    endif
endf

function! s:HasCachedBufferBits(filetype) "{{{3
    let cname = s:GetBufferCacheFilename(a:filetype)
    return filereadable(cname)
endf

function! s:CacheBufferBits(filetype) "{{{3
    let cname = s:GetBufferCacheFilename(a:filetype, 1)
    if !empty(cname)
        call writefile([string(b:tskelBitDefs)], cname, 'b')
    endif
endf

function! s:PrepareBufferFromCache(filetype) "{{{3
    let cname = s:GetBufferCacheFilename(a:filetype)
    let b:tskelBitDefs = eval(join(readfile(cname, 'b'), "\n"))
endf

function! s:FiletypeInCache(filetype) "{{{3
    let cache = s:GetFiletypeBitsCacheFilename(a:filetype)
    return filereadable(cache)
endf

function! s:PrepareFiletypeFromCache(filetype) "{{{3
    let cache = s:GetFiletypeBitsCacheFilename(a:filetype)
    if !empty(cache)
        let g:tskelBits_{a:filetype} = eval(join(readfile(cache, 'b'), "\n"))
    endif
endf

function! s:CacheFiletypeBits(filetype) "{{{3
    let cache = s:GetFiletypeBitsCacheFilename(a:filetype)
    if !empty(cache)
        call writefile([string(g:tskelBits_{a:filetype})], cache, 'b')
    endif
endf

function! s:PrepareFiletype(filetype, reset)
    " TLogVAR a:filetype
    " TLogVAR a:reset
    let g:tskelBits_{a:filetype} = {}
    let fns = s:CollectFunctions('^TSkelFiletypeBits_%s\+$')
                \ + s:CollectFunctions('^TSkelFiletypeBits_%s\+_'. a:filetype .'$')
    for fn in fns
        " TLogDBG 'PrepareFiletype '.fn
        call {fn}(g:tskelBits_{a:filetype}, a:filetype)
    endfor
    " TLogDBG 'bits for '. a:filetype .'='. string(keys(g:tskelBits_{a:filetype}))
endf

function! s:PrepareBuffer(filetype)
    " TLogDBG bufname('%')
    call s:InitBufferMenu()
    let fns = s:CollectFunctions('^TSkelBufferBits_%s\+$')
                \ + s:CollectFunctions('^TSkelBufferBits_%s\+_'. a:filetype .'$')
    for fn in fns
        " TLogDBG 'PrepareBuffer '.fn
        call {fn}(b:tskelBitDefs, a:filetype)
    endfor
    " TLogDBG string(keys(b:tskelBitDefs))
    return !empty(fns)
endf

function! TSkelFiletypeBits_skeleton(dict, type) "{{{3
    " TAssert IsDictionary(a:dict)
    " TAssert IsString(a:type)
    call s:FetchMiniBits(a:dict, g:tskelBitsDir . a:type .'.txt', 0)
    let bf = s:GlobBits(g:tskelBitsDir . a:type .'/', 2)
    for f in bf
        if !isdirectory(f) && filereadable(f)
            let bb = tlib#DecodeURL(fnamemodify(f, ":t"))
            let bn = s:PurifyBit(bb)
            let bt = join(readfile(f), "\n")
            let [bt, meta] = s:ExtractMeta(bt)
            let a:dict[bn] = {'text': bt, 'menu': bb, 'meta': meta}
        endif
    endfor
endf

function! s:ReplacePrototypeArgs(text, rest)
    let args = split(a:text, ',\s\+')
    if empty(args)
        return '()'
    else
        let max = len(args) - 1
        let rv  = map(range(0, max), '!empty(a:rest) && args[v:val] =~ a:rest ? "<++>" : (v:val == 0 ? "" : ", ") . printf("<+%s+>", toupper(args[v:val]))')
        return printf('(<+CURSOR+>%s)<++>', join(rv, ''))
    endif
endf

if !exists('*TSkelFiletypeBits_functions_vim')
    function! TSkelFiletypeBits_functions_vim(dict, filetype) "{{{3
        " TAssert IsDictionary(a:dict)
        " TAssert IsString(a:filetype)
        redir => fns
        silent fun
        redir END
        let fnl = split(fns, '\n')
        call map(fnl, 'matchstr(v:val, ''^\S\+\s\+\zs.\+$'')')
        call filter(fnl, 'v:val[0:4] != ''<SNR>''')
        for f in sort(fnl)
            let fn = matchstr(f, '^.\{-}\ze(')
            let fr = substitute(f, '(\(.\{-}\))$', '\=s:ReplacePrototypeArgs(submatch(1), ''\V...'')', "g")
            " TLogDBG fn ." -> ". fr
            let a:dict[fn] = {'text': fr, 'menu': 'Function.'. fn}
        endfor
    endf
endif

function! s:SortByFilename(tag1, tag2)
    let f1 = a:tag1['filename']
    let f2 = a:tag2['filename']
    return f1 == f2 ? 0 : f1 > f2 ? 1 : -1
endf

let s:tag_defs = {}

function! s:SortBySource(a, b)
    let ta = s:sort_tag_defs[a:a]
    let tb = s:sort_tag_defs[a:b]
    let fa = ta.source
    let fb = tb.source
    if fa == fb
        return ta.menu == tb.menu ? 0 : ta.menu > tb.menu ? 1 : -1
    else
        return fa > fb ? 1 : -1
    endif
endf

function! TSkelBufferBits_tags(dict, filetype) "{{{3
    " TAssert IsDictionary(a:dict)
    " TAssert IsString(a:filetype)
    if exists('*TSkelProcessTag_'. a:filetype)
        let td_id = join(map(tagfiles(), 'fnamemodify(v:val, ":p")'), '\n')
        if !empty(td_id)
            let tag_defs = get(s:tag_defs, td_id, {})
            if empty(tag_defs)
                echom 'tSkeleton: Building tags menu for '. expand('%')
                let tags = taglist('.')
                call sort(tags, 's:SortByFilename')
                call filter(tags, 'TSkelProcessTag_{a:filetype}(tag_defs, v:val)')
                let s:tag_defs[td_id] = tag_defs
                echo
                redraw
            endif
            call extend(a:dict, tag_defs, 'keep')
            let menu_prefix = tlib#GetValue('tskelMenuPrefix_tags', 'bg')
            if !empty(menu_prefix)
                let s:sort_tag_defs = tag_defs
                let tagnames = sort(keys(tag_defs), 's:SortBySource')
                call filter(tagnames, 's:NewBufferMenuItem(b:tskelBufferMenu, v:val, 10)')
            endif
        endif
    endif
endf

function! TSkelProcessTag_functions_with_parentheses(dict, tag, restargs)
    if a:tag['kind'] == 'f'
        let source0 = fnamemodify(a:tag['filename'], ':p')
        let source  = source0
        let xname   = a:tag['name']
        let args    = matchstr(a:tag['cmd'], '(\zs.\{-}\ze)')
        " let bname0  = xname .'/'. len(split(args, ',')) .'@'
        let args0   = matchstr(a:tag['cmd'], '(.\{-})')
        let bname0  = xname . args0 .'@'
        let bname   = bname0 . fnamemodify(source, ':t')
        if has_key(a:dict, bname)
            if fnamemodify(get(a:dict[bname], 'source', ''), ':p') == source0
                return ''
            else
                let bname = bname0 . source
            endif
        endif
        let xname .= s:ReplacePrototypeArgs(args, a:restargs)
        let a:dict[bname] = {'text': xname, 'source': source}
        let menu_prefix = tlib#GetValue('tskelMenuPrefix_tags', 'bg')
        if !empty(menu_prefix)
            " let smenu  = join(map(split(source, '[\/]'), 'escape(v:val, ". ")'), '.')
            " let mname  = 'Tag.'. smenu .'.'. escape(bname, '. ')
            let smenu  = join(map(split(source, '[\/]'), 'escape(v:val, ".")'), '.')
            let mname  = menu_prefix . smenu .'.'. escape(bname, '.')
            " TLogDBG xname .' -- '. xname
            let a:dict[bname]['menu'] = mname
        endif
        return bname
    elseif a:tag['kind'] == 'c'
    elseif a:tag['kind'] == 'm'
    endif
    return ''
endf

function! TSkelProcessTag_vim(dict, tag)
    return TSkelProcessTag_functions_with_parentheses(a:dict, a:tag, '\V...')
endf

function! TSkelProcessTag_ruby(dict, tag)
    return TSkelProcessTag_functions_with_parentheses(a:dict, a:tag, '\*\a\+\s*$')
endf

function! TSkelProcessTag_c(dict, tag)
    return TSkelProcessTag_functions_with_parentheses(a:dict, a:tag, '')
endf

function! TSkelBufferBits_mini(dict, filetype)
    call s:FetchMiniBits(a:dict, expand('%:p:h') .'/.tskelmini', 1)
endf

function! s:CollectFunctions(pattern)
    let types   = '\('. join(tlib#GetValue('tskelTypes', 'bg'), '\|') .'\)'
    let pattern = printf(a:pattern, types)
    redir => fns
    silent exec 'function /'. pattern
    redir END
    let rv = map(split(fns, '\n'), 'matchstr(v:val, ''^\S\+\s\+\zs.\{-}\ze('')')
    call filter(rv, '!empty(v:val)')
    return rv
endf

function! s:PrepareConditionEntry(pattern, eligible) "{{{3
    let pattern  = escape(substitute(a:pattern, '%', '%%', 'g'), '"')
    let eligible = escape(a:eligible, '"')
    return 'if search("'. pattern .'%s", "W") | return "'. eligible .'" | endif | '
endf

function! s:ReadFile(filename) "{{{3
    " TAssert IsString(a:filename)
    if filereadable(a:filename)
        return join(readfile(a:filename), "\n")
    endif
    return ''
endf

function! s:Read0(filename) "{{{3
    call append(0, readfile(a:filename))
    norm! Gdd
endf

function! s:PrepareFiletypeMap(type, anyway) "{{{3
    if !exists('g:tskelBitMap_'. a:type) || a:anyway
        let md = g:tskelDir .'map/'
        " call tlib#EnsureDirectoryExists(md)
        let fn = md . a:type
        let c  = s:ReadFile(fn)
        if c =~ '\S'
            let g:tskelBitMap_{a:type} = {}
            for line in split(c, "\n")
                let pattern = matchstr(line, '^.\{-}\ze\t')
                if !empty(pattern)
                    let bits    = matchstr(line, '\t\zs.*$')
                    let g:tskelBitMap_{a:type}[pattern] = split(bits, '\s\+')
                endif
            endfor
        endif
    endif
endf

function! s:PrepareFiletypeMenu(type) "{{{3
    " TLogVAR a:type
    if a:type == 'general'
        call s:PrepareMenu('general', 'General')
    else
        call s:PrepareMenu(a:type)
    endif
endf

function! s:ExtendBitDefs(dict, type) "{{{3
    " TAssert IsDictionary(a:dict)
    if s:DidSetup(a:type)
        let bm = g:tskelBits_{a:type}
        " TAssert IsDictionary(bm)
        if !empty(bm)
            call extend(a:dict, bm)
        endif
    endif
endf

command! -bar -nargs=? TSkeletonBitReset call s:PrepareBits(<q-args>, 1)

function! TSkeletonSelectBit(ArgLead, CmdLine, CursorPos) "{{{3
    call s:PrepareBits()
    return join(s:EligibleBits(&filetype), "\n")
endf

function! s:SetLine(mode) "{{{3
    let s:tskelLine = line('.')
    let s:tskelCol  = col('.')
endf

function! s:UnsetLine() "{{{3
    let s:tskelLine = 0
    let s:tskelCol  = 0
endf

" TBD: the format should be changed to use vim lists right away
function! s:GetEligibleBits(type) "{{{3
    let pos = '\\%'. s:tskelLine .'l\\%'. s:tskelCol .'c'
    for pattern in keys(g:tskelBitMap_{a:type})
        " <+TBD70+> Use printf()
        if search(pattern.pos, 'W')
            return g:tskelBitMap_{a:type}[pattern]
        endif
    endfor
    return []
endf

function! s:EligibleBits(type) "{{{3
    if s:tskelLine && exists('g:tskelBitMap_'. a:type)
        norm! {
        let eligible = s:GetEligibleBits(a:type)
        " TAssert IsList(eligible)
        call cursor(s:tskelLine, s:tskelCol)
        if !empty(eligible)
            " TLogDBG a:type.': '. string(eligible)
            return eligible
        endif
    endif
    if exists('b:tskelBitNames')
        " TAssert IsList(b:tskelBitNames)
        " TLogDBG 'b:tskelBitNames='. string(b:tskelBitNames)
        return b:tskelBitNames
    else
        return []
    endif
endf

function! s:EditScratchBuffer(filetype, ...) "{{{3
    let idx = a:0 >= 1 ? a:1 : s:tskelScratchIdx
    if exists("s:tskelScratchNr". idx) && s:tskelScratchNr{idx} >= 0
        let tsbnr = bufnr(s:tskelScratchNr{idx})
    else
        let tsbnr = -1
    endif
    if tsbnr >= 0
        silent exec "sbuffer ". tsbnr
    else
        silent split
        silent exec "edit [TSkeletonScratch_". idx ."]"
        let s:tskelScratchNr{idx} = bufnr("%")
        " let b:tskelScratchBuffer = 1
    endif
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nobuflisted
    setlocal foldlevel=99
    silent norm! ggdG
    " TLogVAR a:filetype
    if !exists('b:tskelFiletype') || b:tskelFiletype != a:filetype
        if exists('b:tskelBitDefs')
            unlet b:tskelBitDefs
        endif
        call s:PrepareBits(a:filetype)
    endif
    if exists('*TSkelNewScratchHook_'. a:filetype)
        call TSkelNewScratchHook_{a:filetype}()
    endif
endf

function! TSkelNewScratchHook_viki()
    let b:vikiMarkInexistent = 0
endf

function! s:IsScratchBuffer()
    " return exists('b:tskelScratchBuffer') || bufname('%') =~ '\V[TSkeletonScratch_\d\+]'
    return bufname('%') =~ '\V[TSkeletonScratch_\d\+]'
endf

" s:RetrieveBit(agent, bit, ?indent, ?filetype) => setCursor?; @t=expanded template bit
function! s:RetrieveBit(agent, bit, ...) "{{{3
    if s:tskelScratchIdx >= g:tskelMaxRecDepth
        return 0
    endif
    " TLogVAR a:agent
    " TLogVAR a:bit
    let indent = a:0 >= 1 ? a:1 : ''
    let ft     = a:0 >= 2 ? a:2 : &filetype
    let @t     = ''
    if s:tskelScratchIdx == 0
        let s:tskelDestBufNr = bufnr("%")
    endif
    let s:tskelScratchIdx = s:tskelScratchIdx + 1
    if s:tskelScratchIdx > s:tskelScratchMax
        let s:tskelScratchMax = s:tskelScratchIdx
        let s:tskelScratchNr{s:tskelScratchIdx} = -1
    endif
    let setCursor  = 0
    let processing = s:SetProcessing()
    try
        call s:EditScratchBuffer(ft)
        if ft != ""
            call s:PrepareBits(ft)
        endif
        call s:RetrieveAgent_{a:agent}(a:bit)
        " TLogDBG string(getline(1, '$'))
        call s:IndentLines(1, line("$"), indent)
        " TLogDBG string(getline(1, '$'))
        silent norm! gg
        call TSkeletonFillIn(a:bit, ft)
        let setCursor = s:SetCursor('%', '', '', 1)
        " TLogVAR setCursor
        silent norm! ggvGk$"ty
    finally
        call s:SetProcessing(processing)
        wincmd c
        let s:tskelScratchIdx = s:tskelScratchIdx - 1
        if s:tskelScratchIdx == 0
            silent exec 'buffer '. s:tskelDestBufNr
            let s:tskelDestBufNr = -1
        else
            silent exec 'buffer '. s:tskelScratchNr{s:tskelScratchIdx}
        endif
    endtry
    return setCursor
endf

function! s:SetProcessing(...) "{{{3
    if a:0 >= 1
        let s:tskelProcessing = a:1
        return a:1
    else
        let rv = s:tskelProcessing
        let s:tskelProcessing = 1
        return rv
    endif
endf

" function! s:RetrieveAgent_read(bit) "{{{3
"     let cpo = &cpo
"     try
"       set cpoptions-=a
"       silent exec "0read ". escape(a:bit, '\#%')
"       norm! Gdd
"     finally
"       let &cpo = cpo
"     endtry
" endf

function! s:RetrieveAgent_text(bit) "{{{3
    " TLogVAR a:bit
    if s:IsDefined(a:bit)
        let text = b:tskelBitDefs[a:bit]['text']
        call append(0, split(text, '\n'))
    endif
    " norm! Gdd
    " TLogDBG string(getline(1, '$'))
endf

function! s:InsertBit(agent, bit, mode) "{{{3
    " TLogVAR a:agent
    " TLogVAR a:bit
    let t = @t
    try
        let c  = col(".")
        let e  = col("$")
        let l  = line(".")
        let li = getline(l)
        " Adjust for vim idiosyncrasy
        if c == e - 1 && li[c - 1] == " "
            let e = e - 1
        endif
        let i = s:GetIndent(li)
        let setCursor = s:RetrieveBit(a:agent, a:bit, i)
        " TLogVAR setCursor
        " exec 'silent norm! '. c .'|'
        call cursor(0, c)
        call s:InsertTReg(a:mode)
        if setCursor
            let ll = l + setCursor - 1
            call s:SetCursor(l, ll, a:mode)
        elseif s:IsInsertMode(a:mode) && s:IsEOL(a:mode)
            call cursor(0, col('.') + 1)
        endif
    finally
        let @t = t
    endtry
endf

function! s:InsertTReg(mode) "{{{3
    if s:IsEOL(a:mode)
    " if s:IsInsertMode(a:mode) && !s:IsEOL(a:mode)
        silent norm! "tgp
    else
        silent norm! "tgP
    end
endf

function! s:GetIndent(line) "{{{3
    return matchstr(a:line, '^\(\s*\)')
endf

function! s:IndentLines(from, to, indent) "{{{3
    " silent exec a:from.",".a:to.'s/\(^\|\n\)/\1'. escape(a:indent, '/\') .'/g'
    " TLogVAR a:indent
    silent exec a:from.",".a:to.'s/^/'. escape(a:indent, '/\') .'/g'
endf

function! s:CharRx(char) "{{{3
    let rv = '&\?'
    if a:char == '\\'
        return rv .'\('. tlib#EncodeChar('\') .'\|\\\)'
    elseif a:char =~ '[/*#<>|:"?{}~]'
        return rv .'\('. tlib#EncodeChar(a:char) .'\|'. a:char .'\)'
    else
        return rv . a:char
    endif
endf

function! s:BitRx(bit, escapebs) "{{{3
    let rv = substitute(escape(a:bit, '\'), '\(\\\\\|.\)', '\=s:CharRx(submatch(1))', 'g')
    return rv
endf

function! s:FindValue(list, function, ...)
    " TLogDBG "function=". a:function
    " TLogDBG "list=". string(a:list)
    for elt in a:list
        try
            let fn  = printf(a:function, escape(string(elt), '\'))
            " TLogDBG "fn=". fn
            let val = eval(fn)
            " TLogDBG "val=". val
            if !empty(val)
                " TLogDBG "rv=". val
                return val
            endif
        catch
        endtry
        unlet elt
    endfor
    return a:0 >= 1 ? a:1 : 0
endf

function! s:IsDefined(bit) "{{{3
    return !empty(a:bit) && has_key(b:tskelBitDefs, a:bit)
endf

function! s:SelectAndInsert(bit, mode) "{{{3
    " TLogVAR a:bit
    if s:IsDefined(a:bit)
        call s:InsertBit('text', a:bit, a:mode)
        return 1
    endif
    return 0
endf

if loaded_genutils >= 200 "{{{2
    function! s:SaveWindowSettings() "{{{3
        call genutils#SaveWindowSettings2('tSkeleton', 1)
    endf
    
    function! s:RestoreWindowSettings() "{{{3
        call genutils#RestoreWindowSettings2('tSkeleton')
    endf
else
    function! s:SaveWindowSettings() "{{{3
        call SaveWindowSettings2('tSkeleton', 1)
    endf
    
    function! s:RestoreWindowSettings() "{{{3
        call RestoreWindowSettings2('tSkeleton')
    endf
endif

" TSkeletonBit(bit, ?mode='n')
function! TSkeletonBit(bit, ...) "{{{3
    " TLogVAR a:bit
    " TAssert IsNotEmpty(a:bit)
    call s:PrepareBits()
    let mode = a:0 >= 1 ? a:1 : 'n'
    let processing = s:SetProcessing()
    call s:SaveWindowSettings()
    try
        if s:SelectAndInsert(a:bit, mode)
            " call TLogDBG('s:SelectAndInsert ok')
            return 1
        else
            " call TLogDBG("TSkeletonBit: Unknown bit '". a:bit ."'")
            if s:IsPopup(mode)
                let t = @t
                try
                    let @t = a:bit
                    call s:InsertTReg(mode)
                    return 1
                finally
                    let @t = t
                endtry
            endif
            return 0
        endif
        " catch
        "     echom "An error occurred in TSkeletonBit() ... ignored"
    finally
        call s:RestoreWindowSettings()
        call s:SetProcessing(processing)
    endtry
endf

command! -nargs=1 -complete=custom,TSkeletonSelectBit TSkeletonBit
            \ call TSkeletonBit(<q-args>)

if !hasmapto("TSkeletonBit") "{{{2
    " noremap <unique> <Leader>tt ""diw:TSkeletonBit <c-r>"
    exec "noremap <unique> ". g:tskelMapLeader ."t :TSkeletonBit "
endif

function! s:IsInsertMode(mode) "{{{3
    return a:mode =~? 'i'
endf

function! s:IsEOL(mode) "{{{3
    return a:mode =~? '1'
endf

function! s:IsPopup(mode) "{{{3
    return a:mode =~? 'p'
endf

function! s:BitMenu(bit, mode, ft) "{{{3
    " TLogVAR a:bit
    if has("menu") && g:tskelQueryType == 'popup'
        return s:BitMenu_menu(a:bit, a:mode, a:ft)
    else
        return s:BitMenu_query(a:bit, a:mode, a:ft)
    endif
endf

function! s:BitMenuEligible(agent, bit, mode, ft) "{{{3
    call s:SetLine(a:mode)
    let t = copy(s:EligibleBits(a:ft))
    " TAssert IsList(t)
    let s:tskelMenuEligibleIdx = 0
    let s:tskelMenuEligibleRx  = '^'. s:BitRx(a:bit, 0)
    call filter(t, 'v:val =~ ''\S'' && v:val =~ s:tskelMenuEligibleRx')
    if g:tskelPopupNumbered
        call sort(t)
    endif
    let e = map(t, 's:BitMenuEligible_'. a:agent .'_cb(v:val, '. string(a:mode) .')')
    " TAssert IsList(e)
    " TLogDBG 'e='. string(e)
    return tlib#Compact(e)
endf

function! s:BitMenuEligible_complete_cb(bit, mode) "{{{3
   return s:BitMenuEligible_query_cb(a:bit, a:mode)
endf

function! s:BitMenu_query(bit, mode, ft) "{{{3
    let s:tskelQueryAcc = s:BitMenuEligible('query', a:bit, a:mode, a:ft)
    if len(s:tskelQueryAcc) <= 1
        " let rv = get(s:tskelQueryAcc, 0, a:bit)
        let rv = get(s:tskelQueryAcc, 0, '')
    else
        let qu = "s:tskelQueryAcc|Select bit:"
        let rv = s:Query(qu)
    endif
    " TLogVAR rv
    if rv != ''
        call TSkeletonBit(rv, a:mode .'p')
        return 1
    endif
    return 0
endf

function! s:BitMenuEligible_query_cb(bit, mode) "{{{3
    return tlib#DecodeURL(a:bit)
endf

function! s:BitMenu_menu(bit, mode, ft) "{{{3
    try
        silent! aunmenu ]TSkeleton
    catch
    endtry
    " TLogDBG 'bit='. a:bit
    let rv = s:BitMenuEligible('menu', a:bit, a:mode, a:ft)
    " TAssert IsList(rv)
    let j = len(rv)
    if j == 1
        exec s:tskelMenuEligibleEntry
        return 1
    elseif j > 0
        popup ]TSkeleton
        return 1
    endif
    return 0
endf

function! s:BitMenuEligible_menu_cb(bit, mode) "{{{3
    " TAssert IsString(a:bit)
    " TLogDBG 'bit='. a:bit
    " call TLogDBG('tskelMenuEligibleRx=~'. a:bit =~ s:tskelMenuEligibleRx)
    let s:tskelMenuEligibleIdx = s:tskelMenuEligibleIdx + 1
    if g:tskelPopupNumbered
        if stridx(a:bit, '&') == -1
            let x = substitute(s:tskelMenuEligibleIdx, '\(.\)$', '\&\1', '')
        else
            let x = s:tskelMenuEligibleIdx
        end
        let x .= '\ '
        let m = a:bit
    else
        let x = ''
        let m = escape(b:tskelBitDefs[a:bit]['menu'], '"\ 	')
    endif
    let s:tskelMenuEligibleEntry = 'call TSkeletonBit('. string(a:bit) .', "'. a:mode .'p")'
    " call TLogDBG(s:tskelMenuEligibleEntry)
    exec 'amenu ]TSkeleton.'. x . m .' :'. s:tskelMenuEligibleEntry .'<cr>'
    return 1
endf

" TSkeletonExpandBitUnderCursor(mode, ?bit, ?default)
function! TSkeletonExpandBitUnderCursor(mode, ...) "{{{3
    let bit     = a:0 >= 1 && a:1 != '' ? a:1 : ''
    let default = a:0 >= 2 && a:2 != '' ? a:2 : ''
    " TLogVAR bit
    call s:PrepareBits()
    let t = @t
    let lazyredraw = &lazyredraw
    set lazyredraw
    try
        let @t    = ''
        let ft    = &filetype
        let imode = s:IsInsertMode(a:mode)
        let l     = getline('.')
        let line  = line('.')
        let col0  = col('.')
        " TLogVAR col0
        let col   = col0
        if imode
            if col >= col('$') && &virtualedit =~ '^\(block\|onemore\)\?$'
                let eol_adjustment = 1
            else
                let col -= 1
                let eol_adjustment = 0
            endif
        else
            let eol_adjustment = (col + 1 >= col('$'))
        endif
        let mode = a:mode . eol_adjustment
        " TLogVAR mode
        if bit != ''
            let @t = bit
        else
            let c = l[col - 1]
            let pos = '\%#'
            if c =~ '\s'
                let @t = ''
                " TLogDBG " 0 @t=". @t
                if !imode && !eol_adjustment
                    norm! l
                endif
            elseif exists('g:tskelKeyword_'. ft) && search(g:tskelKeyword_{ft} . pos) != -1
                if imode && eol_adjustment
                    let d = col - col('.')
                else
                    let d = col - col('.') + 1
                endif
                exec 'silent norm! "td'. d .'l'
                " TLogDBG " 1 @t='". @t ."'"
            elseif imode && !eol_adjustment
                silent norm! h"tdiw
                " TLogDBG " 2 @t='". @t ."'"
            else
               silent norm! "tdiw
                " TLogDBG " 3 @t='". @t ."'"
            endif
        endif
        let bit = @t
        if bit =~ '^\s\+$'
            let bit = ''
        endif
        " TLogDBG " 4 bit='". bit ."'"
        if bit != '' && TSkeletonBit(bit, mode) == 1
            " call TLogDBG("TSkeletonBit succeeded!")
            return 1
        elseif (bit	!= '' || default == '') && s:BitMenu(bit, mode, ft)
            " call TLogDBG("s:BitMenu succeeded!")
            return s:InsertDefault(mode, bit, default)
        endif
        " TLogVAR bit
        " TLogVAR default
        if s:InsertDefault(mode, bit, default)
            " TLogDBG 's:InsertDefault succeeded!'
            return 1
        else
            " silent norm! u
            let @t = bit.default
            call s:InsertTReg(mode)
            " call cursor(line, col0, imode)
            call cursor(line, col0)
            echom "TSkeletonBit: Unknown bit '". bit ."'"
            return 0
        endif
    finally
        let @t = t
        call s:UnsetLine()
        let lazyredraw  = &lazyredraw
    endtry
endf

function! s:InsertDefault(mode, bit, default) "{{{3
    if a:default != ''
        let @t = a:bit . a:default
        call s:InsertTReg(a:mode)
        return 1
    else
        return 0
    endif
endf

function! TSkeleton_complete(findstart, base)
    if a:findstart
        let pattern = exists('g:tskelKeyword_'. &filetype) ? g:tskelKeyword_{&filetype} : '\w\+'
        let line    = getline('.')[0:(col('.') - 1)]
        let start   = match(line, pattern.'$')
        return start == -1 ? col('.') - 1 : start
    else
        let t = s:BitMenuEligible('complete', a:base, 'i', &filetype)
        if s:DidSetup(&filetype)
            for [bit, def] in items(g:tskelBits_{&filetype})
                " TAssert IsDictionary(def)
                call add(t, {'word': def['text'], 'abbr': bit})
            endfor
        endif
        " TAssert IsList(t)
        return t
    endif
endf
if g:tskelMapComplete
    set completefunc=TSkeleton_complete
endif

if !hasmapto("TSkeletonExpandBitUnderCursor") "{{{2
    exec "nnoremap <unique> ". g:tskelMapLeader ."# :call TSkeletonExpandBitUnderCursor('n')<cr>"
    if g:tskelAddMapInsert
        exec "inoremap <unique> ". g:tskelMapInsert ." <c-\\><c-o>:call TSkeletonExpandBitUnderCursor('i','', ". string(g:tskelMapInsert) .")<cr>"
    else
        exec "inoremap <unique> ". g:tskelMapInsert ." <c-\\><c-o>:call TSkeletonExpandBitUnderCursor('i')<cr>"
    endif
endif

function! s:TagSelect(chars, mode) "{{{3
    " TLogDBG 'chars.='. a:chars .' mode='. a:mode
    let chars = &selection == 'exclusive' ? a:chars : a:chars - 1
    if a:mode == 'd'
        let cp = (col('.') + chars)
        " TLogDBG 'col.='. col('.') .' colp='. cp .' col$='. col('$')
        if cp == col('$')
            if &ve =~ 'all'
                let correction = '$l'
            else
                let correction = '$'
            endif
        else
            let correction = ''
        endif
        exec 'norm! d'. chars .'l'.correction
    else
        exec 'norm! v'. chars .'l'
        if g:tskelSelectTagMode[0] == 's'
            exec "norm! \<c-g>"
        endif
    endif
endf

function! TSkeletonGoToNextTag() "{{{3
    let rx = '\(???\|+++\|###\|<++>\|<+.\{-}+>\)'
    let x  = search(rx, 'c')
    if x > 0
        let lc = exists('b:tskelLastCol')  ? b:tskelLastCol : col('.')
        let l  = strpart(getline(x), lc - 1)
        " TLogDBG 'l='. l .' lc='. lc
        let ms = matchstr(l, rx)
        let ml = len(ms)
        " TLogDBG 'ms='. ms .' ml='. ml
        if ms == '???' || ms == '+++' || ms == '###'
            call s:TagSelect(ms, 'v')
        else
            if ml == 4
                call s:TagSelect(ml, 'd')
            else
                call s:TagSelect(ml, 'v')
            endif
        endif
    endif
endf

function! TSkeletonMapGoToNextTag() "{{{3
    nnoremap <silent> <c-j> :call TSkeletonGoToNextTag()<cr>
    vnoremap <silent> <c-j> <c-\><c-n>:call TSkeletonGoToNextTag()<cr>
    inoremap <silent> <c-j> <c-\><c-o>:call TSkeletonGoToNextTag()<cr>
endf



function! TSkeletonLateExpand() "{{{3
    let rx = '<+.\{-}+>'
    let l  = getline('.')
    let lc = col('.') - 1
    while strpart(l, lc, 2) != '<+'
        let lc = lc - 1
        if lc <= 0 || strpart(l, lc - 1, 2) == '+>'
            throw "TSkeleton: No tag under cursor"
        endif
    endwh
    let l  = strpart(l, lc)
    let me = matchend(l, rx)
    if me < 0
        throw "TSkeleton: No tag under cursor"
    else
        let lp = substitute(strpart(l, 2, me - 4), '\W', '_', 'g')
        let v  = ''
        if exists('*TSkeletonCB_'. lp)
            let v = TSkeletonCB_{lp}()
        elseif exists('*TSkeleton_'. lp)
            let v = TSkeleton_{lp}()
        else
            throw 'TSkeleton: No callback defined for '. lp .' (TSkeletonCB_'. lp .')'
        endif
        if v != ''
            " exec 'norm! '. (lc + 1) .'|d'. me .'li'. v
            call cursor(0, lc + 1)
            exec 'norm! d'. me .'li'. v
            return
        endif
    endif
endf

if !hasmapto("TSkeletonLateExpand()") "{{{2
    exec "nnoremap <unique> ". g:tskelMapLeader ."x :call TSkeletonLateExpand()<cr>"
    exec "vnoremap <unique> ". g:tskelMapLeader ."x <esc>`<:call TSkeletonLateExpand()<cr>"
endif


" misc utilities {{{1
function! TSkeletonIncreaseRevisionNumber() "{{{3
    let rev = exists("b:revisionRx") ? b:revisionRx : g:tskelRevisionMarkerRx
    let ver = exists("b:versionRx")  ? b:versionRx  : g:tskelRevisionVerRx
    let pos = getpos('.')
    let rs  = @/
    " exec 'keepjumps %s/'.rev.'\('.ver.'\)*\zs\(-\?\d\+\)/\=(submatch(g:tskelRevisionGrpIdx) + 1)/e'
    exec '%s/'.rev.'\('.ver.'\)*\zs\(-\?\d\+\)/\=(submatch(g:tskelRevisionGrpIdx) + 1)/e'
    let @/  = rs
    call setpos('.', pos)
endfun

function! TSkeletonCleanUpBibEntry() "{{{3
    '{,'}s/^.*<+.\{-}+>.*\n//e
    if exists('*TSkeletonCleanUpBibEntry_User')
        call TSkeletonCleanUpBibEntry_User()
    endif
endf
command! TSkeletonCleanUpBibEntry call TSkeletonCleanUpBibEntry()

" TSkeletonRepeat(n, string, ?sep="\n")
function! TSkeletonRepeat(n, string, ...) "{{{3
    let sep = a:0 >= 1 ? a:1 : "\n"
    let rv  = a:string
    let n   = a:n - 1
    while n > 0
        let rv = rv . sep . a:string
        let n  = n - 1
    endwh
    return rv
endf

function! TSkeletonInsertTable(rows, cols, rowbeg, rowend, celljoin) "{{{3
    let y = a:rows
    let r = ''
    while y > 0
        let x = a:cols
        let r = r . a:rowbeg
        while x > 0
            if x == a:cols
                let r = r .'<+CELL+>'
            else
                let r = r . a:celljoin .'<+CELL+>'
            end
            let x = x - 1
        endwh
        let r = r. a:rowend
        if y > 1
            let r = r ."\n"
        endif
        let y = y - 1
    endwh
    return r
endf

function! s:DefineAutoCmd(template) "{{{3
    let sfx = fnamemodify(a:template, ':e')
    let tpl = fnamemodify(a:template, ':t')
    exec 'autocmd BufNewFile *.'. sfx .' TSkeletonSetup '. tpl
endf

augroup tSkeleton
    autocmd!
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
        let autotemplates = split(string(glob(g:tskelDir.'*#*')), '\n')
        " call map(autotemplates, "s:DefineAutoCmd(v:val)")
    endif

    autocmd BufNewFile,BufRead */skeletons/* if s:tskelSetFiletype | setf tskeleton | endif
    " autocmd BufEnter * if (g:tskelMenuCache != '' && !s:IsScratchBuffer()) | call s:BuildBufferMenu(1) | else | call s:PrepareBits('', 1) | endif
    autocmd BufEnter * if (g:tskelMenuCache != '' && !s:IsScratchBuffer()) | call s:BuildBufferMenu(1) | endif
    
    autocmd FileType bib if !hasmapto(":TSkeletonCleanUpBibEntry") | exec "noremap <buffer> ". g:tskelMapLeader ."c :TSkeletonCleanUpBibEntry<cr>" | endif
augroup END
            
call s:PrepareBits('general')


finish
-------------------------------------------------------------------
1.0
- Initial release

1.1
- User-defined tags
- Modifiers <+NAME:MODIFIERS+> (c=capitalize, u=toupper, l=tolower, 
  s//=substitute)
- Skeleton bits
- the default markup for tags has changed to <+TAG+> (for 
  "compatibility" with imaps.vim), the cursor position is marked as 
  <+CURSOR+> (but this can be changed by setting g:tskelPatternLeft, 
  g:tskelPatternRight, and g:tskelPatternCursor)
- in the not so simple mode, skeleton bits can contain vim code that 
  is evaluated after expanding the template tags (see 
  .../skeletons/bits/vim/if for an example)
- function TSkeletonExpandBitUnderCursor(), which is mapped to 
  <Leader>#
- utility function: TSkeletonIncreaseRevisionNumber()

1.2
- new pseudo tags: bit (recursive code skeletons), call (insert 
  function result)
- before & after sections in bit definitions may contain function 
  definitions
- fixed: no bit name given in s:SelectBit()
- don't use ={motion} to indent text, but simply shift it

1.3
- TSkeletonCleanUpBibEntry (mapped to <Leader>tc for bib files)
- complete set of bibtex entries
- fixed problem with [&bg]: tags
- fixed typo that caused some slowdown
- other bug fixes
- a query must be enclosed in question marks as in <+?Which ID?+>
- the "test_tSkeleton" skeleton can be used to test if tSkeleton is 
  working
- and: after/before blocks must not contain function definitions

1.4
- Popup menu with possible completions if 
  TSkeletonExpandBitUnderCursor() is called for an unknown code 
  skeleton (if there is only one possible completion, this one is 
  automatically selected)
- Make sure not to change the alternate file and not to distort the 
  window layout
- require genutils
- Syntax highlighting for code skeletons
- Skeleton bits can now be expanded anywhere in the line. This makes 
  it possible to sensibly use small bits like date or time.
- Minor adjustments
- g:tskelMapLeader for easy customization of key mapping (changed the 
  map leader to "<Leader>#" in order to avoid a conflict with Align; 
  set g:tskelMapLeader to "<Leader>t" to get the old mappings)
- Utility function: TSkeletonGoToNextTag(); imaps.vim like key 
  bindings via TSkeletonMapGoToNextTag()

1.5
- Menu of small skeleton "bits"
- TSkeletonLateExpand() (mapped to <Leader>#x)
- Disabled <Leader># mapping (use it as a prefix only)
- Fixed copy & paste error (loaded_genutils)
- g:tskelDir defaults to $HOME ."/vimfiles/skeletons/" on Win32
- Some speed-up

2.0
- You can define "groups of bits" (e.g. in php mode, all html bits are 
  available too)
- context sensitive expansions (only very few examples yet); this 
  causes some slowdown; if it is too slow, delete the files in 
  .vim/skeletons/map/
- one-line "mini bits" defined in either 
  ./vim/skeletons/bits/{&filetype}.txt or in $PWD/.tskelmini
- Added a few LaTeX, HTML and many Viki skeleton bits
- Added EncodeURL.vim
- Hierarchical bits menu by calling a bit "SUBMENU.BITNAME" (the 
  "namespace" is flat though; the prefix has no effect on the bit 
  name; see the "bib" directory for an example)
- the bit file may have an ampersand (&) in their names to define the 
  keyboard shortcut
- Some special characters in bit names may be encoded as hex (%XX as 
  in URLs)
- Insert mode: map g:tskelMapInsert ('<c-\><c-\>', which happens to be 
  the <c-#> key on a German qwertz keyboard) to 
  TSkeletonExpandBitUnderCursor()
- New <tskel:msg> tag in skeleton bits
- g:tskelKeyword_{&filetype} variable to define keywords by regexp 
  (when 'iskeyword' isn't flexible enough)
- removed the g:tskelSimpleBits option
- Fixed some problems with the menu
- Less use of globpath()

2.1
- Don't accidentally remove torn off menus; rebuild the menu less 
  often
- Maintain insert mode (don't switch back to normal mode) in 
  <c-\><c-\> imap
- If no menu support is available, use the s:Query function to let 
  the user select among eligible bits (see also g:tskelQueryType)
- Create a normal and an insert mode menu
- Fixed selection of eligible bits
- Ensure that g:tskelDir ends with a (back)slash
- Search for 'skeletons/' in &runtimepath & set g:tskelDir accordingly
- If a template is named "#.suffix", an autocmd is created  
  automatically.
- Set g:tskelQueryType to 'popup' only if gui is win32 or gtk.
- Minor tweak for vim 7.0 compatibility

2.2
- Don't display query menu, when there is only one eligible bit
- EncodeURL.vim now correctly en/decoded urls
- UTF8 compatibility -- use col() instead of virtcol() (thanks to Elliot 
  Shank)

2.3
- Support for current versions of genutils (> 2.0)

2.4
- Changed the default value for g:tskelDateFormat from "%d-%b-%Y" to 
'%Y-%m-%d'
- 2 changes to TSkeletonGoToNextTag(): use select mode (as does 
imaps.vim, set g:tskelSelectTagMode to 'v' to get the old behaviour), 
move the cursor one char to the left before searching for the next tag 
(thanks to M Stubenschrott)
- added a few AutoIt3 skeletons
- FIX: handle tabs properly
- FIX: problem with filetypes containing non-word characters
- FIX: check the value of &selection
- Enable normal tags for late expansion

3.0
- Partial rewrite for vim7 (drop vim6 support)
- Now depends on tlib (vimscript #1863)
- "query" now uses a more sophisticated version from autoload/tlib.vim
- The default value for g:tskelQueryType is "query".
- Experimental (proof of concept) code completion for vim script 
(already sourced user-defined functions only). Use :delf 
TSkelFiletypeBits_functions_vim to disable this as it can take some 
time on initialization.
- Experimental (proof of concept) tags-based code completion for ruby.  
Use :delf TSkelProcessTag_ruby to disable this. It's only partially 
useful as it simply works on method names and knows nothing about 
classes, modules etc. But it gives you an argument list to fill in. It 
shouldn't be too difficult to adapt this for other filetypes for which 
such an approach could be more useful.
- The code makes it now possible to somehow plug in custom bit types by 
defining TSkelFiletypeBits_{NAME}(dict, filetype), or 
TSkelFiletypeBits_{NAME}_{FILETYPE}(dict, filetype), 
TSkelBufferBits_{NAME}(dict, filetype), 
TSkelBufferBits_{NAME}_{FILETYPE}(dict, filetype).
- FIX s:RetrieveAgent_read(): Delete last line, which should fix the 
problem with extraneous return characters in recursively included 
skeleton bits.
- FIX: bits containing backslashes
- FIX TSkeletonGoToNextTag(): Moving cursor when no tag was found.
- FIX: Minibits are now properly displayed in the menu.

3.1
- Tag-based code completion for vim
- Made the supported skeleton types configurable via g:tskelTypes
- FIX: Tag-based skeletons the name of which contain blanks
- FIX: Undid shortcut that prevented the <+bit:+> tag from working
- Preliminary support for using keys like <space> for insert mode 
expansion.

3.2
- "tags" & "functions" types are disabled by default due to a noticeable 
delay on initialization; add 'tags' and 'functions' to g:tskelTypes to 
re-enable them (with the new caching strategy, it's usable, but can 
produce much noise; but this depends of course on the way you handle 
tags)
- Improved caching strategy: cache filetype bits in 
skeletons/cache_bits; cache buffer-specific bits in 
skeletons/cache_bbits/&filetype/path (set g:tskelUseBufferCache to 0 to 
turn this off; this speeds up things quite a lot but creates many files 
on the long run, so you might want to purge the cache from time to time)
- embedded <tskel:> tags are now extracted on initialization and not 
when the skeleton is expanded (I'm not sure yet if it is better this 
way)
- CHANGE: dropped support for the ~/.vim/skeletons/prefab subdirectory; 
you'll have to move the templates, if any, to ~/.vim/skeletons
- FIX: :TSkeletonEdit, :TSkeletonSetup command-line completion
- FIX: Problem with fold markers in bits when &fdm was marker
- FIX: Problems with PrepareBits()
- FIX: Problems when the skeletons/menu/ subdirectory didn't exist
- TSkeletonExecInDestBuffer(code): speed-up
- Moved functions from EncodeURL.vim to tlib.vim
- Updated the manual
- Renamed the skeletons/menu subdirectory to skeletons/cache_menu

