Bad Blaster
===========

Small game using OCaml and SDL. Fly a ship, shoot other ships.

Done by Michalis Kamburelis, as a project for OCaml lecture on my University
http://www.ii.uni.wroc.pl/ . This was my first larger project in OCaml,
and I think it turned out pretty good :)
This shows that making a "real" program,
that interfaces with an external library (SDL) in C,
and has some inherently imperative parts (game loop)
is still a pleasure in OCaml. While small parts of this code use
imperative features, most of the code is nicely functional.
And the whole is a nice, strictly-typed code.

Compilation:
* Install OCaml and OCaml bindings for SDL.
  Under Debian this is as simple as "apt-get install ocaml libsdl-ocaml-dev"
* Compile by simple "make" in the main directory.
* Run "make install" to install a symlink $HOME/.badBlaster.data/
  necessary to play the game.
* Run game simply by "./badBlaster" or "./bb800x600" (the latter
  makes full-screen best for our game).