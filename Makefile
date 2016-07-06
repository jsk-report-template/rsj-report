##################################################################
#
# LaTeX / PDFLaTeX Makefile
# (c) Tom Bobach
#
# Last Modified: 17. Jul 2007
#   Added 2-levels of recursion for include checks
#
# History:
#   9. May 2007     Initial Version
#
# Disclaimer:
#   Use at your own risk.
#   I take no responsibility for this Makefile eating up your most
#   precious work, teaching your baby bad language or evoking evil
#   ghosts.
#
# What happens:
#   The current directory is searched for a *.tex file containing
#   the string "\documentclass"; this will be the main file.
#   All files included in the main file via "\include" will be
#   added to the source files.
#   The source files are searched for occurences of strings of the
#   form "{figs/<name>}". For each <name> the first of the
#   following conversion rules that matches is applied
#
#   if the target is a pdf:
#     figs_orig/<name>.png    ->    figs/<name>.png
#     figs_orig/<name>.jpg    ->    figs/<name>.png
#     figs_orig/<name>.eps    ->    figs/<name>.pdf
#     figs_orig/<name>.pdf    ->    figs/<name>.pdf
#
#   if the target is a dvi / ps:
#     figs_orig/<name>.png    ->    figs/<name>.eps
#     figs_orig/<name>.jpg    ->    figs/<name>.eps
#     figs_orig/<name>.pdf    ->    figs/<name>.eps
#     figs_orig/<name>.eps    ->    figs/<name>.eps
#
#   If any of the input files contains the string "\bibliographystyle",
#   bibtex is invoked, the make dependency linked to the bib file found
#   in the "\bibliography{<file>}" entry.
#
#
# Note on xfig / ps+tex:
#   As some kind of support for xfig / ps+tex, the following conversion
#   takes place:
#     figs_orig/<name>.fig    ->    figs/<name>.eps_t + figs/<name>.{eps|pdf}
#
# Usage:
#   make info        prints some info about the setup, what is considered
#                    the main file, what is the bibliography, what are
#                    the relevant images etc.
#   make clean       removes typical intermediate files.
#   make veryclean   BEWARE! removes all except figs* and what is deemed
#                    essential for a proper tex document. BEWARE!
#   make (pdf)       runs as stated in the beginning, assuming as target
#                    a pdf named after the main file.
#   make ps          like above, targeting a postscript
#   make dvi         like above, targeting a dvi
#   make view        opens kdvi with errors piped to /dev/null
#   make watch       checks every second for changes in *.tex, *.bib,
#                    and figs_orig/*
#
#
# TODO:
#   - support an arbitrary number of levels of recursion (currently 2)
#   - strip the comments from the texfile for every analysis of the text
#     (currently only done for bib file inclusion)
##################################################################

##################################################################
#   Main definitions - place your customizations here
##################################################################

MAINFILE=$(shell grep -l "\\\\documentclass" *.tex)
FIGRAW=figs_orig
FIGDIR=figs

# uncomment the following to have the images rescaled
CONVERT=convert -geometry 300
#CONVERT=convert


##################################################################
#   Some Definitions that should not need change
##################################################################

ifneq ($(words $(MAINFILE)),1)
$(error For automatic main file detection, only one .tex file can contain the "\documentclass" string. run make MAINFILE=<your mainfile>)
endif
# Currently, only two levels of recursion for included input is supported.
# If you need more, extend as you like after the scheme below.
TEXFILESPRE:=\
  $(shell grep "\\\\include{" $(MAINFILE) | sed 's/.*{\([^}]*\)}.*/\1/g') \
  $(shell egrep "\\\\input{.*\.tex}" $(MAINFILE) | sed 's/.*{\([^}]*\).tex}.*/\1/g')

