pandoc.mk
==============================================================================

Plain text formats like [Markdown](http://commonmark.org/help/) and 
[YAML](http://www.yaml.org/spec/) are lightweight, understandable, 
maintainable in version control, and easy to modify. In the spirit of the 
[UNIX philosophy](https://en.wikipedia.org/wiki/Unix_philosophy), I glued a 
couple of common tools into `pandoc.mk`, a method for generating documents and 
static websites. The method encourages a radical separation of style from 
content: source text & data are converted to documents & images by a clean and 
transparent process, documented in a `Makefile`. It provides a common base and 
a consistent style for text projects — be it a thesis, a website, a resume…

The repository consists of two parts, either of which, I hope, may prove 
useful to someone:

1.  Recipes for [make](https://www.gnu.org/software/make). As of now, the core 
    recipes call for [pandoc](http://pandoc.org/), 
    [jq](https://stedolan.github.io/jq/) and
    [find](https://www.gnu.org/software/findutils/) — and you could easily 
    substitute or add ingredients. 

2.  Minimalist CSS stylesheets, compiled with [sass](http://sass-lang.com/). 
    Change them to fit your tastes.
 

Usage
-------------------------------------------------------------------------------

To use `pandoc.mk`, fill a directory with Markdown files like this:

    ---
    title: An example.
    make: [html, pdf]
    style: article
    ---

    Consider this graph: ![](graph.svg)

Then, create a `Makefile` with the following content:

    include pandoc.mk pandoc-html.mk pandoc-pdf.mk

The first import will set PDF and HTML targets for corresponding files in the 
source directory. Documents without an appropriate value for `make` in the 
metadata will be ignored. The other imports will add default recipes to 
actually *make* those PDF and HTML targets.

Local resources that are *linked to* by the source documents, are also 
automatically targeted. If there is no recipe for a particular resource, add 
it to your `Makefile`. For the above example, that could be:

    $(DEST)/graph.svg: $(SRC)/data.dat
        echo 'set terminal svg; set output "$@"; plot "$<"' | gnuplot

To start generating, run `make`. To remove obsoleted files of a previous run 
from the `build/` directory, do `make clean`. With the proper configuration, 
the results can be uploaded with [lftp](http://lftp.yar.ru/) or 
[rsync](https://rsync.samba.org/) by calling `make upload`.

See installation directions at the [`INSTALL.md`](INSTALL.md). For 
configuration, consult the files in the [`include/`](include/) directory.


Similar software
-------------------------------------------------------------------------------

Projects that take a similar bare-bones approach to website generation are 
[simple-template](https://github.com/simple-template/pandoc) and
[jqt](https://fadado.github.io/jqt/). Should this be a bit primitive for your 
tastes, try static website generators such as 
[zola](https://www.getzola.org/), [hugo](http://gohugo.io/), 
[hakyll](https://jaspervdj.be/hakyll/about.html),
[jekyll](http://jekyllrb.com/), [nanoc](https://nanoc.ws/), 
[yst](https://github.com/jgm/yst) or [middleman](https://middlemanapp.com/). 


License
------------------------------------------------------------------------------

To the greatest possible extent, I dedicate all content in this
repository to the [public domain](https://unlicense.org/) (see 
[`UNLICENSE.md`](UNLICENSE.md)).

