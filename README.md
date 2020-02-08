snel
==============================================================================

`snel` is the [lightweight](http://idlewords.com/talks/website_obesity.htm) 
template and a static website generator that I use for my personal website. It 
is currently a work-in-progress, but it is mostly functional. It roughly 
consists of two parts, either of which, I hope, may prove useful to someone:

1.  A `Makefile`, to create the pages and an index file.

2.  A minimalist stylesheet and a logo.

To install `snel`, do `make install`. To then use it with your own project, 
simply create a `Makefile` with the following lines:

    SRC=/path/to/sources
    DEST=/path/to/build
    USER=ftp_username
    HOST=ftp_host
    REMOTE=ftp_directory
    include snel.mk

Executing `make` from there will then generate a `build/` directory containing 
a website made from Markdown files found in the `$(SRC)` directory. 

Site generators that take a similar approach are 
[simple-template](https://github.com/simple-template/pandoc), 
[jqt](https://fadado.github.io/jqt/) and 
[pansite](https://github.com/wcaleb/website). Should this be a bit primitive 
for your tastes, try other static website generators such as 
[zola](https://www.getzola.org/), [hugo](http://gohugo.io/), 
[hakyll](https://jaspervdj.be/hakyll/about.html),
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

As of now, the recipe calls for [pandoc](http://pandoc.org/) 2.8 or higher, 
[jq](https://stedolan.github.io/jq/) 1.5 or higher,
[fd](https://github.com/sharkdp/fd),
[sass](http://sass-lang.com/),
[svgo](https://github.com/svg/svgo),
[ImageMagick](http://www.imagemagick.org/) and
[lftp](http://lftp.yar.ru/) — but you could easily substitute or add any 
ingredient.



Style
------------------------------------------------------------------------------

The theme is minimal and monochrome. Its most distinguishing quality is that 
the table of contents extends horizontally and that all its entries are 
visible without further tapping, hovering or sliding; it is supposed to act as 
a vantage point. The CSS is written using SASS.

It is also very suitable for use in PDF writing, as demonstrated in this 
[printer](https://github.com/slakkenhuis/scripts/printer) script.



License
------------------------------------------------------------------------------

To the greatest possible extent, I dedicate all content in this
repository to the [public domain](https://unlicense.org/) (see the
`UNLICENSE` file).

