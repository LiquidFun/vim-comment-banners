" =============================================================================
" File:          autoload/comment-banners.vim
" Description:   Easily add mappings to create comment banners       
" Author:        LiquidFun <github.com/liquidfun>
" =============================================================================

" TODO: Dynamic width with -1
" TODO: Tests
" TODO: Implement remove comments flag
" TODO: Fix spacing issue with titles

" ** Static Variables {{{1

" Note that the options for 1-9 are added by the for loop after the options

" * Default Options {{{2 
let s:defaultOptions = {
        \ 'pattern':                 ['=', '=', '='],
        \ 'width':                   78,
        \ 'commandsOnEachLine':      [],
        \ 'spacesSeparatingComment': 1,
        \ 'commentIfPossible':       0,
        \ 'beforeEach':              '',
        \ 'afterEach':               '',
        \ 'flip':                    0,
        \ 'removeComments':          1,
        \ 'allowTruncation':         1,
        \ 'operatorMode':            'auto',
        \ 'mapping':                 '',
        \ 'line1':                   0,
        \ 'line2':                   0,
    \ }
"}}}2
" * Flag to Option Dictionary {{{2
" Used to convert from flags to patterns
let s:flagToOption = {
        \ '--pattern':          'pattern',
        \ '-p':                 'pattern',
        \ '--width':            'width',
        \ '-w':                 'width',
        \ '--commands':         'commandForEachLine',
        \ '-C':                 'commandForEachLine',
        \ '--comment':          'commentIfPossible',
        \ '-c':                 'commentIfPossible',
        \ '--before':           'beforeEach',
        \ '-B':                 'beforeEach',
        \ '--after':            'afterEach',
        \ '-A':                 'afterEach',
        \ '--flip'  :           'flip',
        \ '-f':                 'flip',
        \ '--mapping':          'mapping',
        \ '-m':                 'mapping',
        \ '--remove-comments':  'removeComments',
        \ '-r':                 'removeComments',
        \ '--operator':         'operatorMode',
        \ '-o':                 'operatorMode',
        \ '--truncate':         'allowTruncation',
        \ '-t':                 'allowTruncation',
        \ '--line1':            'line1',
        \ '--line2':            'line2',
    \ }
" }}}2
" * Option to parsing function dictionary {{{2
" After parsing the flags these functions will be called with 
" (options, optionName, value)
let s:optionToParsingFunction = {
        \ 'pattern':           's:parse_pattern',
        \ 'flip':              's:parse_bool',
        \ 'commentIfPossible': 's:parse_bool',
        \ 'allowTruncation':   's:parse_bool',
        \ 'removeComments':    's:parse_bool',
        \ 'operatorMode':      's:parse_bool',
    \ }
" }}}2

" Adds the defaults of the 1-9 options to the flags
for index in range(1,9)
    let s:flagToOption['-' . strtrans(index)] = strtrans(index)
    let s:optionToParsingFunction[strtrans(index)] = 's:parse_title_option'
    let s:defaultOptions[strtrans(index)] = {
            \ 'align':  'centre',
            \ 'spaces': 1,
            \ 'row':    index,
            \ 'inUse':  (index == 1),
        \ }
endfor

"}}}1
" ** Public {{{1

" * Parser {{{2
function! commentbanners#parser(...) 
    let options = s:apply_flags(a:000)
    if has_key(options, 'mapping') && options['mapping'] !=# ''
        call s:apply_mapping(a:000)
        return
    endif
    call commentbanners#setupopfunc(options)
endfunction
" }}}2
" * Opfunc {{{
function! commentbanners#setupopfunc(options)
    if has_key(a:options, 'operatorMode') && a:options['operatorMode']
        let s:tempOptions = a:options
        let &operatorfunc = 'commentbanners#opfunc'
    else
        call s:make_banner(a:options['line1'], a:options['line2'], a:options)
    endif
endfunction

function! commentbanners#opfunc(...)
    let options = s:tempOptions
    let line1 = getpos("'[")[1]
    let line2 = getpos("']")[1]
    call s:make_banner(line1, line2, options)
endfunction
" }}}2
" * Mappings {{{2

