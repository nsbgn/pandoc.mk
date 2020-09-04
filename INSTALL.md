Installation
===============================================================================

To use `pandoc.mk`, clone it:

    git clone https://github.com/slakkenhuis/pandoc.mk

To install it globally, then do:

    cd pandoc.mk && sudo make install

Include the appropriate `pandoc*.mk` files into your project's `Makefile` and 
you are good to go. However, you don't *need* to install it globally; the 
recipes will work just fine if you `include /path/to/pandoc.mk` instead.


Dependencies
-------------------------------------------------------------------------------

`pandoc.mk` really doesn't consist of much more than a make-recipe and some 
styles. Most of the software that its recipes call for is rather common and 
probably already installed on your computer. For the basic documents and the 
index, just make sure that you have [pandoc](http://pandoc.org/) >=2.8, 
[jq](https://stedolan.github.io/jq/) >=1.6,
[weasyprint](https://weasyprint.org/) and [sassc](http://sass-lang.com/) (or 
change the recipes). On Debian-based systems, this should suffice:

    sudo apt install \
        make sed grep findutils \
        jq pandoc pandoc-citeproc \
        weasyprint ghostscript sassc 

Optional additional recipes use such programs as 
[ImageMagick](http://www.imagemagick.org/),
[optipng](http://optipng.sourceforge.net/), and
[svgo](https://github.com/svg/svgo) for image processing, as well as
[lftp](http://lftp.yar.ru/) or 
[rsync](https://rsync.samba.org/)+[ssh](http://www.openssh.com/) for 
uploading. 

    sudo apt install \
        rsync ssh lftp \
        imagemagick libimage-exiftool-perl optipng

However, note that:

-   We need `pandoc` >=2.8, because we are using Lua filters and template 
    partials. This version is not necessarily available in all repositories, 
    so get the latest release 
    [here](https://github.com/jgm/pandoc/releases/latest) if it's not.

-   `jq` needs to be at version >=1.6 to avoid an "invalid path expression" 
    error. If it is not available in your repositories, grab it 
    [here](https://github.com/stedolan/jq/releases/latest).

-   `weasyprint` is not yet available everywhere. Substitute with 
    [wkhtmltopdf](https://wkhtmltopdf.org/) or install it with pip instead:

        pip3 install weasyprint

-   Unfortunately, `svgo` is a node.js tool. Install it with npm:

        npm install -g svgo

