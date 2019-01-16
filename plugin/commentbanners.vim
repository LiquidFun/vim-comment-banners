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

command! -nargs=* -range CommentBanner call commentbanners#parser('--line1', <line1>, '--line2', <line2>, <f-args>)