ifneq ($(words $(TEXFILESPRE)),0)
  TEXFILES:=\
    $(MAINFILE:.tex=)\
    $(TEXFILESPRE)\
    $(shell grep "\\\\include{" $(TEXFILESPRE:=.tex) | sed 's/.*{\([^}]*\)}.*/\1/g') \
    $(shell egrep "\\\\input{.*\.tex}" $(TEXFILESPRE:=.tex) | sed 's/.*{\([^}]*\).tex}.*/\1/g')
else
  TEXFILES:=$(MAINFILE:.tex=) $(TEXFILESPRE)
endif


MUTE=@
SILENT=> /dev/null
VERYSILENT=1> /dev/null 2>/dev/null

MAKE=make --no-print-directory
LS=ls -1 --color=none
CP=cp

#LATEX=platex -shell-escape -interaction=nonstopmode -kanji=euc
LATEX=platex
DIST=$(shell lsb_release -rs)
ifeq ($(DIST),12.04)
  BIBTEX=jbibtex
else
  BIBTEX=pbibtex -kanji=euc
endif

#for mac
ifeq ($(shell uname), Darwin)
  BIBTEX=pbibtex -kanji=euc
endif

MSG_LAB_CHANGED="LaTeX Warning: Label(s) may have changed"
MSG_REF_UNDEFINED="LaTeX Warning: Reference.*undefined on input line.*"
MSG_CIT_UNDEFINED="LaTeX Warning: Citation.*undefined on input"

# strip all comments and extract the bibliography
FIND_BIB_FILE=$(shell \
	sed -e "s/\\\\%//g" $(1) | \
	sed -e "s/\([^%]*\).*/\1/g" | \
	grep "\\\\bibliography{"  | \
        sed 's/.*{\([^}^ ]*\)}.*/\1/g').bib

BIBFILE:=$(call FIND_BIB_FILE, $(TEXFILES:=.tex))
ifneq ($(BIBFILE),.bib)
  ifneq ($(wildcard *.bib),)
    BBL:=$(MAINFILE:.tex=.bbl)
  else
    BBL:=$(BIBFILE)
  endif
else
  BBL:=$(BIBFILE)
endif

##################################################################
#   The figures used in the tex file
##################################################################

# Extract all lines that address the figures directory somehow
FIGS=$(sort $(shell grep -e $(FIGDIR)/ $(TEXFILES:=.tex) \
		    | sed "s/.*{$(FIGDIR)\/\([^}]*\).*/\1/g" ))

# the standard conversion rules are those, for postscript
# that changes into all->eps
#EPS_TO=.pdf
EPS_TO=.eps
#PDF_TO=.pdf
PDF_TO=.eps
PNG_TO=.eps
JPG_TO=.eps
#DIA_TO=.pdf
DIA_TO=.eps

# Find all existing files of a certain type in FIGRAW that would
# -after conversion- be included from FIGDIR
FIGSRCEPS=$(wildcard $(addprefix $(FIGRAW)/, $(addsuffix .eps, $(FIGS))))
FIGSRCJPG=$(wildcard $(addprefix $(FIGRAW)/, $(addsuffix .jpg, $(FIGS))))
FIGSRCPNG=$(wildcard $(addprefix $(FIGRAW)/, $(addsuffix .png, $(FIGS))))
FIGSRCPDF=$(wildcard $(addprefix $(FIGRAW)/, $(addsuffix .pdf, $(FIGS))))
FIGSRCDIA=$(wildcard $(addprefix $(FIGRAW)/, $(addsuffix .dia, $(FIGS))))
FIGSRCEPST=$(wildcard $(addprefix $(FIGRAW)/, $(FIGS:.eps_t=.fig)))

