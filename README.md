# Vim-Comment-Banners

Vim-Comment-Banners is a Vim plugin which sets up mappings for creating formatted comment banners/boxes. It supports a wide variety of comment banners, including many comment banners used in popular projects such as {TODO}. It is meant to simplify the process of making beautiful configs, the idea being that each user sets up a couple of comment banner mappings and then uses them in any future projects/configs (you can also copy those from the :h CommentBanner page).


## Showcase

## Quick Guide

### Simple Mapping

Since most people would want different banners this plugin does not predefine any mappings,
it instead allows you to easily add mappings to your `.vimrc` for creating banners:

```
CommentBannerMapping g1 :CommentBanner --pattern =,1-,=  --width 60  --comment false
```

Produces this output once called with g1 on a line which has `Title` in it:

```
==========================================================
------------------------- Title --------------------------
==========================================================
```

You could use Vim's mapping directly, but this way the CommentBannerMapping command
will set up nmap and vmap mappings + operators.

#### Explanation

* `g1` is your mapping.
* `:CommentBanner` is the command provided by the plugin for making comment banners.
* `--pattern` is a flag supplied to `:CommentBanner` with the argument of `=,1-,=`. The argument is split on `,`, where each split is considered the pattern for that line. For simplicity, a pattern is a string of chars which is duplicated until it fills the specified with.
* `--width` is yet another flag which specifies the column for the last character. This is useful to keep the 78 / 80 char limit on some projects. If this is not needed you can supply `auto` which would add just enough characters to cover the title.
* `--comment` specifies whether the banner should be commented out.

Whereas running this (`--comment` is set as `true` by default):

```
CommentBannerMapping g2 :CommentBanner --pattern =,1-,=  --width 60
```

would create this banner (depending on your language):

```
/* ==================================================== */
/* ---------------------- Title ----------------------- */
/* ==================================================== */
```

Note that it is still exactly 60 characters wide.

## Installation

| Plugin Manager         | Command                                                                       |
|------------------------|-------------------------------------------------------------------------------|
| [NeoBundle][neobundle] | `NeoBundle 'liquidfun/vim-comment-banners.vim'`                                              |
| [Vundle][vundle]       | `Bundle 'liquidfun/vim-comment-banners.vim'`                                                 |
| [Vim-plug][vim-plug]   | `Plug 'liquidfun/vim-comment-banners.vim'`                                                   |
| [Pathogen][pathogen]   | `git clone git://github.com/liquidfun/vim-comment-banners.vim.git ~/.vim/bundle/commentbanners.vim` |


[neobundle]: https://github.com/Shougo/neobundle.vim
[vundle]: https://github.com/gmarik/vundle
[vim-plug]: https://github.com/junegunn/vim-plug
[pathogen]: https://github.com/tpope/vim-pathogen

## About

Author: LiquidFun https://github.com/liquidfun
Repository: https://github.com/liquidfun/vim-comment-banners
License: same license as Vim
