function! g:CommentBanner(
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
    let titleText = substitute(getline(lineNum), '^ *\|^\t*\| *$\|\t*$', '', 'g')
    let titleLength = strlen(titleText)             

    " Needed count of separator chars in title
    let charsFit = a:columnLimit - titleLength - strlen(a:addBefore) - strlen(a:addAfter) - 2
    let charsFitLeft = charsFit / 2
    let charsFitRight = charsFit / 2 + charsFit % 2

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
    call s:CommentIfPossible(a:isToBeCommented)

    " Add filler before and after title
    while lineCountAfter > 0
        call append(lineNum, filler)
        call cursor(lineNum + 1, 1)
        call s:CommentIfPossible(a:isToBeCommented)
        let lineCountAfter -= 1
    endwhile

    while lineCountBefore > 0
        call append(lineNum - 1, filler)
        call cursor(lineNum, 1)
        call s:CommentIfPossible(a:isToBeCommented)
        let lineCountBefore -= 1
    endwhile

endfunction

function! g:MakeSimpleTitleBar(pattern, lineCountAfter)
    call MakeTitleBar(a:pattern, 1, a:lineCountAfter, 1, 0, 78, "", "")<CR>
endfunction 

function! s:CommentIfPossible(isToBeCommented)
    if a:isToBeCommented
        let commentaryAvailable = execute('command Commentary') 
        if !empty(commentaryAvailable)
            Commentary
            return
        endif
        " TODO: Display error message here
    endif
endfunction