# Set up all the targets that should be created in the FIGDIR
FIGDEPEPS=$(subst $(FIGRAW)/, $(FIGDIR)/, $(FIGSRCEPS:.eps=$(EPS_TO)))
FIGDEPJPG=$(subst $(FIGRAW)/, $(FIGDIR)/, $(FIGSRCJPG:.jpg=$(JPG_TO)))
FIGDEPPNG=$(subst $(FIGRAW)/, $(FIGDIR)/, $(FIGSRCPNG:.png=$(PNG_TO)))
FIGDEPPDF=$(subst $(FIGRAW)/, $(FIGDIR)/, $(FIGSRCPDF:.pdf=$(PDF_TO)))
FIGDEPDIA=$(subst $(FIGRAW)/, $(FIGDIR)/, $(FIGSRCDIA:.dia=$(DIA_TO)))
FIGDEPEPST=$(subst $(FIGRAW)/, $(FIGDIR)/, $(FIGSRCEPST:.fig=.eps_t))

ALLFIGSRC=$(FIGSRCJPG) $(FIGSRCPNG) $(FIGSRCPDF) $(FIGSRCEPST) $(FIGSRCEPS) $(FIGSRCDIA)
ALLFIGS=$(FIGDEPJPG) $(FIGDEPPNG) $(FIGDEPPDF) $(FIGDEPEPST) $(FIGDEPEPS) $(FIGDEPDIA)


##################################################################
#   All the shell magic that helps us manage the twisted LaTeX
#   Compilation procedure
##################################################################


clear_valid=( [ ! -e .valid ] || $(RM) .valid )
check_undef_citations=\
  ( egrep $(MSG_CIT_UNDEFINED) $(MAINFILE:.tex=.log) > /dev/null )

# determine the changeset for citations
define check_citationchange
	(                                                \
	  [ -e .citations ] || touch .citations ;        \
	  ( grep "\\citation" $(MAINFILE:.tex=.aux)      \
		| sort                                   \
		| uniq                                   \
		| diff .citations -                      \
		> .citediff                              \
	  )                                              \
	)
endef

# exctract the citations from the aux file
define make_citations
	(                                                   \
	  (                                                 \
	    [ -e $(MAINFILE:.tex=.aux) ] &&                 \
	    ( echo "[info] Extracting citations...";        \
		grep "\\citation" $(MAINFILE:.tex=.aux)     \
		| sort                                      \
		| uniq                                      \
		> .citations                                \
	    )                                               \
	  )                                                 \
	  || touch .citations                               \
	)
endef

# comparing the citations in $(MAINFILE:.tex=.aux)
# against those in .citations.
# if there are differences, .citediff is changed.
define make_citediff
	(                                                     \
	  ( [ -e .citations ] || touch .citations ;           \
	    [ -e .citediff  ] || touch .citediff ;            \
	    echo "[info] Checking for changed Citations..." ; \
	    grep "\\citation" $(MAINFILE:.tex=.aux)           \
		| sort                                        \
		| uniq                                        \
		| diff .citations -                           \
	    > .citediff__                                     \
	  )                                                   \
	  || mv .citediff__ .citediff                         \
	)
endef

# compiles the document
# the file .valid is created if the compilation went without
# errors
define runtexonce
  ( 	                                                    \
    $(clear_valid);                                         \
    ( $(LATEX) $(MAINFILE) $(SILENT) &&                     \
      touch .valid );                                       \
    (                                                       \
      ( egrep $(MSG_REF_UNDEFINED) $(MAINFILE:.tex=.log)    \
        > .undefref ) ;                                     \
      ( egrep $(MSG_CIT_UNDEFINED) $(MAINFILE:.tex=.log)    \
        > .undefcit ) ;                                     \
      true                                                  \
    )                                                       \
  )
endef

# compile the document as many times as necessary to
# have cross-references right
define runtex
(                                                                      \
  echo "[info] Running tex...";                                        \
  $(runtexonce);                                                       \
  while( grep $(MSG_LAB_CHANGED) $(MAINFILE:.tex=.log) > /dev/null ) ; \
  do                                                                   \
      echo "[info] Rerunning tex...";                                  \
      $(runtexonce);                                                   \
  done                                                                 \
)
endef

