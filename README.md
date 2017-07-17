snel
==============================================================================

`snel` is a [lightweight](http://idlewords.com/talks/website_obesity.htm) 
template and a static website generator. It is currently a work-in-progress, 
but it is mostly functional. It roughly consists of three parts, each of 
which, I hope, may prove useful to someone:

1.  A simple makefile, `snel.mk`, to create documents and other assets from 
    plain text sources.

2.  A Python script to generate a table of contents directly from the 
    directory structure. A small JavaScript can optionally show this overview 
    dynamically. 

3.  A minimalist theme to present the above in as clear and concise a way as 
    possible.

Simply execute `make` or `make -j` to generate a `build/` directory containing 
all scripts, stylesheets and the example website. 

To make `snel` available globally, do `sudo make install`. You can then simply 
`include snel.mk` from any other makefile to import all its recipes and 
variables. Among the variables you will want to set prior to including is 
probably at least `SRC`, the source directory.

Should `snel` be a bit primitive for your tastes, try 
[hugo](http://gohugo.io/), [hakyll](https://jaspervdj.be/hakyll/about.html),
[jekyll](http://jekyllrb.com/), [nanoc](https://nanoc.ws/), 
[yst](https://github.com/jgm/yst) or [middleman](https://middlemanapp.com/)!



Makefile
------------------------------------------------------------------------------

The most open format imaginable is plain text. It is lightweight, immediately 
understandable and readily modifiable. It is also easy to 
[process](https://en.wikipedia.org/wiki/Unix_philosophy) such files using 
standard tools, especially if you adhere to specifications like 
[Markdown](http://commonmark.org/help/) and [YAML](http://www.yaml.org/spec/).

It is in this spirit that I wrote a 
[make](https://www.gnu.org/software/make)-recipe to glue a couple of tools 
together into a website generator. As of now, the recipe calls for at least
[Pandoc](http://pandoc.org/) with 
[pandoc-citeproc](https://github.com/jgm/pandoc-citeproc),
[Panflute](https://github.com/sergiocorreia/panflute),
[Python](https://www.python.org/),
[Closure](https://developers.google.com/closure/compiler/).
[PhantomJS](https://phantomjs.org),
[less](http://lesscss.org/) with 
[clean-css](https://github.com/less/less-plugin-clean-css),
[svgo](https://github.com/svg/svgo),
[ImageMagick](http://www.imagemagick.org/),
[jp2a](https://csl.name/jp2a/),
[lftp](http://lftp.yar.ru/),
[rsync](https://rsync.samba.org/) and
[find](https://www.gnu.org/software/findutils/) --- but you could easily 
substitute any ingredient.

In short, the recipe `find`s Markdown documents under the source directory 
and, using `pandoc`, produces the corresponding HTML document under the 
destination directory. Note that, upon running `make` a second time, any image 
or other resource referenced in the source file will also be created at the 
destination, if a suitable recipe was found. With the appropriate 
configuration, the results can be uploaded by calling `make upload` (using 
`lftp` or `rsync`).



Index
------------------------------------------------------------------------------

For more or less the same reasons that I like plain text files, I like the 
folder hierarchy they are in. The `sitemap.py` script generates a site-wide 
table of contents directly from the directory structure.

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
a vantage point.

The CSS is written using `lessc` and minified with its `clean-css` plugin. The 
filters are made with `panflute`.

Note that citation styles can be found at
[CSL](https://github.com/citation-style-language/styles).



License
------------------------------------------------------------------------------

The font referenced in the stylesheet is [Crimson
Text](https://github.com/skosch/Crimson), which is available under the
[Open Font License](http://scripts.sil.org/cms/scripts/page.php?id=OFL).

To the greatest possible extent, I dedicate all other content in this
repository to the [public domain](https://unlicense.org/) (see the
`UNLICENSE` file).

