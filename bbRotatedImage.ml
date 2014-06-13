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
open BbBase;;
open SdlUtils;;

(* degree_step = wewnetrzna stala modulu, musi byc rowna DEGREE_STEP
   z ktorym zostaly wygenerowane obrazki _strip. *)
let degree_step = 2;;

class c_rotated_image image_strip_filename =
object (self)
  val image_strip: surface = load_image image_strip_filename true
  
  method draw angle dst x y =
    let
      (* Uzywam clamped bo, generalnie, kiedy przechodzimy z floatow
         na inty w jakims zakresie to lepiej sie upewnic.
         W tym konkretnym przypadku moznaby sie obawiac wartosci
         w okolicach tuz ponizej wielokrotnosci 360.0 *)
      image_num = ( clamped
        (int_floor (angle_deg_norm angle) / degree_step)
        0 (360/degree_step - 1) )
    in
      blit_surface_wrapping_srcrect
        {r_x=image_num*self#size; r_y=0; r_w=self#size; r_h=self#size}
        image_strip dst x y

  val mutable f_size = 0
  method size = f_size

  val mutable f_diagonal = 0.0
  method diagonal = f_diagonal

  initializer
    ( let (_, s, _) = surface_dims image_strip in f_size <- s );
    f_diagonal <- sqrt2 *. (float_of_int self#size)
end

let rotated_images_cache = ref [];;

let new_rotated_image image_base =
  try
    List.assoc image_base !rotated_images_cache
  with Not_found ->
    let result = new c_rotated_image image_base in
      listr_add rotated_images_cache (image_base, result);
      result
;;
