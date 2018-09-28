snel
==============================================================================

`snel` is a [lightweight](http://idlewords.com/talks/website_obesity.htm) 
template for [Hugo](http://gohugo.io/).

It is monochrome and very basic. Its most distinguishing quality is that the 
table of contents extends horizontally, and that all its entries are visible 
without further tapping, hovering or sliding, since it is supposed to act as a 
vantage point. 

The accompanying makefile generates some files via software outside the Hugo 
ecosystem. As of now, the recipe calls for [hugo](http://gohugo.io/),
[sass](http://sass-lang.com/),
[svgo](https://github.com/svg/svgo),
[ImageMagick](http://www.imagemagick.org/) and
[lftp](http://lftp.yar.ru/) — but you could easily substitute or add any 
ingredient.

Executing `make` will generate a `build/` directory. To use with your own 
project, simply create a `makefile` with the following lines:

    SRC=/path/to/sources
    DEST=/path/to/build
    USER=ftp_username
    HOST=ftp_host
    REMOTE=ftp_directory
    include /path/to/snel/makefile

Note that other branches of the `snel` repository achieve the same thing fully 
outside the Hugo ecosystem.



License
------------------------------------------------------------------------------

The font referenced in the stylesheet is [Crimson
Text](https://github.com/skosch/Crimson), which is available under the
[Open Font License](http://scripts.sil.org/cms/scripts/page.php?id=OFL).

To the greatest possible extent, I dedicate all other content in this
repository to the [public domain](https://unlicense.org/) (see the
`UNLICENSE` file).

