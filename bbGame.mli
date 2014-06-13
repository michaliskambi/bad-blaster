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

(** Koñcowe klasy dla wszystkich rzeczy które pojawiaj± siê na planszy 
   ([c_rocket], [c_ship], [c_computer_ship], [c_planet]),     
   globalne zmienne przechowuj±ce aktualny stan planszy
   ([rockets], [player_ship], [enemy_ships], [planet])
   i podstawowe funkcje do ich obs³ugi
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

(** c_planet [circle_middle] [moves] tworzy planetê. 
   To jest bardzo prosty obiekt. Nie obraca siê (wiêc zawsze jest 
   wy¶wietlany jako ten sam obrazek). Je¶li podasz [moves] = false
   to nie bêdzie siê te¿ rusza³. Je¶li podasz [moves] = true to bêdzie
   wolno kr±¿y³ po okrêgu. *)
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
  
  (** Rakieta która nie jest [active] nie powinna znajdowaæ siê na planszy
     bo zosta³a ju¿ "rozbrojona". Ka¿da rakieta po pewnym czasie sama
     siê rozbraja - to po to ¿eby po planszy gry nie lata³ deszcz rakiet. *)
  method active: bool
  
  (** [move] przesuwa rakietê i mo¿e te¿ zmieniæ jej stan [active] *)
  method move: float -> unit
end

(** Ta lista bêdzie modyfikowana w tym module tylko z 
   - [c_ship#fire_rocket] (a wiec i z [c_computer_ship#move] które mo¿e 
     wywo³ywac [fire_rocket]). Rakiety beda tam tylko dodawane. 
   - [new_game] (bêdzie tam inicjalizowana od nowa) *)
val rockets: c_rocket list ref

(** [c_ship] to statek który "nie kieruje sam sob±",
   tym samym jest to klasa wla¶ciwa dla statku gracza oraz nadklasa dla
   statku komputera. *)
class c_ship: BbBase.c_pos -> float -> BbRotatedImage.c_rotated_image ->
object
  inherit BbMoveable.c_rotated_moveable
  
  (** Zainicjuj zmianê [angle]. Podaj czy ccw (ccw powoduje zwiêkszanie 
     [angle]). *)
  method rotate: bool -> unit
  
  method thrust: unit
  
  (** [move] dla statku mo¿e zmieniæ aktuany [angle] i [pos] statku
     na podstawie aktualnych szybko¶ci ruchu naprzód i obrotu,
     mo¿e te¿ zmieniaæ te szybko¶ci. 
     W [move] jest realizowana ca³a sztuczna inteligencja statków
     komputera. *)
  method move: float -> unit
  
  (** Statek nie mo¿e dowolnie czêsto odpalac rakiet. 
     Jest to do¶æ uzasadnione utrudnienie gry dla statku gracza 
     i bardzo rozs±dne ograniczenie dla statków komputera 
     (które teoretycznie mog³yby przecie¿ swobodnie wystrzeliæ
     mase rakiet w jednym [move]). 
     Nie trzeba sprawdzaæ wyniku tej funkcji przed wywo³aniem
     fire_rocket - fire_rocket po prostu zachowa siê jak NOP
     je¶li je wywolasz przy [not is_able_to_fire_rocket]. 
     
     Notka : wynik tej metody zale¿y od aktualnego czasu.
     Wiêc nie mo¿na nigdzie polegaæ na tym ¿e "to wywolanie fire_rocket
     zadzia³a jak NOP bo przed chwil± [is_able_to_fire_rocket]
     zwróci³o false" bo przecie¿ czas siê mog³ akurat zmieniæ. *)
  method is_able_to_fire_rocket: bool
  
  (** Jezeli [is_able_to_fire_rocket] to dodaj do [rockets] rakietê odpalon± z 
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
  
  (** Zwraca w któr± stronê i o ile nale¿y zmieniæ aktualne angle
     aby byæ nakierowanym idealnie w stronê pozycji p.
     Zwraca warto¶æ z przedzia³u \[-180., 180.\].
     Tym samym jednocze¶nie mówi w któr± stronê nale¿y zrobiæ rotate
     aby skierowaæ siê w stronê p (i w któr± stronê skierowaæ siê
     aby oddaliæ siê od p) i mówi jak bardzo teraz jeste¶my nakierowani
     na p. 
     
     Przydatne g³ównie w podklasach aby implementowaæ sztucz± inteligencjê. *)
  method angle_change_to_direction: BbBase.c_pos -> float
  
  (** [move] statku komputera oprócz wywo³ania [super#move] 
     mo¿e wywo³ywaæ jeszcze jakie¶ inne akcje obiektu [c_ship] - 
     takie same jakie dla statku gracza s± inicjowane przy
     obs³udze komunikatów od u¿ytkownika.
     Czyli (chwilowo, lista mo¿e ulec z czasem zmianie) [thrust], 
     [rotate] i [fire_rocket]. 
     
     Fakt ¿e narzucam sobie ¿e statek komputera w swoim [move] wywo³uje
     sam z siebie tylko metody dostêpne "prawie bezpo¶rednio"
     dla gracza nie gwarantuje jeszcze wcale ¿e statek komputera ma równe 
     szanse (bo np. móg³bym zrobiæ statek-kamikadze który podlatuje do statku
     gracza ¿eby siê z nim zderzyæ). Ale jest to dobry pocz±tek. *)
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
   
   [planet_moves] podaje czy utworzona planeta ma powoli kr±¿yæ po okrêgu.
   
   [enemies_count] podaje jak wiele statków wroga z danym AI chcesz mieæ:
   ile statków typu "stupido", ile typu "sniper", ile typu "quickie". 
   Wszystkie te parametry musz± byæ >= 0 i musz± siê sumowaæ do
   czego¶ > 0. *)
val new_game: t_enemies_counts -> bool -> unit