" Sets up mappings for comment banners. Determines if these should be in
" operator mode.
" TODO: set up vnoremap
function! commentbanners#map(mapping, command, ...)
    " If operatorMode has not been set then determine it automatically:
    " if there is 0 or 1 title then no operatorMode
    " else operatorMode
    let options = s:apply_flags(a:000)
    if !has_key(options, 'operatorMode') || options['operatorMode'] ==? 'auto'
        let titleInUseCount = 0
        for index in range(1,9)
            let titleInUseCount += options[strtrans(index)]['inUse']
        endfor
        let options['operatorMode'] = (titleInUseCount > 1)
    endif
    if options['operatorMode']
        " If operator is set then do not allow range and run g@ after function
        call execute('nnoremap <silent> <nowait> ' . a:mapping . ' :call commentbanners#setupopfunc(' . string(options) . ')<CR>g@')
    else
        " If no operator is set then allow range
        let flagsStr = ''
        for flag in a:000
            let flagsStr .= flag . ' '
        endfor
        call execute('nnoremap <silent> <nowait> ' . a:mapping . ' ' . a:command . ' ' . flagsStr . '<CR>')
    endif
endfunction
" }}}2

" }}}1
" ** Flag Management {{{1

" * Parsing Flags in General {{{2
function! s:apply_flags(flags)
    " Returns: modified dict of default options
    call assert_true(len(a:flags) % 2 == 0, 'Uneven number of flags given')
    let options = deepcopy(s:defaultOptions)
    let flagValuePairs = []
    let index = 0
    while index < len(a:flags)
        call assert_true(has_key(options, a:flags[index]))
        call add(flagValuePairs, [a:flags[index], s:parse_values(a:flags[index+1])]) 
        let index += 2
    endwhile
    for pair in flagValuePairs
        let optionName = s:flagToOption[pair[0]]
        if has_key(s:optionToParsingFunction, optionName)
            let ParseFunction = function(s:optionToParsingFunction[optionName])
            call ParseFunction(options, optionName, pair[1])
        else
            let options[optionName] = pair[1]
        endif
    endfor
    return options
endfunction

function! s:parse_values(value)
    " Returns: list of values or single value if list is of size 1
    let separate = split(a:value, '\\\@<!,', 1)
    call map(separate, {key, val -> substitute(val, '\\,', ',', 'g')})
    if len(separate) == 1
        return separate[0]
    endif
    return separate
endfunction
" }}}2
" * Parse Value Functions {{{2
function! s:parse_pattern(options, optionName, pattern)
    for index in range(1,9)
        let a:options[strtrans(index)]['inUse'] = 0
    endfor
    for pnum in range(len(a:pattern))
        let titleNums = []
        let subPairs = [
                    \ ['\\\@<!\d', '\=add(titleNums, submatch(0))'], 
                    \ ['\n', ''],
                    \ ['\\\@<!\d', ''],
                    \ ['\\\d\@=', ''],
                \ ]
        for [key, val] in subPairs
            let a:pattern[pnum] = substitute(a:pattern[pnum], key, val, 'g') 
        endfor
        for title in titleNums
            let a:options[strtrans(title)]['inUse'] = 1
            let a:options[strtrans(title)]['row'] = pnum
        endfor
        if a:pattern[pnum] == ''
            let a:pattern[pnum] = ' '
        endif
    endfor
    let a:options[a:optionName] = a:pattern
endfunction

function! s:parse_bool(options, optionName, value)
    if a:value ==? 'false' || a:value ==# '0'
        let a:options[a:optionName] = 0
    else
        let a:options[a:optionName] = 1
    endif
endfunction

function! s:parse_title_option(options, optionName, titleOptions) 
    if type(a:titleOptions) != type([])
        let l:titleOptionsList = [a:titleOptions] 
    else 
        let l:titleOptionsList = a:titleOptions 
    endif
    for titleOptionWithVal in l:titleOptionsList
        call assert_true(matchstr(titleOptionWithVal, ':'), 
                    \ 'Cannot parse title option ' . a:optionName . ' without :')
        let [titleOption, val] = split(titleOptionWithVal, ':')
        if has_key(a:options, a:optionName)
            let a:options[a:optionName][titleOption] = val
        else
            let a:options[a:optionName] = {}
            let a:options[a:optionName][titleOption] = val
        endif
    endfor
endfunction
" }}}2

" }}}1
" ** Banner Creation {{{1

" * Make Banner {{{2

