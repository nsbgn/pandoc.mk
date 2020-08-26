snel
==============================================================================

Plain text formats like [Markdown](http://commonmark.org/help/) and 
[YAML](http://www.yaml.org/spec/) are lightweight, understandable, and easy to 
modify. In the spirit of the [UNIX 
philosophy](https://en.wikipedia.org/wiki/Unix_philosophy), I glued a couple 
of standard tools into `snel`, a method for generating documents and static 
websites. The method encourages a radical separation of style from content: 
source text and data are converted to documents and graphs by a clean and 
transparent process, documented in the Makefile. It provides a common base for 
all prose-heavy projects --- be it a thesis, a resume or a website.

This repository consists of two parts, both of which, I hope, may prove useful 
to someone:

1.  Recipes for [make](https://www.gnu.org/software/make).

2.  Minimalist CSS stylesheets.

As of now, the core recipes call for [pandoc](http://pandoc.org/), 
[jq](https://stedolan.github.io/jq/), [weasyprint](https://weasyprint.org/), 
[sass](http://sass-lang.com/) and 
[find](https://www.gnu.org/software/findutils/) --- but you could substitute 
or add any ingredient. 
 
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

To use `snel`, create a directory with Markdown files like this:

    ---
    title: An example.
    make: [html, pdf]
    style: article
    ---

    Consider this graph: ![](graph.svg)

Then create a `Makefile` with at least the following content:

    include snel.mk

This will import recipes to make PDF and HTML documents corresponding to all 
Markdown files (given the appropriate value for `make` in the metadata). An 
index page will be created that links to them all. To start generating, just 
run `make`.

This will also attempt to automatically create any local resource that the 
source files link to. If there is no recipe for a particular resource, simply 
add it to your `Makefile`. For the above example, that could be:

    $(DEST)/graph.svg: $(SRC)/data.dat
        echo 'set terminal svg; set output "$@"; plot "$<"' | gnuplot

To clean up leftovers files in the `build/` directory that are no longer 
linked, do `make clean`. With the proper configuration, the results can be 
uploaded with [lftp](http://lftp.yar.ru/) or [rsync](https://rsync.samba.org/) 
by calling `make upload`.

See installation directions [here](INSTALL.md). For configuration, consult the 
files in the `include/` directory.


License
------------------------------------------------------------------------------

To the greatest possible extent, I dedicate all content in this
repository to the [public domain](https://unlicense.org/) (see the
`UNLICENSE` file).

