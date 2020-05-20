################################################
############# Configuration ####################
################################################

# You probably don't need or want to configure anything, but if you
# must do all configuration in this file:
-include Makefile.config

# There are two options for specifying the documents to be compiled:

# 1. Specify the files in COMPILED_DOCUMENTS.

# 2. As a short-cut, if you define "%!TEX root = " in your tex files, then
#    you don't need to define anything at all.

# If you use the subdocument package, then this Makefile will
# automatically extract all subdocuments from all COMPILED_DOCUMENTS.
# You can also request rebuilds manually, e.g.
#       make some_subdocument.pdf

COMPILED_DOCUMENTS=thesis.pdf

###
### A few config options that you might want to touch, but probably
### don't need to.
###

#
# This variable should just be the executable name, possibly with path
# if necessary.  Don't put any command-line parameters here.
#
# Instead of putting command-line parameters here, please configure
# latexmk by editing your latexmkrc file.
#
LATEXMK?=latexmk

# This Makefile gracefully handles missing rubber-info and pdftk.  You
# should need to change these only if you have rubber-info and/or
# pdftk, but they aren't in your shell's path.
RUBBER_PATH?=$(shell which rubber-info)
PDFTK_PATH?=$(shell which pdftk)

# If you use tikzexternalize to dump pgfplots into a subdirectory,
# list that subdirectory here, and this Makefile will create and
# clean up the directory for you.
PGFPLOTSDIR?=pgfplots

# If you use search_cite.py, set these and this Makefile will clean
# them up when you invoked "make dblp-clean".
#DBLP_PAPERS_BIB?=dblp-papers.bib
#DBLP_PAPERS_CLEANED_BIB?=dblp-papers-cleaned.bib
#DBLP_CONFERENCES_BIB?=dblp-conferences.bib

# Where to store latexmk's dependency info.  You SHOULD NOT add
# this directory to your version control repository.
DEPS_DIR?=.deps

# Set this if you want make to remember what it builds so "make clean"
# will work auto-magically.  You SHOULD NOT add this directory to
# your version control system.
BUILDINFO_DIR?=.build_info


####
#### You shouldn't need to modify anything below here unless you are
#### adding new functionality to this Makefile.
####

##########################################################
############# Command-line processing ####################
##########################################################

# Enable Latexmk's "continuous" mode.  Note that this does not watch
# files that need to be processed by make.
ifndef PVC
ifdef CONT
	PVC=-pvc
else
	PVC=
endif
endif

# Verbosity options

ifndef V
	V=0
endif

# This silences lots of output unless you specify V=1
ifeq ($(V),0)
	QT=@printf "%-50s\n"
	QC=@
	QO=> /dev/null
	QE=2> /dev/null
	MS=-s
else
	QT=@printf "%-50s\n"
	QC=
	QO=
	QE=
	MS=
endif

PCMD=$(QC) $(QO) $(QE)

##########################################################
############ Inferring COMPILED_DOCUMENTS ################
##########################################################

# If no COMPILED_DOCUMENTS are specified, infer them from "TEX root" comments in the sources
COMPILED_DOCUMENTS?=$(shell grep -n "%\![[:space:]]*TEX[[:space:]]*root[[:space:]]*=" *.tex | cut -f2 -d= | sed "s/^[[:space:]]*//" | sed "s/[[:space:]]*$$//" | sort | uniq | sed "s/.tex/.pdf/")

ifeq ($(COMPILED_DOCUMENTS),)
  $(error COMPILED_DOCUMENTS is undefined.)
endif

all: all-subdocuments

#####################################################################
########### Extract dependencies and build pdfs using latexmk #######
#####################################################################

# The "-use-make" flag causes latexmk to invoke "make" for any missing
# files.  However, this isn't enough.  If, for example, diagram.pdf is
# built from diagram.svg, then latexmk will correctly invoke "make"
# the first time it detects that diagram.pdf is missing.  However,
# future runs of latexmk will not invoke "make" again, since
# diagram.pdf is no longer missing.  Thus, even if you edit
# diagram.svg, latexmk will not invoke "make" to rebuild diagram.pdf.
# This Makefile solves that problem by having latexmk output a list of
# dependencies for your paper and then re-running "make" at the
# top-level, with all those dependencies loaded into "make", so that
# all input files are rebuilt as necessary.

