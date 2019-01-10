" =============================================================================
" File:          autoload/comment-banners.vim
" Description:   Easily add mappings to create comment banners       
" Author:        LiquidFun <github.com/liquidfun>
" =============================================================================

" ** Static Variables {{{1

" Options
let s:defaultOptions = {
        \ 'pattern': ['=', '=', '='],
        \ 'width': 78,
        \ '1': {'align': 'centre', 'row': 1, 'spaces': 1},
        \ 'commandsOnEachLine': [],
        \ 'spacesSeparatingComment': 1,
        \ 'commentIfPossible': 0,
        \ 'beforeEach': '',
        \ 'afterEach': '',
        \ 'mirror': 0,
    \ }

" Flags
let s:flagToOption = {
        \ '--pattern': 'pattern',
        \ '-p': 'pattern',
        \ '--width': 'width',
        \ '-w': 'width',
        \ '--commands': 'commandForEachLine',
        \ '-C': 'commandForEachLine',
        \ '--comment': 'commentIfPossible',
        \ '-c': 'commentIfPossible',
        \ '--before': 'beforeEach',
        \ '-B': 'beforeEach',
        \ '--after': 'afterEach',
        \ '-A': 'afterEach',
        \ '--mirror': 'mirror',
        \ '-m': 'mirror',
    \ }

let s:optionToParsingFunction = {
        \ 'pattern': 's:parse_pattern',
        \ 'mirror': 's:parse_bool',
        \ 'title': 's:parse_text',
        \ 'description': 's:parse_text',
    \ }

"}}}1
" ** Wrappers {{{1
function! commentbanners#wrapper(...) 
    let options = s:apply_flags(a:000)
    let lineNum = getcurpos()[1]
    call s:make_banner(lineNum, lineNum, options)
endfunction

function! commentbanners#wrapper_motion() 
    let &operatorfunc = 'commentbanners#wrapper'
    echo &operatorfunc
    call execute('g@')
    " let options = s:apply_flags(a:000[2:])
    " call s:make_banner(a:line1, a:line2, options)
endfunction
" }}}1
" ** Flag Management {{{1

function! s:apply_flags(flags)
    " Returns: modified dict of default options
    let options = deepcopy(s:defaultOptions)
    for flag in a:flags
        let [flagName, value] = s:parse_flag(flag)
        let optionName = s:flagToOption[flagName]
        if has_key(s:optionToParsingFunction, optionName)
            let ParseFunction = function(s:optionToParsingFunction[optionName])
            call ParseFunction(options, optionName, value)
        else
            let options[optionName] = value
        endif
    endfor
    return options
endfunction

" temp command
" command! -nargs=? PF call s:parse_flag(<q-args>)<CR>

function! s:parse_flag(flag)
    " Returns: dict with { flagName : value } 
    let key = matchstr(a:flag, '.\{-}=')
    let key = key[:len(key)-2]
    let values = s:parse_values(matchstr(a:flag, '=.*$')[1:])
    return [key, values]
endfunction

" temp command
" command! -nargs=? Parse call s:parse_values(<q-args>)<CR>

function! s:parse_values(value)
    " Returns: list of values or single value if list is of size 1
    let separate = split(a:value, '\\\@<!,')
    call map(separate, {key, val -> substitute(val, '\\,', ',', 'g')})
    if len(separate) == 1
        return separate[0]
    endif
    return separate
endfunction

" Parse Value Functions {{{2
function! s:parse_pattern(options, optionName, pattern)
    for pnum in range(len(a:pattern))
        if matchstr(a:pattern[pnum], '\\\@<!t')
            let a:options['titleRowNum'] = pnum
        endif
        if matchstr(a:pattern[pnum], '\\\@<!s')
            let a:options['subtitleRowNum'] = pnum
        endif
		let subPairs = {'\\\@<!t': '', '\\\@<!s': '','\\t': 't', '\\s': 's'}
		for [key, val] in items(subPairs)
            let a:pattern[pnum] = substitute(a:pattern[pnum], key, val, 'g') 
        endfor
    endfor
    let a:options[a:optionName] = a:pattern
endfunction

function! s:parse_bool(options, optionName, value)
    if a:value ==? 'false' || a:value == 0
        let a:options[a:optionName] = 0
    else
        let a:options[a:optionName] = 1
    endif
endfunction
" }}}2

" }}}1
" ** Banner Creation {{{1
function! s:make_banner(lnum1, lnum2, options)
    let lines = get_lines(lnum1, lnum2)
endfunction

function! s:get_lines(lnum1, lnum2)
    " Returns: a list of formatted strings from lnum1 to lnum2
    let lines = []
    for lnum in range(lnum1, lnum2)
        call add(lines, substitute(getline(lnum), '^\s*\|\s*$', '', 'g')))
    endfor
    return lines
endfunction

function! s:sort_by_occurence(lines, options) 
    let occ = []
    for index in range(1,9)
        if has_key(options, string(index)) 
            add(occ,)
        endif
    endfor
endfunction

" }}}1

" {{{1
function! s:make_banner_failed(lnum1, lnum2, options)
    " Find largest indentation
    let aboveCommentBanner = []
    let belowCommentBanner = []
    let tRow = a:options['titleRowNum']
    if tRow == 'none'
        let tRow = 0
    endif
    let pLen = len(a:options['pattern'])
    let indentation = ''
    for lnum in range(a:lnum1, a:lnum2)
        let curr = matchstr(getline(lnum), '^\s*')
        if s:indentation_length(indentation) < s:indentation_length(curr)
            indentation == curr
        endif
    endfor
    " Define variables which are true for finalCommentBanner lines
    let cSpaces = repeat(' ', a:options['spacesSeparatingComment'])
    let comments = s:comment_chars()
    if comments[0] != ''
        let comments[0] = comments[0] . cSpaces
    endif
    if comments[1] != ''
        let comments[1] = cSpaces . comments[1]
    endif
    let front = indentation . comments[0] . a:options['beforeEach']
