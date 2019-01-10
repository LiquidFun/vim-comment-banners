" =============================================================================
" File:         plugin/comment-banners.vim
" Description:  Easily add mappings to create comment banners       
" Author:       LiquidFun <github.com/liquidfun
" Version:       0.0.4
" =============================================================================

if exists('g:loaded_comment_banners') || v:version < 700
    finish
endif

" let g:loaded_comment_banners = 1

command! -nargs=* -range CommentBanner call commentbanners#wrapper(<f-args>)
" command! -nargs=* -range CommentBannerWithMotion 
"     \ call commentbanners#wrapper_motion()

nnoremap <Plug>CommentBanner <SID>commentbanners#wrapper(<f-args>)