LATEXMK_BUILDOPTS=-use-make -interaction=nonstopmode

# Detect whether rubber-info is available
ifeq ($(RUBBER_PATH),)
	RUBBER_INFO=echo > /dev/null
else
	RUBBER_INFO=rubber-info
endif

$(DEPS_DIR):
	mkdir $@

# How to compute dependencies.
$(DEPS_DIR)/%.pdfP: %.tex $(DEPS_DIR) $(PGFPLOTSDIR) $(if $(DONTRECURSE),,FORCE)
	$(QT) "COMPUTING DEPENDENCIES AND PERFORMING INITIAL COMPILATION OF $<"
# Silence latexmk if we have rubber-info
	$(if $(RUBBER_PATH),$(PCMD)) $(LATEXMK) $(LATEXMK_BUILDOPTS) -f -recorder -deps -deps-out=$@ $<
	@echo
	@$(RUBBER_INFO) --check $<
	@if [ -f $*.scl ]; then cat $*.scl; fi
	@if [ -f $*.bcl ]; then cat $*.bcl; fi
	@echo

# Use above to compute dependencies.  Then call "make" recursively so
# those dependencies get loaded.  The recursive call actually builds
# the pdf file.

ifndef DONTRECURSE

# compute dependencies and recurse
%.pdf: $(DEPS_DIR)/%.pdfP 
	$(QT) "LOADING DEPENDENCIES AND REBUILDING (IF NECESSARY) $@"
	make $(MS) PVC=$(PVC) DONTRECURSE=1 V=$(V) $@

else

# Use the dependencies we've already computed to build the file
$(foreach file,$(COMPILED_DOCUMENTS),$(eval -include $(DEPS_DIR)/$(file)P))

%.pdf: %.tex $(PGFPLOTSDIR) $(if $(PVC),FORCE) 
# Silence latexmk if we have rubber-info and we're not in continuous mode
	$(if $(RUBBER_PATH),$(if $(PVC),,$(PCMD))) $(LATEXMK) $(LATEXMK_BUILDOPTS) $(PVC) $<
	@echo
	@$(RUBBER_INFO) --check $<
	@if [ -f $*.scl ]; then cat $*.scl; fi
	@if [ -f $*.bcl ]; then cat $*.bcl; fi
	@echo

endif

.PRECIOUS: $(COMPILED_DOCUMENTS)

#######################################
####### tikz externalize support ######
#######################################

ifdef PGFPLOTSDIR
$(PGFPLOTSDIR):
	mkdir $@
endif

#####################################
######## Automatic cleanups #########
#####################################

