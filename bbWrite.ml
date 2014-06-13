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

(* implementacja tego modulu jest w roznych miejscach zwiazana
   z rozmieszczeniem literek na obrazku font_002.png.
   
   Obrazek ten ma rozmiat 320 x 192, 6 wierszy po 10 literek.
   Literki zaczynaja sie od spacji, potem ida po kolei
   kodami przechodzac przez cyfry i duze litery az zatrzymuja sie
   na znaku nastepujacym po 'Z'. Ale nie wszystkie znaczki po drodze
   tam sa. Konkretnie sa tylko
   - duze litery
   - cyfry 
   - ? = ; : . , ( ) ' "" !
*)

open Base;;
open BbBase;;
open Sdlvideo;;

let char_width = 320 / 10;;
let char_height = 192 / 6;;

(** [drawn_char_width] jest u¿ywane aby ustaliæ jak daleko przesuwamy siê
   w prawo po narysowaniu jednego znaku. Wbrew pozorem to wcale 
   niekoniecznie jest równe char_width - mo¿e to byæ co¶ mniejszego.
   Chodzi tu tylko o estetykê. *)
let drawn_char_width = char_width - 7;;

(** Uwagi podobne jak przy [drawn_char_width]: mimo ¿e mog³oby to byæ
   równe char_height to jednak bardziej estetyczne mo¿e byæ co¶ innego. *)
let drawn_line_height = char_height - 4;;

let f_image_font: Sdlvideo.surface option ref = ref None;;
(** Uzywamy zawsze funkcji image_font zeby zaladowac obrazek font_002.png
   dopiero w momencie pierwszego wywolania write\[_char\] *)
let image_font () =
  match !f_image_font with
    | None -> let img = load_image "font_002.png" true in
                f_image_font := Some img;
                img
    | Some img -> img
;;

let char_uppercase c = 
  (String.uppercase (String.make 1 c)).[0]
;;

(** Postaraj siê zamieniæ znak c na taki który mamy dostêpny w czcionce. *)
let char_corrected c =  
  match c with
    | '[' -> '('
    | ']' -> ')'
    | _ -> char_uppercase c
;;

let write_char surf x y c =
  let i = (int_of_char (char_corrected c)) - (int_of_char ' ') in
    blit_surface
      ~src:(image_font())
      ~src_rect:(rect ((i mod 10)*char_width) ((i / 10)*char_height)
        char_width char_height)
      ~dst:surf
      ~dst_rect:(rect x y 0 0) ()
;;

type t_write_pos = Middle | Normal of int;;

let rec write surf xpos y s =
  match xpos with
    | Normal x ->
        for i = 0 to (String.length s - 1) do
          write_char surf (x + i * drawn_char_width) y s.[i]
        done  
    | Middle ->
        let (w,_,_) = surface_dims surf in
          write surf (Normal ((w - drawn_char_width * (String.length s)) / 2)) y s
;;

let rec write_list surf xpos ypos str_list =
  match ypos with
    | Normal y ->
      begin 
        match str_list with
          | [] -> ()
          | s::ss -> write surf xpos y s;
                     write_list surf xpos (Normal (y + drawn_line_height)) ss
      end
    | Middle ->
        let (_, screen_height, _) = surface_dims surf in
          write_list surf Middle (Normal ((screen_height - 
            (List.length str_list) * drawn_line_height) / 2)) str_list
;;
