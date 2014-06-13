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

(** Kilka niezwi±zanych rzeczy dla "Bad Blaster",
   zbyt ma³ych by stanowi³y osobne modu³y. *)

(** Rozmiary pola gry; chwilowo s± to tak¿e rozmiary okna gry, wiêc
   nie mog± byæ za du¿e. *)
val board_width: unit -> int
val board_height: unit -> int
(** [board_width_f] to skrót dla [float_of_int (board_width())] *)
val board_width_f: unit -> float
(** [board_height_f] to skrót dla [float_of_int (board_height())] *)
val board_height_f: unit -> float

(** Mo¿esz to wywo³aæ tylko przed u¿yciem czegokolwiek innego 
   z modu³ów BbXxx ! Niezbyt eleganckie rozwi±zanie ale 
   trudno - w praktyce chodzi tylko o to ¿eby u¿ytkownik
   móg³ zainicjowaæ [board_width] i [board_height] poprzez argumenty 
   w linii polecen. *)
val init_board_size: int -> int -> unit

(** Pozycja na planszy gry, z dok³adno¶ci± zmiennoprzecinkow±.
   x i y bêd± zawsze w zakresie 0..boardWidth, 0..boardHeight.   
   Punkt 0,0 to lewy górny róg (a wiec Y s± odwrotnie ni¿
   zazwyczaj siê je rysuje na kartce). To po to ¿eby byæ zgodnym
   z rozumieniem SDLa. 
   Konstruuj±c podaj pozycjê pocz±tkow± (podane startowe wspó³rzêdne 
   nie musz± byæ w dopuszczalnym zakresie 0..boardWidth, 0..boardHeight, 
   zostan± odpowiednio poprawione) *) 
