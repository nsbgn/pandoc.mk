snel
==============================================================================

Plain text formats like [Markdown](http://commonmark.org/help/) and 
[YAML](http://www.yaml.org/spec/) are lightweight, understandable, and easy to 
modify. In the spirit of the [UNIX 
philosophy](https://en.wikipedia.org/wiki/Unix_philosophy), I glued a couple 
of standard tools into `snel`, a method for generating PDF documents and 
static websites. The method encourages a radical separation of style from 
content: source text and data are converted to documents and graphs by a clean 
and transparent process, documented in the Makefile.

This repository consists of two parts, both of which, I hope, may prove useful 
to someone:

1.  Recipes for [make](https://www.gnu.org/software/make).

2.  Minimalist CSS stylesheets.

As of now, the core recipes call for [pandoc](http://pandoc.org/) 2.8 or 
higher, [jq](https://stedolan.github.io/jq/) 1.6 or higher,
[weasyprint](https://weasyprint.org/),
[find](https://www.gnu.org/software/findutils/), 
[tree](http://mama.indstate.edu/users/ice/tree/),
[sass](http://sass-lang.com/), and
[xargs](https://savannah.gnu.org/projects/findutils/) --- but you could easily 
substitute or add any ingredient. Optional additional recipes use such 
programs as [ImageMagick](http://www.imagemagick.org/),
[optipng](http://optipng.sourceforge.net/), and
[svgo](https://github.com/svg/svgo) for image processing, as well as
[lftp](http://lftp.yar.ru/) or 
[rsync](https://rsync.samba.org/)+[ssh](http://www.openssh.com/) for 
uploading. 
 
Website generators that take a similar bare-bones approach are 
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
create a `Makefile` with at least the following content:

    include snel.mk # or "/path/to/snel.mk", when not installed globally

Then, executing `make` will generate the `$(DEST)` (default: `build`) 
directory containing HTML and PDF files --- that is, if you have populated the 
`$(SRC)` (default: `.`) directory with Markdown files such as these:

    ---
    title: An example.
    make: [html, pdf]
    style: article
    ---

    Consider this graph: ![](graph.svg)

Markdown files without a `make` entry in the metadata will be ignored. `snel` 
will also attempt to automatically build any resource the Markdown files link 
to. If there is no recipe for a particular resource, simply add it to your 
`Makefile`. Example:

    $(DEST)/%/graph.svg: $(SRC)/%/data.dat script.gnuplot
        gnuplot -c script.gnuplot $<

To clean up leftovers files that are no longer linked, do `make clean`. Given 
an appropriate configuration, the results can be uploaded by calling `make 
upload`.


License
------------------------------------------------------------------------------

To the greatest possible extent, I dedicate all content in this
repository to the [public domain](https://unlicense.org/) (see the
`UNLICENSE` file).

