snel
==============================================================================

`snel` can be used for static website generation and for document typesetting. 
It roughly consists of two parts, either of which, I hope, may prove useful to 
someone:

1.  A `Makefile`-recipe, to generate a website.

2.  A CSS stylesheet.

It is currently a work-in-progress, but it is mostly functional. Website 
generators that take a similar approach are 
[simple-template](https://github.com/simple-template/pandoc), 
[jqt](https://fadado.github.io/jqt/) and 
[pansite](https://github.com/wcaleb/website). Should this be a bit primitive 
for your tastes, try others such as [zola](https://www.getzola.org/), 
[hugo](http://gohugo.io/), [hakyll](https://jaspervdj.be/hakyll/about.html),
[jekyll](http://jekyllrb.com/), [nanoc](https://nanoc.ws/), 
[yst](https://github.com/jgm/yst) or [middleman](https://middlemanapp.com/). 


Usage
-------------------------------------------------------------------------------

To install `snel`, do `make install`. To generate a website, simply create a 
`Makefile` with the following lines:

    SRC=/path/to/sources
    DEST=/path/to/build
    include snel.mk

Executing `make` from there will then generate the `$(DEST)` directory 
containing a [lightweight](http://idlewords.com/talks/website_obesity.htm) 
website made from Markdown files found in the `$(SRC)` directory. 

To use the stylesheet to create a PDF, I suggest using the following options 
to Pandoc:

    pandoc --shift-heading-level-by=1 \
        --pdf-engine=weasyprint \
        --template "/usr/share/snel/pandoc/page.html" \
        --css "/usr/share/snel/style.css"

Rationale
-------------------------------------------------------------------------------

Plain text formats like [Markdown](http://commonmark.org/help/) and 
[YAML](http://www.yaml.org/spec/) are lightweight, understandable, and 
modifiable. In the spirit of the [UNIX 
philosophy](https://en.wikipedia.org/wiki/Unix_philosophy), I glued a couple 
of standard tools into a [make](https://www.gnu.org/software/make)-recipe for 
website generation.

Using `fd` and `pandoc`, the `Makefile` creates an HTML file for every 
Markdown document it can find in the source directory. With `jq`, an index is 
generated directly from the directory structure and `pandoc` metadata. Given 
an appropriate configuration, the results can be uploaded with `lftp` by 
calling `make upload`.

As of now, the recipe calls for [pandoc](http://pandoc.org/) 2.8 or higher, 
[jq](https://stedolan.github.io/jq/) 1.5 or higher,
[find](https://www.gnu.org/software/findutils/),
[tree](http://mama.indstate.edu/users/ice/tree/),
[sass](http://sass-lang.com/),
[svgo](https://github.com/svg/svgo),
[ImageMagick](http://www.imagemagick.org/) and
[lftp](http://lftp.yar.ru/) — but you could easily substitute or add any 
ingredient.


### Style

The stylesheet is minimal and monochrome. It is very suitable for use in PDF 
typesetting, as demonstrated
[here](https://github.com/slakkenhuis/scripts/blob/master/printer). For 
websites, its most distinguishing quality is that the table of contents 
extends horizontally and that all its entries are visible without further 
tapping, hovering or sliding; it is supposed to act as a vantage point.


License
------------------------------------------------------------------------------

To the greatest possible extent, I dedicate all content in this
repository to the [public domain](https://unlicense.org/) (see the
`UNLICENSE` file).

