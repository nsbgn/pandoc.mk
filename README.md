snel
==============================================================================

`snel` is the [lightweight](http://idlewords.com/talks/website_obesity.htm) 
template and a static website generator that I use for my personal website. It 
is currently a work-in-progress, but it is mostly functional. It roughly 
consists of two parts, each of which, I hope, may prove useful to someone:

1.  A simple makefile, to create documents and other resources.

2.  A logo and a minimalist style to present the above.


To install `snel`, do `make install`. To then use it with your own project, 
simply create a `Makefile` with the following lines:

    SRC=/path/to/sources
    DEST=/path/to/build
    USER=ftp_username
    HOST=ftp_host
    REMOTE=ftp_directory
    include snel.mk

Executing `make` will then generate a `build/` directory containing scripts, 
stylesheets and the example website. 

Site generators that take a similar approach are 
[simple-template](https://github.com/simple-template/pandoc), 
[jqt](https://fadado.github.io/jqt/) and 
[pansite](https://github.com/wcaleb/website). Should this be a bit primitive 
for your tastes, try other static website generators such as 
[hugo](http://gohugo.io/), [hakyll](https://jaspervdj.be/hakyll/about.html),
[jekyll](http://jekyllrb.com/), [nanoc](https://nanoc.ws/), 
[yst](https://github.com/jgm/yst) or [middleman](https://middlemanapp.com/). 




Makefile
------------------------------------------------------------------------------

Plain text formats like [Markdown](http://commonmark.org/help/) and 
[YAML](http://www.yaml.org/spec/) are lightweight, understandable, and 
modifiable. In the spirit of the [UNIX 
philosophy](https://en.wikipedia.org/wiki/Unix_philosophy), I glued a couple 
of standard tools into a [make](https://www.gnu.org/software/make)-recipe for 
website generation.

Using `fd` and `pandoc`, the `Makefile` creates an HTML file for every 
Markdown document it can find in the source directory. With `jq`, an index is 
generated directly from the folder structure and `pandoc` metadata. After all, 
the directory hierarchy is a simple and generic interface for organizing 
things. just like plain text. Given an appropriate configuration, the results 
are uploaded with `lftp` by calling `make upload`.

As of now, the recipe calls for [Pandoc](http://pandoc.org/) 2.8 or higher, 
[sass](http://sass-lang.com/),
[svgo](https://github.com/svg/svgo),
[ImageMagick](http://www.imagemagick.org/),
[jp2a](https://csl.name/jp2a/),
[lftp](http://lftp.yar.ru/) and
[fd](https://github.com/sharkdp/fd) — but you could easily substitute or add 
any ingredient.

Note that we use the partials of `pandoc`'s built-in templating system, which 
appeared in `doctemplates 0.3`. The version of `pandoc` in your distribution's 
repositories is probably not sufficient - in fact, neither is the latest 
upstream release, `pandoc 0.7.3` at the time of writing. You'll need the 
development version for now.

    git clone https://github.com/jgm/pandoc && \
    cd pandoc && \
    cabal install


Style
------------------------------------------------------------------------------

The theme is minimal and monochrome. Its most distinguishing quality is that 
the table of contents extends horizontally and that all its entries are 
visible without further tapping, hovering or sliding; it is supposed to act as 
a vantage point. The CSS is written using SASS.



License
------------------------------------------------------------------------------

The font referenced in the stylesheet is [Crimson
Text](https://github.com/skosch/Crimson), which is available under the
[Open Font License](http://scripts.sil.org/cms/scripts/page.php?id=OFL).

To the greatest possible extent, I dedicate all other content in this
repository to the [public domain](https://unlicense.org/) (see the
`UNLICENSE` file).