ifdef BUILDINFO_DIR
$(shell if [ ! -d $(BUILDINFO_DIR) ]; then mkdir $(BUILDINFO_DIR); fi)
record_build=$(shell echo $(1) > $(BUILDINFO_DIR)/`echo $(1) | md5sum | cut -f1 -d" "`)
buildinfo_files=$(wildcard $(BUILDINFO_DIR)/*)
else
record_build=$(shell exit 0)
endif

clean:
	$(LATEXMK) -C $(COMPILED_DOCUMENTS:.pdf=.tex)
ifdef BUILDINFO_DIR
	for i in $(buildinfo_files); do rm `cat $$i`; done
	rm -rf $(BUILDINFO_DIR)
endif

pgfplots-clean: clean
	rm -f $(COMPILED_DOCUMENTS:.pdf=.auxlock) $(COMPILED_DOCUMENTS:.pdf=.figlist) $(COMPILED_DOCUMENTS:.pdf=.makefile)
	rm -rf $(PGFPLOTSDIR)

deps-clean: clean
	rm -rf $(DEPS_DIR)

dblp-clean: clean
	rm -f $(DBLP_PAPERS_BIB) $(DBLP_CONFERENCES_BIB)

all-clean: clean pgfplots-clean dblp-clean deps-clean

#####################################################################
######## Rules for converting various figure formats to pdf #########
#####################################################################

%.pdf: %.ipe
	ipetoipe -pdf $<
	$(call record_build, $@)

%.pdf_tex: %.svg
	inkscape -A $(@:.pdf_tex=.pdf) --export-latex $<
	$(call record_build, $@)
	$(call record_build, $(@:.pdf_tex=.pdf))

%.pdf: %.svg
	inkscape -A $@ $<
	$(call record_build, $@)

%.pdf: %.dia
	dia --nosplash -e $(@:.pdf=.eps) $(@:.pdf=.dia) 
	epstopdf $(@:.pdf=.eps)
	$(call record_build, $@)
	$(call record_build, $(@:.pdf=.eps))

%.pdf: %.fig
	fig2dev -L pdftex $< $@
	$(call record_build, $@)

%.pdf_t: %.fig %.pdf
	fig2dev -L pdftex_t -p $(@:.pdf_t=.pdf) $< $@
	$(call record_build, $@)

%.pstex_t: %.fig
	fig2dev -L pstex_t -p $(@:.pstex_t=.pstex) $< $@
	fig2dev -L pstex $< $(@:.pstex_t=.pstex)
	$(call record_build, $@)
	$(call record_build, $(@:.pstex_t=.pstex)

%.pdf: %.txt
	enscript -Bo- $< | ps2pdf - $@
	$(call record_build, $@)

%.pdf: %.eps
	epstopdf $<
	$(call record_build, $@)

# Generate X.eps from X.dat and X.gnuplot.  Write your gnuplot file to match!
%.eps: %.gnuplot %.dat
	gnuplot $<	
	$(call record_build, $@)

%.eps: %.dia
	dia --nosplash -e $@ $< 
	$(call record_build, $@)

# Required for the gnumeric rule
.SECONDEXPANSION: 

# Rule to generate "a__b.pdf" from sheet "b" in "a.gnumeric"
#
# Make graphs at 0x0 offset and 570xH in size. (Recommend golden ratio: 570x360)
# Include them with 
#    \includegraphics[clip, trim = 1.1in 5.65in 1.5in 1.75in]{a__b.pdf}
#                                        ^^^^^^
#                             adjust depending on height of image
ssbname=$(shell echo $(1) | sed "s/__.*//g")
sssname=$(shell echo $(1) | sed "s/.*__//g")
%.pdf: $$(call ssbname,$$*).gnumeric
	ssconvert -O sheet=$(call sssname,$*) $< $@
	$(call record_build, $@)

######################################################################
####### Derive SUBDOCUMENTS from COMPILED_DOCUMENTS using pdftk ######
######################################################################

# Figure out which COMPILED_DOCUMENT a subdocument lives in
$(DEPS_DIR)/%.pdfSD: $(COMPILED_DOCUMENTS) $(DEPS_DIR)
	$(PCMD) bash -c \
  "for i in $(COMPILED_DOCUMENTS); do \
    $(PDFTK_PATH) \$$i dump_data | grep \"BookmarkTitle: $(*F)_pages=\" > /dev/null; \
    if [ \$$? -eq 0 ]; then \
      echo \$$i > $@; \
      exit 0; \
    fi; \
  done; \
  exit 1"

# Figure out the page range of a subdocument within its compiled document
$(DEPS_DIR)/%.pdfSP: $(DEPS_DIR)/%.pdfSD $(DEPS_DIR)
	$(PCMD) $(PDFTK_PATH) `cat $<` dump_data | grep "BookmarkTitle: $(*F)_pages=" | cut -f2 -d= > $(@)

# Note: you really want this rulle to be last, since it declares a
# generic fallback rule for producing pdf files.

%.pdf: $(COMPILED_DOCUMENTS) $(DEPS_DIR)/%.pdfSD $(DEPS_DIR)/%.pdfSP
	$(QT) "EXTRACTING SUBDOCUMENT $@"
	$(PCMD) $(PDFTK_PATH) `cat $(DEPS_DIR)/$(@:.pdf=.pdfSD)` cat `cat $(DEPS_DIR)/$(@:.pdf=.pdfSP)` output $@
	$(call record_build, $@)


ifndef DONTRECURSE

all-subdocuments: $(COMPILED_DOCUMENTS)
ifeq ($(PDFTK_PATH),)
	$(QT) "NOT EXTRACTING SUBDOCUMENTS (IF ANY) FROM $(COMPILED_DOCUMENTS) DUE TO MISSING PDFTK"
else
	$(QT) "EXTRACTING SUBDOCUMENTS (IF ANY) FROM $(COMPILED_DOCUMENTS)"
	make $(MS) DONTRECURSE=1 V=$(V) all-subdocuments
endif

else


ifeq ($(PDFTK_PATH),)
all_subdocuments=
else
all_subdocuments= \
  $(foreach doc, $(COMPILED_DOCUMENTS), \
            $(shell if [ -f $(doc) ]; then \
                      for i in \
                      `$(PDFTK_PATH) $(doc) dump_data | grep "BookmarkTitle: .*_pages=.*-.*" | \
                       sed "s/BookmarkTitle: \(.*\)_pages=.*/\1/"`; \
                       do \
                         echo $${i}.pdf; \
                       done; \
                    fi \
            )\
  )
endif

all-subdocuments: $(all_subdocuments)

.PRECIOUS: $(all_subdocuments)

endif

##################################
###### Miscellaneous items #######
##################################

FORCE:

help:
	@echo "This Makefile has a few flags:"
	@echo "   make V=1      Enables verbose mode"
	@echo "   make CONT=1   Enables latexmk continuous mode"
	@echo ""
	@echo "Targets of interest"
	@echo "make all (the default)"
	@echo "  makes everything, including extracting any subdocuments"
	@echo "  defined using the subdocument latex package in any of your "
	@echo "  COMPILED_DOCUMENTS"
	@echo "make <document-or-some-subdocument.pdf>"
	@echo "  Rebuild a particular document or sub-dcoument."
	@echo "make <any-other-particular-target>"
	@echo "  Rebuild a particular target (e.g. regenerate a figure), "
	@echo "  assuming rules are available."
	@echo "make clean"
	@echo "  Removes files built by latexmk or this Makefile."
	@echo "  See BUILDINFO_DIR below."
	@echo "make dblp-clean"
	@echo "  Also removes dblp files from search_cite.py" 
	@echo "  See DBLP variables below."
	@echo "make pgfplots-clean"
	@echo "  Also removes figures in your PGFPLOTSDIR"
	@echo "  See PGFPLOTSDIR below."
	@echo "make deps-clean"
	@echo "  Also removes latexmk's dependency information"
	@echo "make all-clean"
	@echo "  All of the above"
	@echo ""
	@echo "To configure this Makefile"
	@echo ""
	@echo "1. Define COMPILED_DOCUMENTS at the top of the Makefile, e.g."
	@echo "        COMPILED_DOCUMENTS=paper.pdf other_paper.pdf"
	@echo "or"
	@echo "2. Put "
	@echo "      %!TEX root = paper.tex"
	@echo "   in your .tex files, and this Makefile will figure it out."
	@echo ""
	@echo "Other variables of interest"
	@echo "PGFPLOTSDIR: if you use tikzexternalize to dump all your pgfplots "
	@echo "             into a subdirectory, then set this variable to "
	@echo "             that subdirectory so this Makefile can clean up"
	@echo "             that subdirectory for you when you do "
	@echo "                 make pgfplots-clean"
	@echo "             Its ok to set this variable even if you don't use "
	@echo "             tikzexternalize."
	@echo "DBLP_PAPERS_BIB:"
	@echo "DBLP_CONFERENCES_BIB:"
	@echo "             If you use search_cite.py from your latexmkrc, then "
	@echo "             set these variables so this Makefile can clean them up"
	@echo "             in \"make dblp-clean\""
	@echo "BUILDINFO_DIR: This Makefile can automatically remember the things it"
	@echo "               builds and then delete them when you do"
	@echo "                      make clean"
	@echo "               Unset this variable if you don't want that behavior."

