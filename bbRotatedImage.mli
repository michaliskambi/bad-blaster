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

(** Modu³ zawieraj±cy klasê [c_rotated_image]. *)

(** Klasa c_rotated_image reprezentuje obrazek który mo¿e byæ obracany.
   Wewnêtrznie mamy po prostu obrazek-pasek na którym zapisane s± 
   po kolei zawczasu poobracane ImageMagickiem obrazki i
   w zale¿nosci od zadanego k±ta u¿ywamy odpowiedniego obrazka.
   
   Przy konstruowaniu podaj nazwê obrazka-paska. 
   Ale uwaga : z zewn±trz tego modulu u¿ywaj zawsze [new_rotated_image]
   zamiast wywo³ywaæ [new c_rotated_image]. 
   
   Konstruuj ten obiekt tylko je¶li masz pewno¶æ ¿e podsystem video 
   SDLa zosta³ ju¿ zainicjowany. *)
class c_rotated_image: string -> 
object
  (** [draw angle dst x y] gdzie angle to k±t w stopniach w 
     standardowym znaczeniu
     (0.0 = co¶ co nazywamy "przodem" w prawo, zwiêkszanie = obracanie CCW,
     zakres dowolny, nie tylko \[0; 360\]), x,y to pozycja na [dst]
     (x i y w odpowiednim zakresie, 
        x in \[0; dst.width-1\], y in \[0; dst.height-1\]).
     Rysuje odpowiednio obrócony obrazek na pozycji x,y, 
     przy czym obrazek przy rysowaniu "zawijamy" za brzegi dst. *)
  method draw: float -> Sdlvideo.surface -> int -> int -> unit
  
  (** Wszystkie obrazki rysowane przez [draw] s± kwadratami o takim 
     samym rozmiarze, mo¿na go odczytaæ t± funkcj±. *)
  method size: int
  
  (** Ju¿ przeliczone [size * sqrt2]. Je¶li kiedy¶ tutejsze obrazki
     nie bêda ju¿ zawsze kwaratami to implementacja tego zmieni siê
     na [sqrt ( width^2 + height^2 )] *)
  method diagonal: float
end

(** My¶l o tej funkcji jak o wywo³aniu [new c_rotated_image].
   Ró¿nica jest taka ¿e ta funkcja cache'uje swoje wyniki, 
   co znaczy ¿e je¿eli drugi raz wywo³asz [new_rotated_image]
   z tym samym argumentem to dostaniesz ten sam obiekt co poprzednio
   (nie bêdzie wywo³ywane drugi raz [new c_rotated_image],
   które trwa do¶æ wolno (musi za³adowac obrazki z dysku),
   w rezultacie czego wszystko zadzia³a szybko).
   Poniewa¿ obiekt klasy [c_rotated_image] nie daje siê w ¿aden sposób
   modyfikowaæ wiêc nie ma problemu z tym ¿e ten sam
   obiekt bêdzie mia³ referencjê z wielu miejsc. *)
val new_rotated_image: string -> c_rotated_image
