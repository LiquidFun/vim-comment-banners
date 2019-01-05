" =============================================================================
" File:         plugin/comment-banners.vim
" Description:  Easily add mappings to create comment banners       
" Author:       LiquidFun <github.com/liquidfun
" =============================================================================

if exists('g:loaded_comment_banners') && g:loaded_comment_banners
    finish
endif

" let g:loaded_comment_banners = 1

command! -nargs=* -range CommentBanner call commentbanners#wrapper(<f-args>)
command! -nargs=* -range CommentBannerWithMotion 
    \ call commentbanners#wrapper_motion()

