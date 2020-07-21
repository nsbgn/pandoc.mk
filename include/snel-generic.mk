# This adds generic recipes for images and other things that you might often
# link to.

# Favicon as bitmap
$(DEST)/favicon.ico: $(SRC)/favicon.svg
	@-mkdir -p $(@D)
	convert $< -transparent white -resize 16x16 -level '0%,100%,0.6' $@

# Icon for bookmark on Apple devices
$(DEST)/apple-touch-icon.png: $(SRC)/favicon.svg
	@-mkdir -p $(@D)
	convert -density 1200 -resize 140x140 -gravity center -extent 180x180 \
	    	+level-colors '#fff,#711' -colors 16 \
		-compress Zip -define 'png:format=png8' -define 'png:compression-level=9' \
		$< $@

# SVG gets optimized.
$(DEST)/%.svg: $(SRC)/%.svg
	@-mkdir -p $(@D)
	svgo --input=$< --output=$@

# Dithered PNG
$(DEST)/%.dither.png: $(SRC)/%.jpg
	@-mkdir -p $(@D)
	convert $< \
		-resize '600x' \
		-dither FloydSteinberg \
		-colorspace gray \
		-colors 8 \
		-normalize \
		-define png:color-type=3 \
        -define png:compression-level=9  \
		-define png:format=png8 \
		-strip \
		$@
	optipng $@
	@echo "Original size $$(ls -sh $< | cut -d' ' -f1)."
	@echo "Compressed to $$(ls -sh $@ | cut -d' ' -f1)."

# Dithered GIF
$(DEST)/%.dither.gif: $(SRC)/%.jpg
	@-mkdir -p $(@D)
	convert $< \
		-resize '400x' \
		-colorspace gray \
		-colors 12 \
		-normalize \
		-dither FloydSteinberg \
		-strip \
		$@
	@echo "Original size $$(ls -sh $< | cut -d' ' -f1)."
	@echo "Compressed to $$(ls -sh $@ | cut -d' ' -f1)."

# Smaller JPG file
$(DEST)/%.small.jpg: $(SRC)/%.jpg
	@-mkdir -p $(@D)
	convert  $< \
		-resize '600x' \
		-quality '60%' \
		$@
	@echo "Original size $$(ls -sh $< | cut -d' ' -f1)."
	@echo "Compressed to $$(ls -sh $@ | cut -d' ' -f1)."

# Any file in the source is also available at the destination
$(DEST)/%: $(SRC)/%
	@-mkdir -p $(@D)
	-ln -s --relative $< $@