e   let back = a:options['afterEach'] . comments[1]
    " Add fillers before
    let charsFit = a:options['width'] - len(front) - len(back)
    for index in range(0, tRow - 1)
        let currPattern = a:options['pattern'][index]
        call add(finalCommentBanner, front . repeat(currPattern, charsFit) . back)
    endfor
    " Add fillers after
    for index in range(tRow + 1, pLen - 1)
        let currPattern = a:options['pattern'][index]
        call add(finalCommentBanner, front . repeat(currPattern, charsFit) . back)
    endfor
    " Insert banner
    for index in range(len(finalCommentBanner))
        call append(a:lnum1 - tRow + index, finalCommentBanner[index])
    endfor
endfunction

function! s:setText(lnum1, lnum2, prefix)
    for lnum in range(a:lnum1, a:lnum2) 
        let tSpaces = repeat(' ', a:options['titleSpaces'])
        if options['title']
        let titletext
        if a:options['titleAlignment'] != 'right'
            let titletext = titletext . tSpaces
        endif
        if a:options['titleAlignment'] != 'left'
            let titletext = tSpaces . titletext
        endif
        let charsFitTitle = a:options['width'] - len(front) - len(titletext) - len(back)
        let align = a:options['titleAlignment']
        if align == 'centre'
            let pCount = charsFitTitle / 2
        elseif align == 'left'
            let pCount = 0
        elseif align == 'right'
            let pCount = charsFitTitle
        else
            let pCount = charsFitTitle - max([len(front) - align, 0])
        endif
        let currPattern = a:options['pattern'][tRow]
        let full = 
            \ front 
            \ . repeat(currPattern, pCount) 
            \ . titletext 
            \ . repeat(currPattern, charsFitTitle - pCount)
            \ . back
        call setline(lnum, full)
    endfor
endfunction

"}}}1
" * Indentation Length {{{1
function! s:indentation_length(indent) 
    let length = 0
    let val = {' ': 1, '\t': &tabstop}
    for char in split(a:indent)
        let length += val[char]
    endfor
    return length
endfunction
" }}}1
" - Deprecated {{{1
function! s:make_banner_deprecated(
        \ pattern,
        \ titlePattern,
        \ lineCountBefore,
        \ lineCountAfter,
        \ columnLimit,
        \ addBefore,
        \ addAfter,
        \ isToBeCommented,
    \ )

    let lineCountBefore = a:lineCountBefore
    let lineCountAfter = a:lineCountAfter
    let lineNum = getcurpos()[1]
    let indentation = matchstr(getline(lineNum), '^ *|^\t*')
    " let indentationLength

    " Remove spaces/tabs before and after title
    let titleText = substitute(getline(lineNum), '^\s*\|\s*$', '', 'g')
    let titleLength = strlen(titleText)             

    " Needed count of separator chars in title
    let charsFit = a:columnLimit - titleLength - strlen(a:addBefore) - strlen(a:addAfter) - 2
    let charsFitLeft = charsFit / 2
    let charsFitRight = charsFit / 2 + charsFit % 2

    let patternsFit = charsFit / strlen(a:pattern)
    let patternsFitLeft = charsFitLeft / strlen(a:titlePattern)
    let patternsFitRight = charsFitLeft / strlen(a:titlePattern)

    let divLeft = repeat(a:pattern, charsFitLeft)
    let divRight = repeat(a:pattern, charsFitRight)
    let divTitleLeft = repeat(a:titlePattern, charsFitLeft)
    let divTitleRight = repeat(a:titlePattern, charsFitRight)
    let middle = divTitleLeft . ' ' . titleText . ' ' . divTitleRight

    if a:titlePattern ==# ''
        let middle = middle . repeat(' ', charsFit) 
    endif

    " A full line of separator chars
    let filler = divLeft . a:pattern . repeat(a:pattern, titleLength) . a:pattern . divRight

    if a:pattern ==# ''
        let filler = filler . repeat(' ', charsFit) 
    endif

    " Add the before and after stuff
    let middle = a:addBefore . middle . a:addAfter
    let filler = a:addBefore . filler . a:addAfter

    call setline(lineNum, middle)
    call s:comment_if_possible(a:isToBeCommented)

    " Add filler before and after title
    while lineCountAfter > 0
        call append(lineNum, filler)
        call cursor(lineNum + 1, 1)
        call s:comment_if_possible(a:isToBeCommented)
        let lineCountAfter -= 1
    endwhile

    while lineCountBefore > 0
        call append(lineNum - 1, filler)
        call cursor(lineNum, 1)
        call s:comment_if_possible(a:isToBeCommented)
        let lineCountBefore -= 1
    endwhile

endfunction
" }}}1
" ** Comment Handling {{{1
function! s:comment_chars() abort
    let comment = &commentstring 
    if comment ==# ''
        let comment = '%s'
    endif
    return split(substitute(comment, '\s*', '', 'g'), '%s', 1)
endfunction

function! s:comment_if_possible(isToBeCommented)
    if a:isToBeCommented
        let commentaryAvailable = execute('command Commentary') 
        if !empty(commentaryAvailable)
            Commentary
            return
        endif
        " TODO: Display error message here
    endif
endfunction
" }}}1

" vim:fdm=marker:fmr={{{,}}}:fdc=1
