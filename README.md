snel
==============================================================================

Plain text formats like [Markdown](http://commonmark.org/help/) and 
[YAML](http://www.yaml.org/spec/) are lightweight, understandable, and easy to 
modify. In the spirit of the [UNIX 
philosophy](https://en.wikipedia.org/wiki/Unix_philosophy), I glued a couple 
of common tools into `snel`, a method for generating documents and static 
websites. The method encourages a radical separation of style from content: 
source text & data are converted to documents & graphs by a clean and 
transparent process, documented in a `Makefile`. It provides a common base and 
a consistent style for text projects — be it a thesis, a website, a resume…

The repository consists of two parts, either of which, I hope, may prove 
useful to someone:

1.  Recipes for [make](https://www.gnu.org/software/make). As of now, the core 
    recipes call for [pandoc](http://pandoc.org/), 
    [jq](https://stedolan.github.io/jq/), 
    [weasyprint](https://weasyprint.org/), [sass](http://sass-lang.com/) and 
    [find](https://www.gnu.org/software/findutils/) — but you could substitute 
    or add any ingredient. 

2.  Minimalist CSS stylesheets. Change them to fit your tastes.
 

Usage
-------------------------------------------------------------------------------

To use `snel`, fill a directory with Markdown files like this:

    ---
    title: An example.
    make: [html, pdf]
    style: article
    ---

    Consider this graph: ![](graph.svg)

Then, create a `Makefile` with at least the following content:

    include snel.mk

This will import recipes for corresponding PDF and HTML documents, plus an 
index page that links to them all. Files without an appropriate value for 
`make` in the metadata will be ignored. To start generating, just run `make`.

This will also attempt to automatically create any local resource that the 
source files link to. If there is no recipe for a particular resource, add it 
to your `Makefile`. For the above example, that could be:

    $(DEST)/graph.svg: $(SRC)/data.dat
        echo 'set terminal svg; set output "$@"; plot "$<"' | gnuplot

To remove obsolete files of a previous run from the `build/` directory, do 
`make clean`. With the proper configuration, the results can be uploaded with 
[lftp](http://lftp.yar.ru/) or [rsync](https://rsync.samba.org/) by calling 
`make upload`.

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

