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

(** Operacje zwi±zane z czasem (na bazie [Sdltimer]). *)

(** Wywo³uj zawsze gdy zaczniesz renderowaæ klatkê. *)
val frame_render_begin: unit -> unit

(** Wywo³uj zawsze gdy skoñczysz renderowaæ klatkê;
   zwróci warto¶æ odwrotnie proporcjonaln± do FPS (liczonego na podstawie 
   czasu renderowania tej klatki), czyli tzw. "game_speed".
   Przyjmuje ¿e 20 klatek na sekundê oznacza game_speed = 1.0.
   game_speed jest u¿ywane do time-based animation, czyli ¿eby
   ruch wszystkiego na wolniejszych komputerach by³ szybszy (na 1 klatkê),
   w ten sposób gra dzia³a tak samo szybko na wszystkich komputerach. 
   
   Ta procedura jest te¿ odpowiedzialna za uaktualnianie co jaki¶
   czas tytu³u okienka aby wypisac ilo¶æ FPS naszego programu. *)
val frame_render_end: unit -> float
