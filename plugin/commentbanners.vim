" =============================================================================
" File:         plugin/comment-banners.vim
" Description:  Easily add mappings to create comment banners       
" Author:       LiquidFun <github.com/liquidfun
" Version:      0.1.0
" =============================================================================

if exists('g:loaded_comment_banners') || v:version < 700
    finish
endif

" let g:loaded_comment_banners = 1

command! -nargs=* -range CommentBanner call commentbanners#wrapper('--line1', <line1>, '--line2', <line2>, <f-args>)

function! MyOpfunc(type, ...)
    let rangeStart = getpos("'[")[1]
    let rangeEnd = getpos("']")[1]
    echo a:000
    " call feedkeys('g@', 'i')
    " call feedkeys(':CommentBanner --line1 ' . rangeStart . ' --line2 ' . rangeEnd, 'i')
endfunction

nmap <Plug>CommentBanner :set opfunc=MyOpfunc<CR>g@
nmap gy <Plug>CommentBanner<CR>

