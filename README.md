snel
==============================================================================

This branch contains a fancy JavaScript menu that brings up the table of 
contents instantly. While it is useful and it was a fun project, I would like 
the main branch to be even more static and primitive.

-------------------------------------------------------------------------------

`snel` is the [lightweight](http://idlewords.com/talks/website_obesity.htm) 
template and a static website generator that I use for my personal website. It 
is currently a work-in-progress, but it is mostly functional. It roughly 
consists of three parts, each of which, I hope, may prove useful to someone:

1.  A simple makefile, to create documents and other assets from plain text 
    sources.

2.  A Python script to generate a table of contents directly from the 
    directory structure. A small JavaScript can optionally show this overview 
    dynamically. 

3.  A logo and a minimalist style to present the above concisely.


Executing `make` will generate a `build/` directory containing scripts, 
stylesheets and the example website. To use with your own project, simply 
create a `makefile` with the following lines:

    SRC=/path/to/sources
    DEST=/path/to/build
    include /path_to_snel/makefile

Should this be a bit primitive for your tastes, try other static website 
generators such as [hugo](http://gohugo.io/), 
[hakyll](https://jaspervdj.be/hakyll/about.html),
[jekyll](http://jekyllrb.com/), [nanoc](https://nanoc.ws/), 
[yst](https://github.com/jgm/yst) or [middleman](https://middlemanapp.com/)!



Makefile
------------------------------------------------------------------------------

Plain text formats like [Markdown](http://commonmark.org/help/) and 
[YAML](http://www.yaml.org/spec/) are lightweight, understandable, and 
modifiable. I glued a couple of 
[standard](https://en.wikipedia.org/wiki/Unix_philosophy) tools into a 
[make](https://www.gnu.org/software/make)-recipe for website generation.

Using `pandoc`, it creates an HTML file for every Markdown document it can 
`find` in the source directory. Upon running `make` a second time, any 
resource referenced in the source file metadata will also be generated. With 
the appropriate configuration, the results can be uploaded by calling `make 
upload` (using `lftp` or `rsync`).

As of now, the recipe calls for at least
[Pandoc](http://pandoc.org/) 2.x with 
[pandoc-citeproc](https://github.com/jgm/pandoc-citeproc),
[Panflute](https://github.com/sergiocorreia/panflute),
[Python](https://www.python.org/),
[jq](https://stedolan.github.io/jq/),
[Closure](https://developers.google.com/closure/compiler/).
[PhantomJS](https://phantomjs.org),
[less](http://lesscss.org/) 2.7.1 with 
[clean-css](https://github.com/less/less-plugin-clean-css),
[svgo](https://github.com/svg/svgo),
[ImageMagick](http://www.imagemagick.org/),
[jp2a](https://csl.name/jp2a/),
[lftp](http://lftp.yar.ru/),
[rsync](https://rsync.samba.org/) and
[find](https://www.gnu.org/software/findutils/) --- but you could easily 
substitute any ingredient.


Index
------------------------------------------------------------------------------

The directory hierarchy is useful for much the same reason that plain text is 
useful. The `generate-index.py` script generates a site-wide table of contents 
directly from the folder structure.

The `index.js` script can then display this overview dynamically, so that it 
is always accessible without further HTTP requests (and so that it may allow 
interaction in the future). After minification with `closure-compiler`, this 
script weighs less than 2kB, and it has no dependencies. It is also completely 
optional, since a static fallback is created using `phantomjs`.



Style
------------------------------------------------------------------------------

The theme is kept simple and monochrome. Its most distinguishing quality is 
that the table of contents extends horizontally and that all its entries are 
visible without further tapping, hovering or sliding; it is supposed to act as 
a vantage point. The CSS is written using `lessc` and minified with its 
`clean-css` plugin. The filters are made with `panflute`.



License
------------------------------------------------------------------------------

The font referenced in the stylesheet is [Crimson
Text](https://github.com/skosch/Crimson), which is available under the
[Open Font License](http://scripts.sil.org/cms/scripts/page.php?id=OFL).

To the greatest possible extent, I dedicate all other content in this
repository to the [public domain](https://unlicense.org/) (see the
`UNLICENSE` file).