##################################################################
#   Main compilation rules
##################################################################

pdf: $(MAINFILE:.tex=.pdf)

ps: $(MAINFILE:.tex=.dvi)

dvi: $(MAINFILE:.tex=.ps)



$(MAINFILE:.tex=.pdf): .compilesource
	$(MUTE)echo "[info] Created PDF."

# the dvi creation path invokes standard tex and requires other figures
$(MAINFILE:.tex=.dvi): .force
	$(MUTE)$(MAKE) .compilesource \
		LATEX="platex -shell-escape -interaction=nonstopmode" \
		EPS_TO=.eps \
		PDF_TO=.eps \
		PNG_TO=.eps \
		JPG_TO=.eps \
		DIA_TO=.eps

%.ps: %.dvi
	$(MUTE)echo "[info] Converting DVI to PS"
	$(MUTE)dvips $< -o $@ $(VERYSILENT)

.compilesource: .force
	$(MUTE)$(MAKE) .valid
	$(MUTE)[ -z "$(BBL)" ] || $(MAKE) .citations
	$(MUTE)[ -e .valid ] || (                                    \
	  ( [ -e .compiled ] || $(MAKE) .compiled ) ;                \
	  ( [ -e .compiled ] || $(MAKE) .compiled ) ;                \
	  ( [ -e .compiled ] || $(MAKE) .compiled ) ;                \
	  ( [ -e .compiled ] || echo "[Error] Could not make it work after 3 runs. Weird." ) \
	)
	$(MUTE) (                                                    \
           echo ; echo "Compilation Warnings:" ;                     \
	   grep "Warning" $(MAINFILE:.tex=.log) ;                    \
	   grep "Error" $(MAINFILE:.tex=.log) ;                      \
	   grep -A 1 "Undefined" $(MAINFILE:.tex=.log) || true       \
	)
	$(MUTE)[ ! -e $(MAINFILE:.tex=.bbl) ] || (                   \
	  echo ; echo "Bibtex Warnings:" ;                           \
	  grep "Warning" $(MAINFILE:.tex=.blg) ;                     \
	  grep "Error" $(MAINFILE:.tex=.blg) || true                 \
	)
	$(MUTE)[ -z "$(BBL)" -a -e .valid ] || [ -n "$(BBL)" -a -e .compiled ]
	$(MUTE)echo "[info] Converting DVI to PDF"
	$(MUTE)dvipdfmx -o $(MAINFILE:.tex=.pdf) $(MAINFILE:.tex=.dvi) $(VERYSILENT)

.figs: $(ALLFIGS)
	$(MUTE)touch .figs

clean:
	- $(MUTE)$(RM) -f *.bbl *.blg *.aux *.log
	- $(MUTE)$(RM) -f *.*~ *~
	- $(MUTE)$(RM) -f .citations .undefcit .undefref .valid .citediff .compiled