" Takes the lines from lnum1 to lnum2 and creates a comment banner with the
" supplied options.
function! s:make_banner(lnum1, lnum2, options)
    let indentation = s:get_largest_indentation(a:lnum1, a:lnum1)
    let comments = s:get_comments(a:options)
    let front = comments[0] . a:options['beforeEach']
    let back = a:options['afterEach'] . comments[1]
    let titles = s:create_all_titles(a:lnum1, a:lnum2, a:options)
    let commentbanner = []
    
    " Calculate width and title appearances
    let maxFillerWidth = 0
    for pnum in range(len(a:options['pattern']))
        let frontWithTitle = front . titles[pnum]['left']
        let backWithTitle = titles[pnum]['right'] . back
        let withoutFillerLength = 
                    \ s:indentation_length(indentation)
                    \ + len(frontWithTitle)
                    \ + len(backWithTitle)
                    \ + len(titles[pnum]['centre'])
        if a:options['width'] ==? 'auto'
            let maxFillerWidth = max([maxFillerWidth, withoutFillerLength])
        else
            let maxFillerWidth = a:options['width']
        endif
    endfor

    " Delete titles
    call execute(a:lnum1 . ',' . a:lnum2 . 'd')

    " Create final banner
    for pnum in range(len(a:options['pattern']))
        let frontWithTitle = front . titles[pnum]['left']
        let backWithTitle = titles[pnum]['right'] . back
        let currPattern = a:options['pattern'][pnum]
        let fillerWidth = 
                    \ maxFillerWidth
                    \ - s:indentation_length(indentation)
                    \ - len(frontWithTitle)
                    \ - len(backWithTitle)
                    \ - len(titles[pnum]['centre'])
        let shouldFlip = a:options['flip']
        let allowTruncation = a:options['allowTruncation']
        let [leftFiller, rightFiller] = 
                \ s:create_fillers(fillerWidth, currPattern, shouldFlip, allowTruncation)
        let fullTitle = 
                \ indentation 
                \ . frontWithTitle 
                \ . leftFiller 
                \ . titles[pnum]['centre'] 
                \ . rightFiller 
                \ . backWithTitle
        call add(commentbanner, fullTitle) 
    endfor
    call append(a:lnum1 - 1, commentbanner)
endfunction
" }}}2
" * Create Fillers {{{2

" Creates fillers which completely fill the required width with the pattern,
" flipping the right side if needed.
function! s:create_fillers(width, pattern, flip, allowTruncation)
    " Takes: 20, <{, true
    " Returns: ['<{<{<{<{<{', '}>}>}>}>}>']
    let leftOfCentre = a:width / 2
    let rightOfCentre = a:width / 2 + a:width % 2
    let leftPattern = a:pattern
    if a:flip 
        let rightPattern = s:flip_pattern(a:pattern)
    else 
        let rightPattern = leftPattern
    endif
    let leftFiller = repeat(leftPattern, leftOfCentre / len(leftPattern))
    let rightFiller = repeat(rightPattern, rightOfCentre / len(rightPattern))
    " TODO: Add option to truncate
    if a:allowTruncation
        let leftFiller = leftPattern . leftFiller
        let rightFiller = rightFiller . rightPattern
    else
        let leftFiller = repeat(' ', len(leftPattern)) . leftFiller
        let rightFiller = rightFiller . repeat(' ', len(rightPattern) - 1)
    endif
    let leftFiller = strcharpart(leftFiller, len(leftFiller) - leftOfCentre)
    let rightFiller = strcharpart(rightFiller, 0, rightOfCentre)
    return [leftFiller, rightFiller]
endfunction
" }}}2
" * Flip Pattern {{{2