class c_pos : float -> float ->
object ('a)
  method x: float
  method y: float
 
  (** Przesuwa pozycjê, x i y siê przewijaj± cyklicznie ¿eby byæ 
     zawsze w zakresie 0..boardWidth/Height. *)
  method add_f: float -> float -> unit
  
  method add: c_pos -> unit
  
  (** Zwróæ rect SDLa, x i y to bêd± zaokr±glone nasze pozycje
     (do zakresu \[0; boardWidth), \[0; boardHeight)),
     a width i height recta bêd± ustawione na 0. *)
  method to_rect: Sdlvideo.rect
  
  (** To samo co to_rect.r_x *)
  method int_x: int
  
  (** To samo co to_rect.r_y *)
  method int_y: int
  
  (** [move_angle angle length] przesuñ punkt o wektor d³ugo¶ci [length]
     pod k±tem [angle] do uk³adu wspó³rzêdnych. [angle] jest w stopniach
     (w swobodnym zakresie, to znaczy niekoniecznie w \[0; 360\])
     i jest interpretowany jak zwykle w tym programie:
     0 = w prawo (w +X),
     wiêcej = obraca siê CCW, przy czym prawo = +X a góra = -Y. *)
  method move_angle: float -> float -> unit
  
  (** Same as [move_angle], but here [angle] is in radians *)
  method move_angle_rad: float -> float -> unit
  
  (** [angle_rad_in_direction target] zwraca jak powinien byæ obrócony obiekt 
     po³o¿ony na tej pozycji aby wskazywaæ na obiekt na pozycji [target].
     Np. statek komputera chc±c strzeliæ rakietê w stronê statku gracza
     zapyta siê [angle_rad_in_direction] podaj±c jako parametr pozycjê
     statku gracza i otrzyma w odpowiedzi jak± warto¶æ powinno mieæ
     jego pole [angle] (po konwersji z radianów na stopnie) aby byæ skierowanym
     idealnie w stronê statku gracza.
     
     Ta funkcja bierze pod uwagê ¿e plansza siê przewija. Je¿eli widzi
     ¿e bez przewijania planszy odleglo¶æ wzd³u¿ wspó³rzêdnej x pomiêdzy
     [self] a [target] jest wiêksza ni¿ [board_width()/2] to wie ¿e
     krótsz± odleg³o¶æ uzyskamy przelatuj±c przez pionow± krawêd¼ 
     planszy na drug± stronê. Podobnie dla wspó³rzêdnej y. Ta funkcja 
     zwraca taki k±t ¿eby gdyby jego wybraæ to droga w stronê [target]
     bêdzie najkrótsza. 
     
     Ta funkcja zawsze zwraca liczbê w przedziale \[0; 2*pi\]. *)
  method angle_rad_in_direction: c_pos -> float
  
  (** [angle_deg_in_direction target] zwraca to samo co  
     [angle_rad_in_direction target] tylko wyra¿one w stopniach
     (w przedziale \[0.; 360.\]). *)
  method angle_deg_in_direction: c_pos -> float
  
  (** [move_to target length] moves by [length] in direction 
     from current pos to [target] (direction is calculated using
     [angle_rad_in_direction] so it knows that board "wraps" at it's edges. *)
  method move_to: c_pos -> float -> unit
  
  (** Zwraca kwadrat [board_distance]. W praktyce jednak to [board_distance]
     jest zaimplementowane jako [sqrt sqr_board_distance], wiêc u¿ywaj±c
     [sqr_board_distance] zamiast [board_distance] zaoszczêdzasz na
     pierwiastkowaniu. *)     
  method sqr_board_distance: c_pos -> float
  
  (** Zwróc odleg³o¶æ do drugiej pozycji c_pos. Podobnie jak
     [angle_rad_in_direction] bierze pod uwagê przewijanie i je¶li 
     trzeba to zwraca odleg³o¶æ która odpowiada drodze przez krawêd¼
     ekranu. *)     
  method board_distance: c_pos -> float
  
  (** Zwróci w formacie "(x, y)", np. "(12.3, 45.6)" *)
  method to_string: string
  
  (** {1 Niniejsze funkcje korzystaj± z obiektu c_pos jakby by³ obiektem
     funkcyjnym: nie modyfikuj± jego zawarto¶ci, zwracaj± nowy obiekt
     o odpowiednio wyliczonych atrybutach.} *)
     
  method copy: 'a
  method copy_add_i: int -> int -> 'a
  method copy_add: 'a -> 'a 
  method copy_add_f: float -> float -> 'a
  method copy_move_angle: float -> float -> 'a
end

(** Zwraca losow± pozycjê na planszy. *)
val new_random_pos: unit -> c_pos

(** [new_random_further pos min_distance] zwraca losow± pozycjê na 
   planszy która jest bardziej oddalona od pos ni¿ min_distance
   (gdzie odleg³o¶æ mierzona jest przez [c_pos#board_distance] a wiêc
   uwzglêdnia zawijanie planszy). Podawaj zawsze [min_distance] >= 0,
   podawaj te¿ zawsze takie [min_distance] ¿eby odpowiednia pozycja
   na planszy by³a w ogóle mo¿liwa (bo to jest zaimplementowane
   jako wywo³ywanie [new_random_pos] do skutku wiêc niemo¿liwe
   do spe³nienia [min_distance] spowoduje zawieszenie programu). *)
val new_random_pos_further: c_pos -> float -> c_pos

(** [set_caption s] sets title and icon of our window to something
   like ["Bad Blaster - " ^ s].
   Actually it is smarter, so it doesn't look strange when [s] = "".    
   Don't use [Sdlwm.set_caption] - this function should be used in
   BadBlaster as the only possible way to change title. *)
val set_caption: string -> unit

(** [load_image basename with_alpha] ³aduje obrazek optymalizuj±c 
   jego format pod k±tem wy¶wietlania na ekranie.
   Obrazek jest ³adowany z katalogu [data_path ^ "images/"].
   Podaj w drugim parametrze czy obrazek ma byæ wyswietlany z 
   alpha channelem. 
   
   Uwaga : wywo³uj dopiero wtedy gdy wiesz ¿e [set_video_mode] SDLa 
   zosta³o ju¿ wykonane ! *)
val load_image: string -> bool -> Sdlvideo.surface