figclean:
	- $(MUTE)$(RM) $(FIGDIR)/*

veryclean: clean figclean
	$(MUTE)$(RM) `$(LS) | grep -v ".tex$$" |  \
                              grep -v "Makefile$$" |  \
                              grep -v ".bib$$" |  \
                              grep -v "figs$$" |      \
                              grep -v ".bst$$" |  \
                              grep -v ".cls$$"`
	$(MUTE)$(RM) .??*

view: $(MAINFILE:.tex=.pdf)
	kpdf $< > /dev/null 2>&1 &

viewdvi: $(MAINFILE:.tex=.dvi)
	kdvi $(<:.dvi=) > /dev/null 2>&1 &

viewps: $(MAINFILE:.tex=.ps)
	kghostview $< > /dev/null 2>&1 &

info:
	@echo Main file:    $(MAINFILE)
	@echo Input files:  $(TEXFILES:=.tex)
	@echo Bibliography: $(BIBFILE)
	@echo Images USED
	@echo
	@echo $(ALLFIGSRC)
	@echo
	@echo Images NOT used
	@echo
	@echo $(filter-out $(ALLFIGSRC), $(wildcard $(FIGRAW)/*))

# just do one run...
.valid: .figs $(TEXFILES:=.tex)
	$(MUTE)$(runtex)

# if citations changed since last run of bibtex, run it again.
.citations: .citediff $(BIBFILE)
	$(MUTE)[ ! -e .compiled ] || rm .compiled
	$(MUTE)(                         \
	  echo "[info] Running BibTex" ; \
	  $(BIBTEX) $(MAINFILE:.tex=) $(SILENT)         \
	) && $(make_citations)
	$(MUTE) $(clear_valid)

.citediff: .force
	$(MUTE)$(make_citediff)

# run as long as necessary
.compiled: $(TEXFILES:=.tex) $(BBL) .figs
	$(MUTE)echo "Found undefined Citations, rerunning..."
	$(MUTE)$(runtex)
	$(MUTE)$(check_undef_citations) || touch .compiled

.force:



##################################################################
#   Rules to convert the figures into the format that (pdf)latex
#   understands
##################################################################

$(FIGDIR)/%.eps : $(FIGRAW)/%.png
	$(CONVERT) $< $@

$(FIGDIR)/%.eps : $(FIGRAW)/%.jpg
	$(CONVERT) $< $@

$(FIGDIR)/%.eps : $(FIGRAW)/%.dia
	dia -e $@ $<

$(FIGDIR)/%.eps : $(FIGRAW)/%.pdf
	$(CONVERT) $< $@

$(FIGDIR)/%.eps : $(FIGRAW)/%.eps
	$(CP) $< $@

$(FIGDIR)/%.png : $(FIGRAW)/%.png
	$(CONVERT) $< $@

$(FIGDIR)/%.png : $(FIGRAW)/%.jpg
	$(CONVERT) $< $@

$(FIGDIR)/%.pdf : $(FIGRAW)/%.eps
	ps2pdf -dEPSCrop $< $@

$(FIGDIR)/%.pdf : $(FIGRAW)/%.dia
	dia -e $(FIGDIR)/$*.eps $<; ps2pdf -dEPSCrop $(FIGDIR)/$*.eps $@

$(FIGDIR)/%.pdf : $(FIGRAW)/%.pdf
	$(CP) $< $@

$(FIGDEPEPST): $(FIGDIR)/%.eps_t : $(FIGRAW)/%.fig
	fig2dev -L pstex_t -p $(@:.eps_t=) $? > $@
	fig2dev -L pstex $? $(if $(filter .eps,$(EPS_TO)),,| epstopdf -filter) > ${@:.eps_t=$(EPS_TO)}

watch:
	$(MUTE)CHANGE=true &&                            \
	while true ; do                                  \
          if $$CHANGE ; then                             \
	    for i in $(TEXFILES:=.tex) $(BIBFILE) ; do   \
	      touch .$$i -r $$i;                         \
	    done;                                        \
	    for i in `( cd $(FIGRAW); ls -1 *.* )` ; do  \
	      touch $(FIGRAW)/.$$i -r $(FIGRAW)/$$i;     \
	    done;                                        \
	    CHANGE=false;                                \
	    make;                                        \
          fi;                                            \
          sleep 1;                                       \
          for i in $(TEXFILES:=.tex) $(BIBFILE) ; do     \
	    if [ .$$i -ot $$i ] ; then                   \
	      CHANGE=true;                               \
	    fi                                           \
          done ;                                         \
          for i in `( cd $(FIGRAW); ls -1 *.* )` ; do    \
	    if [ $(FIGRAW)/.$$i -ot $(FIGRAW)/$$i ] ; then \
	      CHANGE=true;                               \
	    fi                                           \
          done                                           \
        done
ARCH=$(shell uname)
open:
	open *pdf
