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

(** Ko�cowe klasy dla wszystkich rzeczy kt�re pojawiaj� si� na planszy 
   ([c_rocket], [c_ship], [c_computer_ship], [c_planet]),     
   globalne zmienne przechowuj�ce aktualny stan planszy
   ([rockets], [player_ship], [enemy_ships], [planet])
   i podstawowe funkcje do ich obs�ugi
   ([new_game] do inicjalizacji).

   Important things:
   - Before you create any object of class [c_rocket], [c_ship], 
     [c_computer_ship] or [c_planet] you must first
     initialize SDL with it's video subsystem (that's because
     creating these objects requires loading some images,
     and we must have SDL video initialized to be sure that we can do that).
     In particular, you must initialize video subsystem of SDL
     before calling [new_game()].

   - Before you access [planet], [rockets], [enemy_ships] and [player_ship] you
     must call [new_game()].

   - Only the call to [new_game()] can change the values returned by    
     [player_ship] and [planet] functions.
     This is useful in badBlaster.ml to do a small "trick" only
     to be able to write [player_ship#fire_rocket] instead of
     very ugly [(player_ship())#fire_rocket].
*)

(** c_planet [circle_middle] [moves] tworzy planet�. 
   To jest bardzo prosty obiekt. Nie obraca si� (wi�c zawsze jest 
   wy�wietlany jako ten sam obrazek). Je�li podasz [moves] = false
   to nie b�dzie si� te� rusza�. Je�li podasz [moves] = true to b�dzie
   wolno kr��y� po okr�gu. *)
class c_planet: BbBase.c_pos -> bool ->
object
  inherit BbMoveable.c_singleimg_moveable
  method move: float -> unit
end

(** Not modified in this module, only initialized in [new_game] *)
val planet: unit -> c_planet

class c_rocket: BbBase.c_pos -> float ->
object
  inherit BbMoveable.c_rotated_moveable
  
  (** Rakieta kt�ra nie jest [active] nie powinna znajdowa� si� na planszy
     bo zosta�a ju� "rozbrojona". Ka�da rakieta po pewnym czasie sama
     si� rozbraja - to po to �eby po planszy gry nie lata� deszcz rakiet. *)
  method active: bool
  
  (** [move] przesuwa rakiet� i mo�e te� zmieni� jej stan [active] *)
  method move: float -> unit
end

(** Ta lista b�dzie modyfikowana w tym module tylko z 
   - [c_ship#fire_rocket] (a wiec i z [c_computer_ship#move] kt�re mo�e 
     wywo�ywac [fire_rocket]). Rakiety beda tam tylko dodawane. 
   - [new_game] (b�dzie tam inicjalizowana od nowa) *)
val rockets: c_rocket list ref

(** [c_ship] to statek kt�ry "nie kieruje sam sob�",
   tym samym jest to klasa wla�ciwa dla statku gracza oraz nadklasa dla
   statku komputera. *)
class c_ship: BbBase.c_pos -> float -> BbRotatedImage.c_rotated_image ->
object
  inherit BbMoveable.c_rotated_moveable
  
  (** Zainicjuj zmian� [angle]. Podaj czy ccw (ccw powoduje zwi�kszanie 
     [angle]). *)
  method rotate: bool -> unit
  
  method thrust: unit
  
  (** [move] dla statku mo�e zmieni� aktuany [angle] i [pos] statku
     na podstawie aktualnych szybko�ci ruchu naprz�d i obrotu,
     mo�e te� zmienia� te szybko�ci. 
     W [move] jest realizowana ca�a sztuczna inteligencja statk�w
     komputera. *)
  method move: float -> unit
  
  (** Statek nie mo�e dowolnie cz�sto odpalac rakiet. 
     Jest to do�� uzasadnione utrudnienie gry dla statku gracza 
     i bardzo rozs�dne ograniczenie dla statk�w komputera 
     (kt�re teoretycznie mog�yby przecie� swobodnie wystrzeli�
     mase rakiet w jednym [move]). 
     Nie trzeba sprawdza� wyniku tej funkcji przed wywo�aniem
     fire_rocket - fire_rocket po prostu zachowa si� jak NOP
     je�li je wywolasz przy [not is_able_to_fire_rocket]. 
     
     Notka : wynik tej metody zale�y od aktualnego czasu.
     Wi�c nie mo�na nigdzie polega� na tym �e "to wywolanie fire_rocket
     zadzia�a jak NOP bo przed chwil� [is_able_to_fire_rocket]
     zwr�ci�o false" bo przecie� czas si� mog� akurat zmieni�. *)
  method is_able_to_fire_rocket: bool
  
  (** Jezeli [is_able_to_fire_rocket] to dodaj do [rockets] rakiet� odpalon� z 
     aktualnego [pos] i [angle], wpp. NOP. *)
  method fire_rocket: unit
end

(** Not modified in this module, only initialized in [new_game]. *)
val enemy_ships: c_ship list ref

(** Not modified in this module, only initialized in [new_game]. *)
val player_ship: unit -> c_ship

class c_computer_ship: BbBase.c_pos -> float -> BbRotatedImage.c_rotated_image ->
object
  inherit c_ship
  
  (** Zwraca w kt�r� stron� i o ile nale�y zmieni� aktualne angle
     aby by� nakierowanym idealnie w stron� pozycji p.
     Zwraca warto�� z przedzia�u \[-180., 180.\].
     Tym samym jednocze�nie m�wi w kt�r� stron� nale�y zrobi� rotate
     aby skierowa� si� w stron� p (i w kt�r� stron� skierowa� si�
     aby oddali� si� od p) i m�wi jak bardzo teraz jeste�my nakierowani
     na p. 
     
     Przydatne g��wnie w podklasach aby implementowa� sztucz� inteligencj�. *)
  method angle_change_to_direction: BbBase.c_pos -> float
  
  (** [move] statku komputera opr�cz wywo�ania [super#move] 
     mo�e wywo�ywa� jeszcze jakie� inne akcje obiektu [c_ship] - 
     takie same jakie dla statku gracza s� inicjowane przy
     obs�udze komunikat�w od u�ytkownika.
     Czyli (chwilowo, lista mo�e ulec z czasem zmianie) [thrust], 
     [rotate] i [fire_rocket]. 
     
     Fakt �e narzucam sobie �e statek komputera w swoim [move] wywo�uje
     sam z siebie tylko metody dost�pne "prawie bezpo�rednio"
     dla gracza nie gwarantuje jeszcze wcale �e statek komputera ma r�wne 
     szanse (bo np. m�g�bym zrobi� statek-kamikadze kt�ry podlatuje do statku
     gracza �eby si� z nim zderzy�). Ale jest to dobry pocz�tek. *)
  method move: float -> unit
end

type t_enemies_counts = { 
  ec_stupido:int ref; 
  ec_sniper:int ref; 
  ec_quickie:int ref; 
}  

(** [new_game enemies_count planet_moves]
   initializes [planet], [rockets], [enemy_ships], [player_ship] to 
   some values. You must call this function before
   using any of these values. You can call this as many times
   as you want to initialize new game. 
   
   [planet_moves] podaje czy utworzona planeta ma powoli kr��y� po okr�gu.
   
   [enemies_count] podaje jak wiele statk�w wroga z danym AI chcesz mie�:
   ile statk�w typu "stupido", ile typu "sniper", ile typu "quickie". 
   Wszystkie te parametry musz� by� >= 0 i musz� si� sumowa� do
   czego� > 0. *)
val new_game: t_enemies_counts -> bool -> unit
