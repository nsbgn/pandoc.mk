snel
==============================================================================

`snel` is a [lightweight](http://idlewords.com/talks/website_obesity.htm) 
template for [Hugo](http://gohugo.io/).

It is monochrome and very basic. Its most distinguishing quality is that the 
table of contents extends horizontally, and that all its entries are visible 
without further tapping, hovering or sliding, since it is supposed to act as a 
vantage point. 

The accompanying makefile generates some additional files via software outside 
the Hugo ecosystem. As of now, the recipe calls for [hugo](http://gohugo.io/),
[sass](http://sass-lang.com/),
[svgo](https://github.com/svg/svgo),
[ImageMagick](http://www.imagemagick.org/) and
[lftp](http://lftp.yar.ru/).

To include the theme into your git-managed website, [add it as a 
submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules):
    
    git submodule add https://github.com/slakkenhuis/snel.git themes/snel

To also make use of the makefile recipes, simply include the makefile into 
your own:

    SRC=/path/to/hugo/content
    DEST=/path/to/hugo/destination
    USER=ftp_username
    HOST=ftp_host
    REMOTE=ftp_directory
    include themes/snel/makefile

(Note that other branches of the `snel` repository achieve a similar thing 
using [Pandoc](http://pandoc.org/).)



License
------------------------------------------------------------------------------

The font referenced in the stylesheet is [Crimson
Text](https://github.com/skosch/Crimson), which is available under the
[Open Font License](http://scripts.sil.org/cms/scripts/page.php?id=OFL).

To the greatest possible extent, I dedicate all other content in this
repository to the [public domain](https://unlicense.org/) (see the
`UNLICENSE` file).

