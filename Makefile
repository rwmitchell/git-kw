# $Id$
# $Source$
######################################################################
# You'll need these:
#    make.darwin-i386
#    make.solaris-sparc

# include make.$(OSTYPE)-$(MACHTYPE)

REPO:=$(shell basename ${PWD})
GITVERSION:='$(shell git show -s --date=format:"%F %T %z" --format="$(REPO) %ad %d %h %an %aE")'
GITVERSION:=$(shell git show -s --date=format:"%F %T %z" --format="$(REPO) %h %d %ad %an %aE")
GITVERSION:="\#define IMG_VERSION \"IMG_VERSION $(GITVERSION)\""


CC_DEBUG_FLAGS    = -g3 -DDEBUG_ALL
CC_CHECK_FLAGS    = --analyzer-output text --analyze -I$(HOME)/Build/include -I$(SRC)
CC_RELEASE_FLAGS  = -O3

VERSION           = Source/version.h

stamp: $(VERSION)
	@ echo GITVERSION: ${GITVERSION}

.PHONY: update_version
$(VERSION): update_version
	@ [ -f $@ ] || touch $@
	@ echo ${GITVERSION}
	@ echo $(GITVERSION) | cmp -s $@ - || echo $(GITVERSION) > $@

RLS  = release
DBG  = debug
PTH := $(RLS)
RUN  = all

list:

column = sed 's/ / 	/g' | tr ' |' '\n\n'


DIR = $(shell basename $(CURDIR))
BLD = $(HOME)/Build
INC = $(BLD)/include
MCH = $(BLD)/$(MACHTYPE)
BAS = $(MCH)/$(PTH)/$(DIR)
DEP = $(MCH)/.dep/$(DIR)

DST = $(BAS)/bin
OBJ = $(BAS)/obj
LIB = $(BAS)/lib

# Override this on the cmdline with: make prefix=/some/where/else
prefix = $(BLD)

SRC = Source
NST = $(prefix)/bin

MYINC = -I$(BLD)/include -I$(SRC)
MYLIB = -L$(BLD)/lib -lmylib

.PHONY: check
check: CFLAGS = $(CC_CHECK_FLAGS)
check: .analyze

.PHONY: check_all
check_all: CFLAGS = $(CC_CHECK_FLAGS)
check_all: make_check_all

.PHONY: debug
debug: CFLAGS += $(CC_DEBUG_FLAGS) $(MYINC)
debug: PTH    := $(DBG)
debug: make_it

.PHONY: release
release: CFLAGS += $(CC_RELEASE_FLAGS) $(MYINC)
release: PTH    := $(RLS)
release: make_it

# All C programs
DST_PROGS =          \
#	$(DST)/wg          \

# All Scripts (basename, no extensions ie: foo, not foo.pl)
DST_SCRPT =          \
	$(DST)/gitkwexpand \
	$(DST)/gitkwshrink \

DIRS =    \
	$(DEP)  \
	$(OBJ)  \
	$(BAS)  \
	$(DST)  \
	$(NST)  \

$(DST)/%:	$(SRC)/%.pl
	install -m ugo+rx $< $@

$(DST)/%:	$(SRC)/%.sh
	install -m ugo+rx $< $@

$(DST)/%:	$(SRC)/%.awk
	install -m ugo+rx $< $@

$(DST)/%:	$(SRC)/%.py
	install -m ugo+rx $< $@

$(DST)/%:	$(SRC)/%.zsh
	install -m ugo+rx $< $@

$(NST)/%: $(DST)/%
	install -m ugo+rx $< $@

test:
	@echo $(NST_SCRPT)


NST_PROGS = $(subst $(DST), $(NST), $(DST_PROGS))
NST_SCRPT = $(subst $(DST), $(NST), $(DST_SCRPT))


.PHONY: install real_install help

list:
	@echo all install
	@echo $(DST_PROGS)
	@echo $(DST_SCRPT)
