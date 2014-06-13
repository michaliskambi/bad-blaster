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

open Base;;
open BbBase;;
open Sdlvideo;;
open SdlUtils;;

class virtual c_moveable start_pos =
object (self)
  val mutable f_pos: c_pos = start_pos
  method pos = f_pos
  method set_pos value = f_pos <- value
  
  method virtual draw: Sdlvideo.surface -> unit
    
  method virtual move: float -> unit
  
  method virtual size: int
  
  method image_start_pos: c_pos =
    self#pos#copy_add_i (- self#size/2) (- self#size/2)
  
  method is_collision (b:c_moveable) =
    let circle_intersect x1 y1 radius1 x2 y2 radius2 =
      (sqr (x1 - x2)) + (sqr (y1 - y2)) < sqr (radius1 + radius2) in
    let moveable_to_circle m = 
      (m#pos#int_x, m#pos#int_y, (m#size/2)) in
    let (x1, y1, r1) = moveable_to_circle self and
        (x2, y2, r2) = moveable_to_circle b 
    in
    (* Zeby uwzglednic ze oba obiekty (self i b) przewijaja sie przez
       krawedzie planszy mozna zastosowac nastepujacy pomysl:
       zamiast badac jedna kolizje (obiekt 1 z obiektem 2)
       badaj 9 kolizji : 
         obiekt 1 z obiektem 2,
         obiekt 1 przesuniety o board_width w prawo z obiektem 2,
         obiekt 1 przesuniety o board_width w lewo z obiektem 2,
       itd. Czyli tworzymy 8 dodatkowych "obrazow" obiektu 1 przesunietych 
       o board_width/height w obu kierunkach. 
       
       Mozna to jeszcze zoptymalizowac: wiemy ze nasze obiekty nie beda zbyt
       du¿e, na pewno bêd± mia³y mniejsze rozmiary ni¿ min(board_width, 
       board_height)/2. Z czego wynika ze jesli obiekt 2 jest na prawej
       polowie board to nie ma sensu rozwazac 3 mozliwosci gdzie 
       obiekt 1 jest przenoszony o -board_width. Uogolniajac ten przypadek
       zostaja nam 4 mozliwosci do sprawdzenia zamiast 9. *)
    let x1_increase = (if x2>board_width()/2 then 1 else (-1)) * board_width() in
    let y1_increase = (if y2>board_width()/2 then 1 else (-1)) * board_height() in
      (circle_intersect x1               y1               r1 x2 y2 r2) ||
      (circle_intersect (x1+x1_increase) y1               r1 x2 y2 r2) ||
      (circle_intersect x1               (y1+y1_increase) r1 x2 y2 r2) ||
      (circle_intersect (x1+x1_increase) (y1+y1_increase) r1 x2 y2 r2)
      
  method fired_rocket_start_distance (_:float) (rocket:c_moveable) =
    (* size/2 przyjmowane jest jako radius obrazka;
       dodajemy + 2 dla pewnosci, 2 jest wieksze od sqrt2 wiec na pewno
       zwiekszy polozenie rakiety przynajmniej o 1 pixel dalej) *)
    float_of_int ((self#size + rocket#size)/2 +2)      
end;;

class virtual c_singleimg_moveable start_pos f_image =
let (f_image_width, f_image_height, _) = surface_dims f_image in
object (self)
  inherit c_moveable start_pos 
  
  method draw dst = 
    let p = self#image_start_pos in
      blit_surface_wrapping f_image dst p#int_x p#int_y
    
  method size = f_image_width
  
  initializer
    assert (f_image_width = f_image_height);
end;;

class virtual c_rotated_moveable start_pos start_angle init_image_rot =
object (self)
  inherit c_moveable start_pos

  val mutable f_angle = start_angle
  method angle = f_angle
  method set_angle new_angle = f_angle <- new_angle

  val f_image_rot: BbRotatedImage.c_rotated_image = init_image_rot
  method draw dst = 
    let p = self#image_start_pos in
      f_image_rot#draw f_angle dst p#int_x p#int_y

  method size = f_image_rot#size
end;;
