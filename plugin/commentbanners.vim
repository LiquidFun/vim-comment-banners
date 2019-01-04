" =============================================================================
" File:         plugin/comment-banners.vim
" Description:  Easily add mappings to create comment banners       
" Author:       LiquidFun <github.com/liquidfun
" =============================================================================

if exists('g:loaded_comment_banners') && g:loaded_comment_banners
    finish
endif

command! -nargs=* CommentBanner call commentbanners#wrapper(<f-args>)
command! -nargs=* -range CommentBannerWithMotion 
    \ call commentbanners#wrapper_motion(<line1>, <line2>, <f-args>)