#@echo $(NST_PROGS)
#@echo $(NST_SCRPT)

all: \
	$(DIRS)       \
	$(DST_PROGS)  \
	$(DST_SCRPT)  \
	show_install  \
#	tags types    \

install: real_install
	@true

real_install:        \
	$(NST)        \
	$(NST_SCRPT)  \
	$(NST_PROGS)  \

$(DIRS):
	mkdir -p $@

show_install:
	@echo ""
	@echo "These programs need to be installed:"
	@make -sn install

help:
	@make -sn
	@echo "These programs are made:"
	@echo $(DST_PROGS) | tr ' ' '\n'
	@echo $(DST_SCRPT) | tr ' ' '\n'
	@echo
	@echo "Try: make install"

help_install:
	@echo "These programs are installed:"
	@echo
	@echo $(NST_PROGS) | tr ' ' '\n'
	@echo $(NST_SCRPT) | tr ' ' '\n'
	@echo

clean:
	$(RM) $(DEP)/*.d $(OBJ)/*.o $(DST_PROGS) $(DST_SCRPT)
	rmdir $(OBJ) $(DST)

foo:
	@ echo "OBJ  " $(OBJ)
	@ echo "SRC  " $(SRC)
	@ echo "HOST " $(HOST)
	@ echo "NSTS " $(NST_SCRPT) | $(column)

.analyze: $(wildcard $(SRC)/*.c)
	gcc $(CFLAGS) $?
	@ touch .analyze

make_check_all:
	@ rm .analyze  || true
	@ make CFLAGS="$(CFLAGS)" check

make_it:
	make PTH=$(PTH) CFLAGS="$(CFLAGS)" $(RUN)

#We don't need to clean up when we're making these targets
NODEPS:=clean svn install
#Find all the C++ files in the $(SRC)/ directory
SOURCES:=$(shell find $(SRC)  -name "*.c")
#These are the dependency files, which make will clean up after it creates them
DEPFILES:=$(patsubst %.c,%.d,$(patsubst $(SRC)/%,$(DEP)/%, $(SOURCES)))

#Don't create dependencies when we're cleaning, for instance
ifeq (0, $(words $(findstring $(MAKECMDGOALS), $(NODEPS))))
    #Chances are, these files don't exist.  GMake will create them and
    #clean up automatically afterwards
    -include $(DEPFILES)
endif

#This is the rule for creating the dependency files
$(DEP)/%.d: $(SRC)/%.c $(DEP)
	@echo "START DEP: $@"
	@echo $(CC) $(CFLAGS) -MG -MM -MT '$(patsubst $(SRC)/%,$(OBJ)/%, $(patsubst %.c,%.o,$<))' $(MYINC) $<
	$(CC) $(CFLAGS) -MG -MM -MT '$(patsubst $(SRC)/%,$(OBJ)/%, $(patsubst %.c,%.o,$<))' $(MYINC) $< > $@
	@echo "END   DEP: $@"
# End of - Dependency code added here

# Make a highlight file for types.  Requires Exuberant ctags and awk

# Make a highlight file for types.  Requires Universal ctags and awk
types: $(SRC)/.types.vim
$(SRC)/.types.vim: $(SRC)/*.[ch]
	ctags --kinds-c=gstu -o- \
		$(SRC)/*.[ch] \
		$(INC)/*.h \
		| grep -v "^__anon" \
		| awk 'BEGIN{printf("syntax keyword Type\t")} \
		{printf("%s ", $$1)}END{print ""}' > $@
	ctags --kinds-c=d -o- \
		$(SRC)/*.h \
		$(INC)/*.h \
		| grep -v "^__anon" \
		| awk 'BEGIN{printf("syntax keyword Debug\t")}\
		{printf("%s ", $$1)}END{print ""}' >> $@
# End types

tags: $(SRC)/*.[ch]
	ctags --fields=+l --langmap=c:.c.h \
		$(SRC)/* \
		$(INC)/*

