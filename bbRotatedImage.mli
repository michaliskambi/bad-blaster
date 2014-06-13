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

(** Modu� zawieraj�cy klas� [c_rotated_image]. *)

(** Klasa c_rotated_image reprezentuje obrazek kt�ry mo�e by� obracany.
   Wewn�trznie mamy po prostu obrazek-pasek na kt�rym zapisane s� 
   po kolei zawczasu poobracane ImageMagickiem obrazki i
   w zale�nosci od zadanego k�ta u�ywamy odpowiedniego obrazka.
   
   Przy konstruowaniu podaj nazw� obrazka-paska. 
   Ale uwaga : z zewn�trz tego modulu u�ywaj zawsze [new_rotated_image]
   zamiast wywo�ywa� [new c_rotated_image]. 
   
   Konstruuj ten obiekt tylko je�li masz pewno�� �e podsystem video 
   SDLa zosta� ju� zainicjowany. *)
class c_rotated_image: string -> 
object
  (** [draw angle dst x y] gdzie angle to k�t w stopniach w 
     standardowym znaczeniu
     (0.0 = co� co nazywamy "przodem" w prawo, zwi�kszanie = obracanie CCW,
     zakres dowolny, nie tylko \[0; 360\]), x,y to pozycja na [dst]
     (x i y w odpowiednim zakresie, 
        x in \[0; dst.width-1\], y in \[0; dst.height-1\]).
     Rysuje odpowiednio obr�cony obrazek na pozycji x,y, 
     przy czym obrazek przy rysowaniu "zawijamy" za brzegi dst. *)
  method draw: float -> Sdlvideo.surface -> int -> int -> unit
  
  (** Wszystkie obrazki rysowane przez [draw] s� kwadratami o takim 
     samym rozmiarze, mo�na go odczyta� t� funkcj�. *)
  method size: int
  
  (** Ju� przeliczone [size * sqrt2]. Je�li kiedy� tutejsze obrazki
     nie b�da ju� zawsze kwaratami to implementacja tego zmieni si�
     na [sqrt ( width^2 + height^2 )] *)
  method diagonal: float
end

(** My�l o tej funkcji jak o wywo�aniu [new c_rotated_image].
   R�nica jest taka �e ta funkcja cache'uje swoje wyniki, 
   co znaczy �e je�eli drugi raz wywo�asz [new_rotated_image]
   z tym samym argumentem to dostaniesz ten sam obiekt co poprzednio
   (nie b�dzie wywo�ywane drugi raz [new c_rotated_image],
   kt�re trwa do�� wolno (musi za�adowac obrazki z dysku),
   w rezultacie czego wszystko zadzia�a szybko).
   Poniewa� obiekt klasy [c_rotated_image] nie daje si� w �aden spos�b
   modyfikowa� wi�c nie ma problemu z tym �e ten sam
   obiekt b�dzie mia� referencj� z wielu miejsc. *)
val new_rotated_image: string -> c_rotated_image
