# Makefile dla projektu "Bad Blaster". Piszac go w pewnym momencie
# przeczytalem dokumentacje programu ocamldep i pokazany tam przykladowy 
# Makefile w znacznym stopniu wplynal na uproszczenie ponizszego
# pliku.
#
# Oficjalne cele tego Makefile'a:
#   make - zbuduj $(BIN) = program skompilowany do bytecode
#   make $(BINOPT) - zbuduj $(BINOPT) = program skompilowany do kodu natywnego
#   make clean - remove all files made by ocaml compilers, 
#     including $(BIN) and $(BINOPT)
# 
#   make htmldoc - wygeneruj przy pomocy ocamldoc dokumentacje w apidoc/.
#   make cleandoc - clean documentation

BIN=badBlaster
BINOPT=badBlaster.opt

# OBJ musza byc ponizej wymienione w takiej kolejnosci w jakiej nalezy je podac
# przy linkowaniu dla ocamlc.
OBJS=base.cmo sdlUtils.cmo bbBase.cmo bbWrite.cmo bbRotatedImage.cmo \
  bbMoveable.cmo bbGame.cmo bbTime.cmo badBlaster.cmo 
OBJSOPT=$(addsuffix .cmx,$(basename $(OBJS)))

# Odpowiednie parametry -I do standardowych bibliotek.
# Beda dodawane do kazdego wywolania ocamlc i ocamlopt, 
# zarowno przy kompilowaniu (tzn. do cm?) jak i przy linkowaniu,
# bo w koncu i tu i tu sa potrzebne (co najwyzej moznaby uniknac
# podawania ich przy niektowych plikach cm?, np. bbUtils nie zalezy od 
# modulow sdl'a, ale to nic nie daje - nie przyspieszy to zbytnio
# kompilacji...). Acha, i do ocamldoc tez.
OCC_COMMON_FLAGS=-I +sdl

# LIBS to lista plikow .cma, w takiej kolejnosci w jakiej nalezy
# je podawac.
LIBS=bigarray.cma sdl.cma sdlloader.cma
LIBSOPT=$(addsuffix .cmxa,$(basename $(LIBS)))

# Wywolania ocamlc i ocamlopt, z dodanymi juz $(OCC_COMMON_FLAGS)
# i $(LIBS) / $(LIBSOPT), mozna tez tutaj dopisywac inne opcje specyficzne 
# tylko dla ocamlc lub tylko dla ocamlopt.
OCC=ocamlc $(OCC_COMMON_FLAGS) $(LIBS)
OCCOPT=ocamlopt $(OCC_COMMON_FLAGS) $(LIBSOPT)

# rules for compiling ----------------------------------------

$(BIN): $(OBJS)
	$(OCC) $(OBJS) -o $@ 

$(BINOPT): $(OBJSOPT)
	$(OCCOPT) $(OBJSOPT) -o $@

%.cmo: %.ml
	$(OCC) -c $<

%.cmi: %.mli
	$(OCC) -c $<

%.cmx: %.ml
	$(OCCOPT) -c $<

Makefile.dep:
	ocamldep *.ml *.mli > $@

include Makefile.dep

.PHONY: clean
clean:
	rm -f *.cm[oix] *.o $(BIN) $(BINOPT) Makefile.dep

.PHONY: install
install:
	rm -f $(HOME)/.badBlaster.data
	ln -s $(shell pwd) $(HOME)/.badBlaster.data

# doc generating ----------------------------------------

DOC_PATH=doc/
HTML_DOC_PATH=apidoc/
LATEX_DOC_PATH=$(DOC_PATH)latex/
MAN_DOC_PATH=$(DOC_PATH)man/

# Oblicz DOC_FILES z $(OBJS) zamiast po prostu dac *.mli - w ten sposob
# moduly beda wymienione dokumentacji w odpowiedniej kolejosci.
DOC_FILES=$(filter-out badBlaster.mli, $(addsuffix .mli,$(basename $(OBJS))))
DOC_OPTS=$(OCC_COMMON_FLAGS) -t "Bad Blaster modules"

.PHONY: predoc htmldoc latexdoc mandoc cleandoc

# Przed wygenerowaniem dokumentacji ocamldoc musi miec skompilowane interfejsy.
predoc:	$(addsuffix .cmi,$(basename $(DOC_FILES)))

htmldoc: predoc
	mkdir -p $(HTML_DOC_PATH)
	ocamldoc -html $(DOC_OPTS) -d $(HTML_DOC_PATH) $(DOC_FILES)
	sed -i -e 's/<head>/<head><meta http-equiv="Content-Type" content="text\/html; charset=ISO-8859-2">/' \
	  $(HTML_DOC_PATH)*.html

latexdoc: predoc
	mkdir -p $(LATEX_DOC_PATH)
	ocamldoc -latex $(DOC_OPTS) $(DOC_FILES)
	mv -f ocamldoc.out $(LATEX_DOC_PATH)badBlaster.tex
	mv -f ocamldoc.* $(LATEX_DOC_PATH)

mandoc: predoc
	mkdir -p $(MAN_DOC_PATH)
	ocamldoc -man $(DOC_OPTS) -d $(MAN_DOC_PATH) $(DOC_FILES) 

cleandoc:
	rm -fR $(MAN_DOC_PATH)
	rm -fR $(HTML_DOC_PATH)
	rm -fR $(LATEX_DOC_PATH)

# other things ----------------------------------------

.PHONY: reallyclean distzip

reallyclean: clean cleandoc
	rm -f *~

distzip: htmldoc
	rm -f badBlaster.zip
	zip -r badBlaster.zip apidoc/ images/ README.html \
	  Makefile bb800x600 COPYING *.ml *.mli 

# eof ----------------------------------------
