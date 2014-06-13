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

(** Ten modu³ implementuje procedury write* s³u¿±ce do rysowania
   napisów przy u¿yciu literek zapisanych na sta³e w obrazku 
   images/font_002.png *)

type t_write_pos = Middle | Normal of int

(** [write surface x y text]: napisz [text] na [surface] na pozycji [x], [y]. 
   U¿ywaj w napisie tylko znaków dostêpnych na
   images/font_002.png oraz ma³ych liter (bêd± automatycznie 
   zamieniane na du¿e) p znaków "\[" i "\]" (bêd± automatycznie 
   zamieniane na "(" i ")" które w naszej czcionce i tak wygl±daj±
   bardziej jak nawiasy klamrowe ni¿ okr±g³e). 
   
   Naturalnie wymaga zainicjowanego video SDLa. 
   Uwaga : string nie jest w ¿aden sposób ³amany, sam musisz zadbaæ
   ¿eby nie zosta³ obciêty przez krawêdzie ekranu. 
   Jako wspo³rzedn± x mo¿esz podaæ [Middle] w znaczeniu "wy¶rodkuj 
   liniê na zadanym [surface]". *)
val write: Sdlvideo.surface -> t_write_pos -> int -> string -> unit

(** Wywoluje po kolei write z ka¿dym elementem listy stringów.
   Kolejne stringi s± wypisywane coraz ni¿ej. 
   Tutaj mo¿esz podaæ [Middle] tak¿e zamiast wspó³rzêdnej y -
   spowoduje to wy¶rodkowanie ca³ej listy stringów na ekranie. *)
val write_list: Sdlvideo.surface -> t_write_pos -> t_write_pos -> string list -> unit
