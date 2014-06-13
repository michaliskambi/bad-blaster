(*
  Copyright 2004 Michalis Kamburelis.

  This file is part of "Bad Blaster".

  "Bad Blaster" is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  "Bad Blaster" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with "Bad Blaster"; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*)

(** Ogólne funkcje przydatne do obs³ugi Sdla, 
   niezale¿ne od "Bad Blaster". Innymi s³owy ten modu³ nie mo¿e zale¿eæ
   od ¿adnego modu³u BbXxx, nawet BbBase; natomiast mo¿e
   zale¿eæ od Base i od standardowych modu³ów Sdla.
   
   Uwaga do nazwy: nazywa sie SdlUtils, zwracam uwagê ¿e czlon 
   "Utils" jest z du¿ej litery, co jest 1. zgodne z moja konwencj±
   nazywania modulow w OCamlu 2. niezgodne z konwencj±
   modu³ów ocamlsdl'a (tam nazwaliby to "Sdlutils") i to jest
   bardzo dobrze.
*)

(** [rect_wrap src_width src_height dst_width dst_height x0 y0] zadzia³a tak:
   wyobra¼my sobie ¿e mamy obrazek dst o rozmiarach dst_width, dst_height.
   Niech poprawna pozycja na takim obrazku to (x,y) takie ¿e 
   x jest w \[0; dst_width), y w \[0; dst_height).
   Chcemy na tym obrazku narysowaæ prostok±t src o wymiarach 
   src_width i src_height (przy czym src_width<=dst_width i 
   analogicznie height) w miejscu x0,y0 (gdzie x0,y0 to poprawna
   pozycja na dst).
   
   Ale chcemy narysowaæ src na dst tak ¿eby src w razie potrzeby
   "przewin±³ siê" przez brzegi dst, tzn. je¿eli x0+src_width>dst_width
   to trzeba bêdzie podzielic obrazek src na dwie czê¶ci.
   Podobnie mo¿e okazaæ siê konieczny podzia³ poziomy.
   
   Ta funkcja robi wla¶nie taki podzial. Zwraca 1,2 lub 4 pary
   postaci (src_part, dst_pos) gdzie src_part okre¶la
   jak± czê¶æ obrazka src wzi±æ a dst_pos okre¶la
   na jakiej pozycji w dst powinny siê one znale¼æ
   (dst_pos.r_w i r_h s± równe zawsze 0). *)
val rect_wrap: int -> int -> int -> int -> int -> int -> 
  (Sdlvideo.rect * Sdlvideo.rect) list

(** [blit_surface_center src dst] rysuje [src] na ¶rodku [dst].
   Je¿eli który¶ wymiar [src] bêdzie wiêkszy od odpowiedniego wymiaru
   [dst] to [src] zostanie obciêty po równo z obu stron. 
   Przy okazji zwraca rect którego [r_x], [r_y] mówi± na jakiej
   pozycji zosta³ zapisany [src] (a [r_w] i [r_h] s± niezdefiniowane). *)
val blit_surface_center: Sdlvideo.surface -> Sdlvideo.surface -> Sdlvideo.rect

(** Odczytuj zdarzenia SDLa przez wait_event a¿ zajdzie zdarzenie KEYDOWN 
   z klawiszem na podanej li¶cie (musisz podac listê <> \[\]).
   Zwraca to zdarzenie KEYDOWN. *)
val wait_for_keypress: Sdlkey.t list -> Sdlevent.keyboard_event

(** W skrócie, [blit_surface_wrapping src dst x0 y0] dzia³a trochê jak
     [Sdlvideo.blit_surface src dst \{r_x=x0; r_y:y0\}]
   tyle ¿e [src] jest "zawijany" wokó³ brzegów [dst] 
   je¿eli jest za blisko prawego/dolnego brzegu ekranu.
   Patrz [rect_wrap] po dok³adny opis. 
   Pamietaj ¿e [x0],[y0] musi byc poprawn± pozycj± na [dst]. *) 
val blit_surface_wrapping: 
  Sdlvideo.surface -> Sdlvideo.surface -> int -> int -> unit
  
(** Jak [blit_surface_wrapping] tylko dodatkowo podajesz jeszcze
   [rect] ograniczaj±cy jak± czê¶æ [src] rysowaæ. *)
val blit_surface_wrapping_srcrect: 
  Sdlvideo.rect -> Sdlvideo.surface -> Sdlvideo.surface -> int -> int -> unit

(** [tile_surface tile surf] rysuje surface [tile] na [surf] na zasadzie 
   kafelek: pokrywa ca³± powierzchniê [surf] sasiaduj±cymi obrazkami [tile]. *)
val tile_surface: 
  Sdlvideo.surface -> Sdlvideo.surface -> unit
    
(** {1 Funkcje zwi±zane z czasem zwracanym przez [Sdltimer.get_ticks] } *)

(** [ticks_substract a b] jest przeznaczone do odejmowania dwóch czasów
   uzyskanych z [Sdltimer.get_ticks]. Podawaj zawsze jako [a] czas
   pó¼niejszy ni¿ [b]. 
   
   Gdyby OcamlSDL zwraca³o dobry typ (int32) z Sdltimer.get_timer:
   Zwraca jakby a-b ale bierze pod 
   uwagê ¿e mog± siê one przewin±æ: dopóki [a] jest pó¼niejsze od [b]
   o mniej niz ~49 dni to, nawet je¶li [get_ticks] siê przewinê³o
   po drodze, zwróci dobr± odpowied¼. 
   
   Poniewa¿ jednak OcamlSDL zwraca int wiêc opisana wy¿ej mo¿liwo¶æ
   nie jest dostêpna. Po prostu nie da siê w sposób elegancki zabezpieczyæ
   przed przewijaniem [get_timer] bo pomiêdzy [get_timer] SDLa a [get_timer] 
   OCamla wykonywane jest dodatkowe obcinanie najstarszego bitu.
   No dobrze, czyli ta funkcja w tej chwili zwraca po prostu a-b.
   Nie jest to w sumie nic strasznego - w koñcu raczej nikt nie bêdzie
   mia³ "Bad Blastera" uruchomionego d³u¿ej ni¿ przez ~24 dni wiêc
   nic siê nie stanie. Tym niemniej dla porz±dku bêdê zawsze odejmowa³
   czasy u¿ywaj±c tej funkcji, zamiast wykonywaæ odejmowanie explicite.
*)
val ticks_substract: int -> int -> int

(** Zwraca ile czasu w ticks up³ynê³o od argumentu do teraz, czyli
   [ticks_passed b] to to [samo ticks_substract (get_ticks()) b].
   Pamiêtaj ¿e musisz zainicjowaæ podsystem `TIMER SDLa aby tego u¿yæ. *)
val ticks_passed: int -> int

(** [ticks_check_passed time_option time_to_pass] zwraca true gdy
   time_option = None lub
   time_option = Some t takie ¿e (ticks_passed t >= time_to_pass),
   wpp. zwraca false. *)
val ticks_check_passed: int option -> int -> bool
