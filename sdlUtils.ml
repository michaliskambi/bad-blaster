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
open Bigarray;;

let rect_translate x y {r_x=old_x; r_y=old_y; r_w=w; r_h=h} =
  {r_x=x+old_x; r_y=y+old_y; r_w=w; r_h=h}
;;

let rect_wrap src_width src_height dst_width dst_height x0 y0 =
  let 
      (* cut_src_column kopiuje kolumne z src, nie martwiac sie 
         juz o to czy dst_x0 bedzie w dobrym zakresie (na pewno bedzie).
         cut_src_column musi sie zatroszczyc juz tylko o ew. podzial
         obrazka na dwie czesci wzdluz linii poziomej. *)
      cut_src_column src_xbegin src_xend dst_x0 =
      
      let (* cut_src zwraca juz pojedyncza pare prostokatow. *)
          cut_src src_ybegin src_yend dst_y0 = (            
            (rect src_xbegin src_ybegin 
                (src_xend - src_xbegin + 1) 
                (src_yend - src_ybegin + 1)),
             (rect dst_x0 dst_y0 0 0) )
      in
      
      (* zasadnicza tresc cut_src_column jest taka sama
         jak zasadnicza tresc rect_wrap, tyle ze zamiast
         y biore x, zamiast width - height, i zamiast cut_src_column
         robie cut_src *)
      if y0>dst_height - src_height then
      begin
        [ cut_src 0 (dst_height-y0) y0;
          cut_src (dst_height-y0+1) src_height 0 ]
      end else
        [ cut_src 0 src_height y0 ]
  in
  if x0>dst_width - src_width then
  begin
    (cut_src_column 0 (dst_width-x0) x0) @
    (cut_src_column (dst_width-x0+1) src_width 0)
  end else
    cut_src_column 0 src_width x0
;;

let blit_surface_center src dst =
  let (src_width, src_height, _) = surface_dims src and
      (dst_width, dst_height, _) = surface_dims dst in
  let dst_rect = 
    rect ((dst_width - src_width) / 2) ((dst_height - src_height) / 2) 0 0 in
    blit_surface ~src ~dst ~dst_rect ();
    dst_rect
;;      

let rec wait_for_keypress keylist = 
  assert (keylist <> []); 
  match Sdlevent.wait_event () with 
    | Sdlevent.KEYDOWN ({ Sdlevent.keysym=k } as e) when List.mem k keylist -> e
    | _ -> wait_for_keypress keylist (* tail-recursive *)
;;

let blit_surface_wrapping src dst x0 y0 =
  let (src_width, src_height, _) = surface_dims src and
      (dst_width, dst_height, _) = surface_dims dst in
    List.iter
      (function (src_rect, dst_rect) -> blit_surface
        ~src ~src_rect ~dst ~dst_rect ()) 
      (rect_wrap src_width src_height dst_width dst_height x0 y0)
;;

let blit_surface_wrapping_srcrect 
  { r_x=src_x0; r_y=src_y0; r_w=src_width; r_h=src_height }
  src dst x0 y0 = 
  let (dst_width, dst_height, _) = surface_dims dst in
    List.iter
      (function (src_rect_notransl, dst_rect) -> 
         let src_rect = rect_translate src_x0 src_y0 src_rect_notransl in
           blit_surface ~src ~src_rect ~dst ~dst_rect ()) 
      (rect_wrap src_width src_height dst_width dst_height x0 y0)  
;;

let tile_surface tile surf =
  let (surf_width, surf_height, _) = surface_dims surf and
      (tile_width, tile_height, _) = surface_dims tile in
  let i = ref 0 in
  while !i*tile_width < surf_width do
    let j = ref 0 in 
    while !j*tile_height < surf_height do
      blit_surface ~src:tile ~dst:surf 
        ~dst_rect:(rect (!i*tile_width) (!j*tile_height) 0 0) ();
      incr j
    done;
    incr i
  done
;;

let ticks_substract a b = a - b;;

(* notka : nie, z ponizszego zapisu ticks_passed nie mozna usunac
   parametru b, bo wtedy Ocaml obliczy wartosc ticks_passed
   przy inicjalizacji i nastepnym razem juz nie bedzie robil
   od nowa Sdltimer.get_ticks(). *) 
let ticks_passed b = ticks_substract (Sdltimer.get_ticks()) b;;

let ticks_check_passed time_option ticks_to_pass =
  match time_option with
    | None -> true
    | Some time when (ticks_passed time) > ticks_to_pass -> true
    | _ -> false
;;
