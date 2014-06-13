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

(** Ten modu� dostarcza abstrakcyjn� klas� [c_moveable] razem z 
   pewnymi pomocniczymi rzeczami jak podklasy [c_singleimg_moveable]
   i [c_rotated_moveable]. *)

(** [c_moveable] to klasa reprezentuj�ca obiekty kt�re mo�na scharakteryzowa�
   przez pozycj� na planszy (w sensie klasy [c_pos]) i obrazek 
   (w sensie surface SDLa) oraz operacj� [move] kt�ra odzwierciedla
   �e obiekt jako� zmienia si� wraz z up�ywem czasu. 
   Klasa ta zapewnia te� podstawowe metody do badania kolizji,
   wszystkie metody badania kolizji w tym programie opieraj� si� 
   na nich.
   
   Parametry przy konstruowaniu : pocz�tkowa pozycja. *)
class virtual c_moveable: BbBase.c_pos ->
object
  method pos: BbBase.c_pos
  
  (** Klasa pos jest modyfikowalna wi�c w zasadzie poni�sza metoda jest
     zb�dna; ale czasem mo�e by� wygodna. *)
  method set_pos: BbBase.c_pos -> unit
  
  (** Rysuje siebie na zadanej powierzchni, w taki spos�b �e [self#pos]
     wypadnie na �rodku rysowanego obszaru. *)
  method virtual draw: Sdlvideo.surface -> unit
    
  (** Podaj [game_speed]. W odpowiedzi zmieni atrybuty obiektu uwzgledniaj�c
     odpowiedni up�yw czasu. Oznacza to �e np. przesunie 
     i obr�ci statek zgodnie z aktualnymi pr�dko�ciami ruchu i obrotu, 
     �e pr�dko�ci te zmniejsz� si� nieco itd. *)
  method virtual move: float -> unit
  
  (** Wszystkie obiekty moveable mieszcz� si� w kwadracie.
     Ta metoda zwraca jego rozmiar. Tym samym zwraca ona rozmiar
     obszaru w kt�rym obiekt b�dzie rysowany w [draw]. *)
  method virtual size: int
  
  (** Na podstawie [size] i [pos] oblicza gdzie na ekranie powinien zaczyna� 
     si� prostok�t obrazka o rozmiarach [size] x [size] kt�rego �rodek
     mia�by trafi� w [pos]. Przydatne dla podklas przy implementacji
     metody [draw]. *)
  method image_start_pos: BbBase.c_pos
  
  (** W idealnym �wiecie [is_collision b] sprawdza�oby czy dwa obiekty 
     koliduj� ze sob�, tzn. zachodz� na siebie w punkcie planszy gdzie
     oba obrazki maj� alpha channel nieprzezroczysty.
     [self] i [b] mog� wi�c s�u�y� do odczytania ich width/height oraz
     do odczytu ich kanalu alpha.  
     Zak�adamy przy tym �e [self] i [b] si� przewijaj� przez kraw�dzie planszy.

     Takie drobiazgowe sprawdzanie jest
     konieczne �eby nigdy nie bylo wida� jakby
     "rakieta nie trafi�a w m�j statek a program uzna� �e m�j statek 
     jest zestrzelony !" albo "wydawa�o mi si� �e rakieta przeszla na 
     wylot przez m�j statek a program nie zauwa�y� �adnej kolizji". 

     A teraz "back to reality": w praktyce polegamy na fakcie �e wszystkie
     obiekty [c_moveable] kt�rych b�dziemy u�ywa� w tej grze b�d� mia�y obrazki
     kt�re "stosunkowo dobrze" (cokolwiek by to mia�o znaczy�)
     mieszcz� si� w kole wpisanym w ich kwadrat (acha, polegamy te� na fakcie
     �e s� kwadratami, nie tylko prostok�tami...) 
     i robimy proste sprawdzenie czy te dwa ko�a si� 
     przecinaj�. Uwzgl�dniamy przy tym ci�gle fakt �e obrazki mog� si� przewija�.
     Ten modu� jest zrobiony wla�nie po to �ebym w razie czego 
     (czytaj: "gdy to przybli�enie przestanie by� sensowne") mog�
     zmieni� implementacj� kolizji. *)  
  method is_collision: c_moveable -> bool
  
  (** [fired_rocket_start_distance angle rocket]:
     w jakiej minimalnie odleglo�ci od #pos powinno byc [rocket#pos]
     �eby [rocket] nie kolidowalo z nami. Zak�adamy przy tym �e rakieta
     odpalona jest pod k�tem [angle].

     To jest potrzebne dla [c_ship#fire_rocket] ktore chce odpalaj�c rakiet�
     umie�cic j� nieco przed statkiem w taki sposob �eby nowo odpalona
     rakieta nie spowodowala od razu kolizji ze statkiem ktory j� wystrzeli�.
     Implementacja tego zale�y oczywi�cie od implementacji [is_collision]
     i dlatego jest wrzucone obok [is_collision], do tej samej klasy w tym
     samym module. *)
  method fired_rocket_start_distance:  float -> c_moveable -> float  
end

(** [c_singleimg_moveable] to banalna podklasa [c_moveable] kt�ra implementuje
   metody [draw] i [size] zawsze u�ywaj�c ten sam podany przy inicjalizacji
   obiektu obrazek. 
   
   Podany obrazek musi by� kwadratem. *)
class virtual c_singleimg_moveable: BbBase.c_pos -> Sdlvideo.surface ->
object
  inherit c_moveable
  
  (** Rysuje zawsze ten sam obrazek kt�ry poda�es przy inicjalizacji obiektu. *)
  method draw: Sdlvideo.surface -> unit
  
  method size: int
end

(** [c_rotated_moveable] do zestawu cech [c_moveable] dodaje jeszcze
   [angle], czyli kierunek w kt�rym aktualnie obiekt jest zwr�cony. 
   Jednocze�nie [c_rotated_moveable] implementuje metody [draw] i [size]
   realizuj�c je przez klas� [c_rotated_image] aby wizualizowa�
   aktualny [angle] obiektu na ekranie. 
   
   Parametry konstruktora: pocz�tkowa pozycja, pocz�tkowy [angle]
   (patrz metoda [angle] po konwencj� podawania [angle])
   i obiekt obrazk�w klasy [c_rotated_image] (ten obiekt nie b�dzie
   modyfikowany nigdzie w �rodku implementacji [c_rotated_moveable]). *)
class virtual c_rotated_moveable: 
  BbBase.c_pos -> float -> BbRotatedImage.c_rotated_image ->
object
  inherit c_moveable
  
  (** Aktualny kierunek w kt�rym zwr�cony jest ten obiekt.  
     Patrz [set_angle]. Zwracany tutaj [angle] nie musi by� w zakresie
     \[0; 360\]. *)     
  method angle: float
  
  (** Ustaw angle, interpretacja:
       0.0 = dzi�b statku jest skierowany dokladnie w prawo, tzn. +X.
       0.0 - 360.0 = obracamy si� CCW, 
     warto�ci <0 lub >360 s� interpretowane jakby by�y odpowiednio
     przesuni�te o wielokrotno�� 360.0. *)
  method set_angle: float -> unit

  (** Rysuje uwzgl�dniaj�c aktualny obr�t obiektu. *)
  method draw: Sdlvideo.surface -> unit   
  
  method size: int
end

