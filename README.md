snel
==============================================================================

`snel` consists of two parts, either of which, I hope, may prove useful to 
someone:

1.  A [make](https://www.gnu.org/software/make)-recipe for generating a static 
    website and/or PDF documents.

2.  Minimalist, monochrome CSS stylesheets.


Plain text formats like [Markdown](http://commonmark.org/help/) and 
[YAML](http://www.yaml.org/spec/) are lightweight, understandable, and easy to 
modify. In the spirit of the [UNIX 
philosophy](https://en.wikipedia.org/wiki/Unix_philosophy), I glued a couple 
of standard tools into an application for static website generation and 
document typesetting.

As of now, the recipe calls for [pandoc](http://pandoc.org/) 2.8 or higher, 
[jq](https://stedolan.github.io/jq/) 1.6 or higher,
[find](https://www.gnu.org/software/findutils/),
[tree](http://mama.indstate.edu/users/ice/tree/),
[xargs](https://savannah.gnu.org/projects/findutils/),
[sass](http://sass-lang.com/),
[ImageMagick](http://www.imagemagick.org/),
[optipng](http://optipng.sourceforge.net/) and optionally
[lftp](http://lftp.yar.ru/),
[svgo](https://github.com/svg/svgo),
and [weasyprint](https://weasyprint.org/). These are mostly standard programs, 
and you could easily substitute or add any ingredient.

Website generators that take a similar approach are 
[simple-template](https://github.com/simple-template/pandoc), 
[jqt](https://fadado.github.io/jqt/) and 
[pansite](https://github.com/wcaleb/website). Should this be a bit primitive 
for your tastes, try others such as [zola](https://www.getzola.org/), 
[hugo](http://gohugo.io/), [hakyll](https://jaspervdj.be/hakyll/about.html),
[jekyll](http://jekyllrb.com/), [nanoc](https://nanoc.ws/), 
[yst](https://github.com/jgm/yst) or [middleman](https://middlemanapp.com/). 


Usage
-------------------------------------------------------------------------------

To install `snel` globally, do `make` and `sudo make install`. To use it, 
create a `Makefile` with content like this:

    SRC=/path/to/source/directory  # defaults to "."
    DEST=/path/to/build/directory  # defaults to "./build"
    include snel.mk  # or "/path/to/snel.mk", if it wasn't installed globally

Executing `make html` from there will then generate the `$(DEST)` directory 
containing a [lightweight](http://idlewords.com/talks/website_obesity.htm) 
website made from the Markdown files found in the `$(SRC)` directory. All 
entries in the created `index.html` are visible without further tapping, 
hovering or sliding --- it is supposed to act as a vantage point.

Alternatively, executing `make pdf` will use `weasyprint` to make PDF 
documents from those same Markdown files, with the same workflow.

`snel` will also attempt to automatically build any resource the Markdown 
files link to. If there is no recipe for a particular resource, simply add it 
to your `Makefile`. Example:

    $(DEST)/%/graph.jpg: $(SRC)/%/data.dat script
        gnuplot -c script $<

To clean up leftovers files that are no longer linked, do `make clean`. Given 
an appropriate configuration, the results can be uploaded with `lftp` or 
`rsync` & `ssh` by calling `make upload`.


License
------------------------------------------------------------------------------

To the greatest possible extent, I dedicate all content in this
repository to the [public domain](https://unlicense.org/) (see the
`UNLICENSE` file).

