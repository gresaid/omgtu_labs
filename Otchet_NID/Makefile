# settings precedence: command line>usercfg.mk>{windows,unix}.mk

# user settings
# include before variable definitions
ifneq ($(wildcard usercfg.mk),)
	include usercfg.mk
endif

# platform specific settings
# include before variable definitions
ifeq ($(OS),Windows_NT)
	include windows.mk
else
	include unix.mk
endif

# Ghostscript-based pdf postprocessing
include compress.mk

# Config file
MKRC ?= latexmkrc

# Source .tex file
SOURCE ?= dissertation

# LaTeX compiler output .pdf file
TARGET ?= $(SOURCE)

# LaTeX version:
# -pdf		= pdflatex
# -pdfdvi	= pdflatex with dvi
# -pdfps	= pdflatex with ps
# -pdfxe	= xelatex with dvi (faster than -xelatex)
# -xelatex	= xelatex without dvi
# -pdflua	= lualatex with dvi  (faster than -lualatex)
# -lualatex	= lualatex without dvi
BACKEND ?= -pdfxe

# Do not modify the section below. Edit usercfg.mk instead.
DRAFTON ?= # 1=on;0=off
SHOWMARKUP ?= # 1=on;0=off
FONTFAMILY ?= # 0=CMU;1=MS fonts;2=Liberation fonts
ALTFONT ?= # 0=Computer Modern;1=pscyr;2=XCharter
USEBIBER ?= # 0=bibtex8;1=biber
USEFOOTCITE ?= # 0=no;1=yes
BIBGROUPED ?= # 0=no;1=yes
IMGCOMPILE ?= # 1=on;0=off
NOTESON ?= # 0=off;1=on, separate slide;2=on, same slide
LATEXFLAGS ?= -halt-on-error -file-line-error
LATEXMKFLAGS ?= -silent
BIBERFLAGS ?= # --fixinits
REGEXDIRS ?= . Dissertation Synopsis Presentation # distclean dirs
TIMERON ?= # show CPU usage
TIKZFILE ?= # .tikz file for tikz rule
USEDEV ?= # use development version

# Makefile options
MAKEFLAGS := -s
.DEFAULT_GOAL := all
.NOTPARALLEL:

export DRAFTON
export SHOWMARKUP
export FONTFAMILY
export ALTFONT
export USEBIBER
export USEFOOTCITE
export BIBGROUPED
export IMGCOMPILE
export NOTESON
export LATEXFLAGS
export BIBERFLAGS
export REGEXDIRS
export TIMERON
export TIKZFILE
export USEDEV

##! компиляция всех файлов
all: synopsis dissertation presentation

define compile
	latexmk -norc -r $(MKRC) $(LATEXMKFLAGS) $(BACKEND) -jobname=$(TARGET) $(SOURCE)
endef

##! компиляция диссертации
dissertation: TARGET=dissertation
dissertation: SOURCE=dissertation
dissertation:
	$(compile)

##! компиляция диссертации, автореферата, и презентации при помощи pdflatex
pdflatex: BACKEND=-pdf
pdflatex: dissertation synopsis presentation

##! компиляция черновиков всех файлов
draft: dissertation-draft synopsis-draft





##! очистка от временных файлов цели TARGET
clean-target:
	latexmk -norc -r $(MKRC) -f $(LATEXMKFLAGS) $(BACKEND) -jobname=$(TARGET) -c $(SOURCE)

##! полная очистка от временных файлов цели TARGET
distclean-target:
	latexmk -norc -r $(MKRC) -f $(LATEXMKFLAGS) $(BACKEND) -jobname=$(TARGET) -C $(SOURCE)

##! очистка проекта от временных файлов
clean:
	"$(MAKE)" SOURCE=dissertation TARGET=dissertation clean-target
	"$(MAKE)" SOURCE=synopsis TARGET=synopsis clean-target
	"$(MAKE)" SOURCE=presentation TARGET=presentation clean-target
	"$(MAKE)" SOURCE=presentation_booklet TARGET=presentation_booklet clean-target
	"$(MAKE)" SOURCE=presentation_handout TARGET=presentation_handout clean-target

##! полная очистка проекта от временных файлов
distclean:
	"$(MAKE)" SOURCE=dissertation TARGET=dissertation distclean-target
	"$(MAKE)" SOURCE=synopsis TARGET=synopsis distclean-target
	"$(MAKE)" SOURCE=presentation TARGET=presentation distclean-target
	"$(MAKE)" SOURCE=presentation_booklet TARGET=presentation_booklet distclean-target
	"$(MAKE)" SOURCE=presentation_handout TARGET=presentation_handout distclean-target

# include after "all" rule
include examples.mk

.PHONY: all dissertation synopsis presentation dissertation-draft \
synopsis-draft pdflatex draft synopsis-booklet presentation-booklet\
tikz release clean-target distclean-target clean distclean
