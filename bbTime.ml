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

open Sdltimer;;
open BbBase;;
open Base;;
open SdlUtils;;

let last_frame_render_begin_time = ref None;;
let last_title_update_time = ref None;;

(* Czas po ktorym title okienka powinien zostac uaktualniony
   zeby pokazywal nowe FPS, w milisekundach. Uzywamy tego bo
   zbyt czeste (np. w kazdym frame_render_end) zmienianie tytulu okienka 
   jest raczej meczace dla uzytkownika. *)
let time_to_update_title = 2000 (* = 2 sekundy *) ;;

let frame_render_begin () =
  last_frame_render_begin_time := Some (get_ticks ())
;;

let frame_render_end () =
  match !last_frame_render_begin_time with
    | Some begin_time ->
        (* Uaktualnij FPS w tytule okienka. Tak naprawde nasze FPS
           jest dosc kiepskie bo zakladamy po prostu ze klatka ktora
           wlasnie zrobilismy miala "przecietny" czas renderowania.
           Ale dla tak prostej gry jak BadBlaster to powinno byc
           wystarczajace zalozenie. *)          
        if ticks_check_passed !last_title_update_time time_to_update_title then
        begin
          set_caption (Printf.sprintf "FPS : %f"
            (1000.0 /. float_of_int (ticks_passed begin_time)) );
          last_title_update_time := Some (get_ticks ())
        end else ();
        
        (* zwroc aktualny game_speed na podstawie FPS dla ostatniej klatki.
           Przyjmujemy ze game_speed = 1.0 gdy robimy 20 klatek 
           na sekunde, czyli gdy ostatnia klatka renderowala sie
           w 1000/20 = 50 milisekund.  *)
        float_of_int (ticks_passed begin_time) /. 50.0;
        
    | None -> raise (E_Internal_Error 
        "No frame_render_begin yet, but frame_render_end called")
;;