" Flips a pattern by changing the directional characters and reversing their
" order.
function! s:flip_pattern(pattern)
    " Takes: --<--<--<{
    " Returns: }>-->-->--
    let newPattern = ''
    let swaps = {'>': '<', '<': '>', '}': '{', '{': '}', ')': '(', '(': ')',
                \ ']': '[', '[': ']', '\': '/', '/': '\'}
    for char in split(a:pattern, '\zs')
        if has_key(swaps, char)
            let newPattern = swaps[char] . newPattern
        else
            let newPattern = char . newPattern
        endif
    endfor
    return newPattern
endfunction
" }}}2
" * Create All Titles In Line {{{2

" Returns a list of all titles appearing on that line
function! s:create_all_titles(lnum1, lnum2, options)
    let titles = []
    let lines = s:get_lines(a:lnum1, a:lnum2)
    let orderOfRows = s:get_sorted_by_appearance(a:options)
    for pnum in range(len(a:options['pattern']))
        let titlesInLine = {'left':'', 'centre':'', 'right':''}
        while len(orderOfRows) != 0 && orderOfRows[0]['row'] == pnum
            let title = s:get_title(orderOfRows[0], lines, a:options)
            if orderOfRows[0]['align'] == 'right'
                let titlesInLine['right'] .= title
            elseif orderOfRows[0]['align'] == 'left'
                let titlesInLine['left'] .= title
            else
                let titlesInLine['centre'] .= title
            endif
            call remove(orderOfRows, 0)
        endwhile
        call add(titles, titlesInLine)
    endfor
    return titles
endfunction
" }}}2
" * Get Title {{{2
function! s:get_title(currTitleOptions, lines, options)
    let spaces = repeat(' ', a:currTitleOptions['spaces'])
    if len(a:lines) == 0
        return ''
    endif
    let text = a:lines[0]
    call remove(a:lines, 0)
    if text != '' 
        if a:currTitleOptions['align'] != 'right' || a:options['beforeEach'] != ''
            let text = text . spaces
        endif
        if a:currTitleOptions['align'] != 'left' || a:options['afterEach'] != ''
            let text = spaces . text
        endif
    endif
    return text
endfunction
" }}}2
" * Get Lines {{{2
function! s:get_lines(lnum1, lnum2)
    " Returns: a list of formatted strings from lnum1 to lnum2
    let lines = []
    for lnum in range(a:lnum1, a:lnum2)
        call add(lines, substitute(getline(lnum), '^\s*\|\s*$', '', 'g'))
    endfor
    return lines
endfunction
" }}}2
" * Get Sorted By Appearance {{{2
function! s:get_sorted_by_appearance(options) 
    let occ = []
    for index in range(1,9)
        if has_key(a:options, strtrans(index)) 
            if a:options[strtrans(index)]['inUse']
                call add(occ, a:options[strtrans(index)])
            endif
        endif
        call sort(occ, {i1, i2 -> i1['row'] - i2['row']})
    endfor
    return occ
endfunction
" }}}2
" * Get Comments {{{2
function! s:get_comments(options)
    if !a:options['commentIfPossible']
        return ['', '']
    endif
    let comments = s:comment_chars()
    let cSpaces = repeat(' ', a:options['spacesSeparatingComment'])
    if comments[0] != ''
        let comments[0] = comments[0] . cSpaces
    endif
    if comments[1] != ''
        let comments[1] = cSpaces . comments[1]
    endif
    return comments
endfunction
" }}}2
" * Get Largest Indentation {{{2
function! s:get_largest_indentation(lnum1, lnum2) 
    let indentation = ''
    for lnum in range(a:lnum1, a:lnum2)
        let curr = matchstr(getline(lnum), '^\s*')
        if s:indentation_length(indentation) < s:indentation_length(curr)
            let indentation = curr
        endif
    endfor
    return indentation
endfunction
" }}}2
" * Indentation Length {{{2
function! s:indentation_length(indent) 
    return strdisplaywidth(a:indent)
    let length = 0
    let val = {' ': 1, '\t': &tabstop}
    for char in split(a:indent)
        let length += val[char]
    endfor
    return length
endfunction
" }}}2

" }}}1
" ** Comment Handling {{{1
function! s:comment_chars() abort
    let comment = &commentstring 
    if comment ==# ''
        let comment = '%s'
    endif
    return split(substitute(comment, '\s*', '', 'g'), '%s', 1)
endfunction
" }}}1
" ** Testing {{{1
function! s:set_test_mappings()
    CommentBannerMapping g1 :CommentBanner -p =,1-,=
    CommentBannerMapping g2 :CommentBanner -p <->,1-,<-> -w auto -B \|>- -A -<\|
    CommentBannerMapping g3 :CommentBanner -p -,12 -1 align:left -2 align:right
    CommentBannerMapping g4 :CommentBanner -w 60 -p 1-,2-,3- -A \ --\|-  -B -\|--\  
    CommentBannerMapping g5 :CommentBanner -w 60 -p 1=,,2,3,,= -A === -B === -2 align:left -3 align:left
    CommentBannerMapping g6 :CommentBanner -w 60 -p -=<{,1--=<<{(,-=<{ --flip true
    CommentBannerMapping g7 :CommentBanner -w 60 -p -<:>-,1,-<:>- -A -<:  -B  :>-  -1 align:left -c false -C Commentary
    CommentBannerMapping g8 :CommentBanner -p <->,1-,<-> -w 60 -B \|>- -A -<\|
    CommentBannerMapping g9 :CommentBanner -w 70 -p -</({,-=<{\|,-----<{1,-=<{\|,-</({  -1 spaces:3 -c false -f true
endfunction
call s:set_test_mappings()

finish

" --------------- TESTING GROUNDS ----------------
" ================================================

INSTRUCTIONS
1. Do something                  
2. Do something else

" }}}1


" vim:fdm=marker:fmr={{{,}}}:fdc=1
