# Skrypt dopisuj±cy odpowiedni copryright i notke ¿e ten kod jest na GPL
# do ka¿dego pliku .ml i .mli Bad Blastera. Po wykonaniu tego wystarczy
# jeszcze dodaæ do archiwum plik COPYING z GPLem i ju¿.

doit ()
{
  echo -n "${1}:"
  emacs_batch -l kambi-startup.el "$1" \
    --eval '(ocaml-insert-gpl-licensed "\"Bad Blaster\""
      "Copyright 2004 Michalis Kamburelis.")' \
    -f save-buffer
  echo "done"
}

for NNN in *.ml; do doit "$NNN"; done
for NNN in *.mli; do doit "$NNN"; done
