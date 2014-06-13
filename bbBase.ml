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

open Sdlvideo;;
open Base;;
open SdlUtils;;

let f_board_width  = ref 640;;
let f_board_height = ref 480;;
let board_width () = !f_board_width;;
let board_height() = !f_board_height;;
let board_width_f () = float_of_int(board_width());;
let board_height_f() = float_of_int(board_height());;

let init_board_size w h =
  f_board_width := w;
  f_board_height := h
;;

class c_pos x0 y0 =
object (self:'a)

  val mutable f_x = float_norm x0 (board_width_f ())
  val mutable f_y = float_norm y0 (board_height_f())
  method x = f_x
  method y = f_y
  
  method add (p:c_pos) = self#add_f p#x p#y
  
  method add_f ax ay =
    f_x <- float_norm (f_x +. ax) (board_width_f ());
    f_y <- float_norm (f_y +. ay) (board_height_f());
    
  method to_rect = { r_x=self#int_x; r_y=self#int_y; r_w=0; r_h=0; }
  
  method int_x = clamped (int_floor f_x) 0 (board_width()-1)
  method int_y = clamped (int_floor f_y) 0 (board_height()-1)

  method move_angle angle length =
    self#move_angle_rad (deg_to_rad angle) length

  method move_angle_rad angle_rad length =
    self#add_f (   length *. (cos angle_rad))
               (-. length *. (sin angle_rad))
              
  method angle_rad_in_direction (target:c_pos) = 
    (* Zamiast target#x/y ustalamy sobie target_x/y
       ktore zalatwiaja juz sprawe z tym ze plansza sie przewija. *)
    let target_x = 
      if abs_float (target#x -. self#x) < board_width_f() /. 2. then 
        target#x else
      if target#x > self#x then 
        target#x -. board_width_f() else
        target#x +. board_width_f()
    in
    let target_y =
      if abs_float (target#y -. self#y) < board_height_f() /. 2. then 
        target#y else
      if target#y > self#y then 
        target#y -. board_height_f() else
        target#y +. board_height_f()
    in    
    (* Zamiast self#y i target_y bedziemy brali (to_y self#y/target_y) 
       bo nasze y-ki sa w konwencji SDLa, 0 u gory i rosnie w dol. *)
    let to_y y = board_height_f() -. y in
      let almost_result =
        atan2 ((to_y target_y) -. (to_y self#y)) (target_x -. self#x) in
        (* Na koniec, atan2 zwraca wynik w przedziale [-pi, pi].
           My chcemy miec w [0; 2*pi]. *)
        if almost_result < 0. then almost_result +. (2. *. pi) else almost_result
        
  method angle_deg_in_direction (target:c_pos) =
    rad_to_deg (self#angle_rad_in_direction target)

  method move_to (target:c_pos) length =
    self#move_angle_rad (self#angle_rad_in_direction target) length
    
  method sqr_board_distance (a:c_pos) =
    let dx = ref (abs_float (self#x -. a#x)) in
    let dy = ref (abs_float (self#y -. a#y)) in
      if !dx > board_width_f () /. 2. then dx:=board_width_f () -. !dx;
      if !dy > board_height_f() /. 2. then dy:=board_height_f() -. !dy;
      (!dx *. !dx) +. (!dy *. !dy)
      
  method board_distance (a:c_pos) = sqrt (self#sqr_board_distance a)
  
  method to_string =
    "(" ^ (string_of_float f_x) ^ ", " ^ (string_of_float f_y) ^ ")"

  method copy = {< f_x=f_x; f_y=f_y >}
  
  method copy_add (a:'a) = self#copy_add_f a#x a#y
  
  method copy_add_i ax ay = self#copy_add_f (float_of_int ax) (float_of_int ay)
  
  method copy_add_f ax ay = {<
    f_x = float_norm (f_x +. ax) (float_of_int (board_width()));
    f_y = float_norm (f_y +. ay) (float_of_int (board_height())) >}
    
  method copy_move_angle angle length =
    let angle_rad = deg_to_rad angle in
      self#copy_add_f (   length *. (cos angle_rad))
                      (-. length *. (sin angle_rad));
end;;

let new_random_pos () = new c_pos
  (Random.float (float_of_int (board_width())))
  (Random.float (float_of_int (board_height())))
;;

let new_random_pos_further (pos:c_pos) min_distance = 
  let result = ref (new_random_pos()) in
    while (!result)#sqr_board_distance pos < (min_distance *. min_distance) do
      result := new_random_pos()
    done;
    !result
;;

let set_caption s =
  let t = "Bad Blaster" ^ (if s = "" then "" else (" - " ^ s)) in
    Sdlwm.set_caption t t
;;

let load_image basename with_alpha =
  display_format ~alpha:with_alpha
    (Sdlloader.load_image (data_path ^ "images/" ^ basename))
;;
