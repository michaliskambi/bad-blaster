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

(** Ten modu� implementuje procedury write* s�u��ce do rysowania
   napis�w przy u�yciu literek zapisanych na sta�e w obrazku 
   images/font_002.png *)

type t_write_pos = Middle | Normal of int

(** [write surface x y text]: napisz [text] na [surface] na pozycji [x], [y]. 
   U�ywaj w napisie tylko znak�w dost�pnych na
   images/font_002.png oraz ma�ych liter (b�d� automatycznie 
   zamieniane na du�e) p znak�w "\[" i "\]" (b�d� automatycznie 
   zamieniane na "(" i ")" kt�re w naszej czcionce i tak wygl�daj�
   bardziej jak nawiasy klamrowe ni� okr�g�e). 
   
   Naturalnie wymaga zainicjowanego video SDLa. 
   Uwaga : string nie jest w �aden spos�b �amany, sam musisz zadba�
   �eby nie zosta� obci�ty przez kraw�dzie ekranu. 
   Jako wspo�rzedn� x mo�esz poda� [Middle] w znaczeniu "wy�rodkuj 
   lini� na zadanym [surface]". *)
val write: Sdlvideo.surface -> t_write_pos -> int -> string -> unit

(** Wywoluje po kolei write z ka�dym elementem listy string�w.
   Kolejne stringi s� wypisywane coraz ni�ej. 
   Tutaj mo�esz poda� [Middle] tak�e zamiast wsp�rz�dnej y -
   spowoduje to wy�rodkowanie ca�ej listy string�w na ekranie. *)
val write_list: Sdlvideo.surface -> t_write_pos -> t_write_pos -> string list -> unit
