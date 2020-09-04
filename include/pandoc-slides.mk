# This adds recipes for LaTeX beamer slides. This one is just easier than using
# the default PDF recipe with the `slides` style, for now.

$(DEST)/%slides.pdf: $(SRC)/%slides.md 
	@mkdir -p "$(@D)"
	@cd $(@D); pandoc -i $(shell realpath $< --relative-to $(@D)) -o $(@F) -t beamer

