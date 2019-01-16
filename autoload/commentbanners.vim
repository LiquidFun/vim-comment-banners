" =============================================================================
" File:          autoload/comment-banners.vim
" Description:   Easily add mappings to create comment banners       
" Author:        LiquidFun <github.com/liquidfun>
" =============================================================================

" TODO: Dynamic width with -1
" TODO: Tests
" TODO: Implement remove comments flag

" ** Static Variables {{{1

" Note that the options for 1-9 are added by the for loop after the options

let s:defaultOptions = {
        \ 'pattern':                 ['=', '=', '='],
        \ 'width':                   78,
        \ 'commandsOnEachLine':      [],
        \ 'spacesSeparatingComment': 1,
        \ 'commentIfPossible':       1,
        \ 'beforeEach':              '',
        \ 'afterEach':               '',
        \ 'flip':                    0,
        \ 'removeComments':          1,
        \ 'allowTruncation':         1,
        \ 'mapping':                 '',
        \ 'line1':                   0,
        \ 'line2':                   0,
    \ }

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
        \ '--allow-truncation': 'allowTruncation',
        \ '-t':                 'allowTruncation',
        \ '--line1':            'line1',
        \ '--line2':            'line2',
    \ }

" After parsing the flags these functions will be called with 
" (options, optionName, value)
let s:optionToParsingFunction = {
        \ 'pattern':           's:parse_pattern',
        \ 'flip':            's:parse_bool',
        \ 'commentIfPossible': 's:parse_bool',
        \ 'allowTruncation':   's:parse_bool',
        \ 'removeComments':    's:parse_bool',
        \ 'operatorMode':      's:parse_bool',
    \ }

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
function! commentbanners#parser(...) 
    let options = s:apply_flags(a:000)
    if has_key(options, 'mapping') && options['mapping'] !=# ''
        call s:apply_mapping(options)
        return
    endif
    call commentbanners#setupopfunc(options)
endfunction

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
    if options['operatorMode']
        let line1 = getpos("'[")[1]
        let line2 = getpos("']")[1]
        call s:make_banner(line1, line2, options)
    else
        call s:make_banner(options['line1'], options['line2'], options)
    endif
endfunction
" }}}1
" ** Mappings {{{1
function! s:apply_mapping(options)
    " If operatorMode has not been set then determine it automatically:
    " if there is 0 or 1 title then no operatorMode
    " else operatorMode
    if !has_key(a:options, 'operatorMode')
        let titleInUseCount = 0
        for index in range(1,9)
            let titleInUseCount += a:options[strtrans(index)]['inUse']
        endfor
        let a:options['operatorMode'] = (titleInUseCount > 1)
    endif
    let mapping = a:options['mapping']
    let appendix = '<CR>'
    if a:options['operatorMode']
        let appendix .= 'g@'
    endif
    call execute('nnoremap <silent> ' . mapping . ' :call commentbanners#setupopfunc(' . string(a:options) . ')' . appendix)
endfunction
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
        let a:titleOptionsList = [a:titleOptions] 
    else 
        let a:titleOptionsList = a:titleOptions 
    endif
    for titleOptionWithVal in a:titleOptionsList
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

" Takes the lines from lnum1 to lnum2 and creates a comment banner with the
" supplied options.
function! s:make_banner(lnum1, lnum2, options)
    let lines = s:get_lines(a:lnum1, a:lnum2)
    let indentation = s:get_largest_indentation(a:lnum1, a:lnum1)
    let orderOfRows = s:get_sorted_by_appearance(a:options)
    let comments = s:get_comments(a:options)
    call execute(a:lnum1 . ',' . a:lnum2 . 'd')

    let front = comments[0] . a:options['beforeEach']
    let back = a:options['afterEach'] . comments[1]

    let commentbanner = []

    for pnum in range(len(a:options['pattern']))
        let titles = s:create_all_titles_in_line(orderOfRows, pnum, lines, a:options)
        let frontWithTitle = front . titles['left']
        let backWithTitle = titles['right'] . back
        let fillerWidth = 
                \ a:options['width'] 
                \ - s:indentation_length(indentation)
                \ - len(frontWithTitle)
                \ - len(backWithTitle)
                \ - len(titles['centre'])
        let currPattern = a:options['pattern'][pnum]
        let shouldFlip = a:options['flip']
        let allowTruncation = a:options['allowTruncation']
        let [leftFiller, rightFiller] = 
                \ s:create_fillers(fillerWidth, currPattern, shouldFlip, allowTruncation)
        let fullTitle = 
                \ indentation 
                \ . frontWithTitle 
                \ . leftFiller 
                \ . titles['centre'] 
                \ . rightFiller 
                \ . backWithTitle
        call add(commentbanner, fullTitle) 
    endfor
    call append(a:lnum1 - 1, commentbanner)
endfunction

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

" Returns a list of all titles appearing on that line
function! s:create_all_titles_in_line(orderOfRows, pnum, lines, options)
    " Takes: [{'align':'centre','row':1,'spaces':1}, ...], 1, ['A','B'], <options>
    " Returns: {'left':'A', 'centre':'', 'right':''}
    let titles = {'left':'', 'centre':'', 'right':''}
    while len(a:orderOfRows) != 0 && a:orderOfRows[0]['row'] == a:pnum
        let title = s:get_title(a:orderOfRows[0], a:lines, a:options)
        if a:orderOfRows[0]['align'] == 'right'
            let titles['right'] .= title
        elseif a:orderOfRows[0]['align'] == 'left'
            let titles['left'] .= title
        else
            let titles['centre'] .= title
        endif
        call remove(a:orderOfRows, 0)
    endwhile
    return titles
endfunction

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

function! s:get_lines(lnum1, lnum2)
    " Returns: a list of formatted strings from lnum1 to lnum2
    let lines = []
    for lnum in range(a:lnum1, a:lnum2)
        call add(lines, substitute(getline(lnum), '^\s*\|\s*$', '', 'g'))
    endfor
    return lines
endfunction

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

" }}}1
" * Indentation Length {{{1
function! s:indentation_length(indent) 
    return strdisplaywidth(a:indent)
    let length = 0
    let val = {' ': 1, '\t': &tabstop}
    for char in split(a:indent)
        let length += val[char]
    endfor
    return length
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
" }}}1
" ** Testing {{{1
function! s:set_test_mappings()
    CommentBanner -m g1 -w 60 -p =,1-,=
    CommentBanner -m g2 -w 60 -p =,1,= -1 align:left,spaces:1
    CommentBanner -m g3 -w 60 -p -,12 -1 align:left -2 align:right -c 0 
    " nnoremap g4 :CommentBanner -w 60 -p 1-,2-,3- -A \ --\|-  -B -\|--\  <CR>
    " nnoremap g5 :CommentBanner -w 60 -p 1=,,2,3,,= -A === -B === -2 align:left -3 align:left <CR>
    " nnoremap g6 :CommentBanner -w 60 -p -=<{,--=<<{(,-=<{ --flip true <CR>
    "
    " nnoremap g2 :CommentBanner -w 60 -p =,1,= -1 align:left,spaces:1 <CR>
    " nnoremap g3 :CommentBanner -w 60 -p -,12 -1 align:left -2 align:right -c 0 <CR>
    " nnoremap g4 :CommentBanner -w 60 -p 1-,2-,3- -A \ --\|-  -B -\|--\  <CR>
    " nnoremap g5 :CommentBanner -w 60 -p 1=,,2,3,,= -A === -B === -2 align:left -3 align:left <CR>
    " nnoremap g6 :CommentBanner -w 60 -p -=<{,--=<<{(,-=<{ --flip true <CR>
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
