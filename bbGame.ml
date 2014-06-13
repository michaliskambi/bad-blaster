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
open Base;;
open BbBase;;
open BbMoveable;;
open BbRotatedImage;;
open SdlUtils;;

(* Pewne pomysly: 
   - Niektore wartosci stad moglyby byc wyciagniete na zewnatrz i zrobione
     "adjustable by user" : 
       c_rocket.move const for move_length,
       angle_max_velocity,
       max velocity w c_ship.thrust
       planet_gravity
       czy planeta ma sie poruszac
     Nie zrobilem tego bo 1. zanieczysciloby to kod - w tym momencie
     te wartosci sa lokalnymi stalymi a zeby to zaimplementowac musialbym
     uczynic je globalnymi zmiennymi 2. a nie sadzie zeby naprawde byl sens
     dawac to pod kontrole gracza - te wartosci powinny byc raczej dobrze
     dobrane w grze.
     
   - c_planet w swoim move moze sie ruszac, np. krazyc po okregu. 
     Nie zrobilem bo uznalem ze nie uaktrakcyjni to gry az tak bardzo 
     spowoduje to wiecej zamieszania
     niz uaktrakcyjnie
*)

(* planet ---------------------------------------- *)

class c_planet (circle_middle:c_pos) moves =
let image_planet = load_image "mars.png" true in
let start_circle_angle_rad = Random.float pi in
let circle_radius = (board_width_f() +. board_height_f()) /. 8. in
let pos_from_angle_rad angle_rad = 
    circle_middle#copy_add_f ((sin angle_rad) *. circle_radius) 
                             ((cos angle_rad) *. circle_radius) in
let start_pos = pos_from_angle_rad start_circle_angle_rad in
object (self)
  inherit c_singleimg_moveable start_pos image_planet
  
  val mutable circle_angle_rad = start_circle_angle_rad
  
  method move game_speed = 
    if moves then
    begin
      circle_angle_rad <- circle_angle_rad +. (game_speed *. 0.01);
      self#set_pos (pos_from_angle_rad circle_angle_rad)
    end else
      ()
end;;

let f_planet: c_planet option ref = ref None;;
let planet () =
  match !f_planet with
    | None -> raise (E_Internal_Error 
        "You must call new_game before accessing planet")
    | Some x -> x
;;

(* rockets ---------------------------------------- *)

class c_rocket start_pos start_angle = 
let rotated_image = new_rotated_image "rocket_strip.png" in
object (self)
  inherit c_rotated_moveable start_pos start_angle rotated_image as super
  
  val mutable f_active = true  
  method active = f_active
  
  (* lifetime to odleglosc na planszy ktora rakieta moze przeleciec
     zanim nie zniknie sama z siebie *)
  val mutable lifetime = float_of_int (max (board_width()) (board_height()))
  
  method move game_speed =
    if self#active then
    begin
      let move_length = game_speed *. 20.0 in
        super#pos#move_angle super#angle move_length;
        lifetime <- lifetime -. move_length;
        if lifetime < 0.0 then f_active <- false
    end else
      ()
end;;

let rockets: c_rocket list ref = ref [];;

(* c_ship ---------------------------------------- *)

class c_ship start_pos start_angle init_image_rot = 
object (self)
  inherit c_rotated_moveable start_pos start_angle init_image_rot as super

  (* obroty ---------------------------------------- *)
  (* angle_velocity: prywatny atrybut, not to be set or even read from outside.
     angle_velocity is the change to f_angle in nearest move.
     angle_velocity will be gradually changed in move to 0. *)
  val mutable angle_velocity = 0.0
  method rotate ccw =
    let angle_max_velocity = 10.0 (* okresla jak zwrotny jest statek *) in
      angle_velocity <- (if ccw then 1.0 else -. 1.0) *. angle_max_velocity;
       
  (* ruch naprzod ---------------------------------------- *)
  val mutable velocity = 0.0
  method thrust =
    velocity <- 10.0 (* okresla jak szybki jest statek *);

  (* ---------------------------------------- *)  
  method move game_speed =
    self#set_angle (self#angle +. game_speed *. angle_velocity);
    self#pos#move_angle self#angle (game_speed *. velocity);
    
    let planet_gravity = 1. in
    self#pos#move_to (planet())#pos (game_speed *. planet_gravity); 

    angle_velocity <- angle_velocity /. (1.5 ** game_speed); 
    velocity <- velocity /. (1.1 ** game_speed); 

  (* firing rockets ---------------------------------------- *)
  val mutable last_fire_rocket_time = None
  method is_able_to_fire_rocket = ticks_check_passed last_fire_rocket_time 1000
  method fire_rocket = 
    if self#is_able_to_fire_rocket then
    begin
      (* rakieta jest wystrzelona minimalnie przed statkiem zeby
         na pewno rakieta wystrzelona przez statek nie spowodowala
         od razu kolizji z nim samym. *)
      let new_rocket = new c_rocket self#pos#copy self#angle in
        new_rocket#pos#move_angle self#angle
          (self#fired_rocket_start_distance self#angle (new_rocket :> c_moveable));
        listr_add rockets new_rocket;
        last_fire_rocket_time <- Some (Sdltimer.get_ticks());
    end else ()
end;;

let enemy_ships: c_ship list ref = ref [];;

let f_player_ship: c_ship option ref = ref None;;
let player_ship () =
  match !f_player_ship with
    | None -> raise (E_Internal_Error 
        "BbGame: You must call new_game before accessing player_ship")
    | Some x -> x
;;

(* c_computer_ship ---------------------------------------- *)

class c_computer_ship start_pos start_angle init_image_rot = 
object (self)
  inherit c_ship start_pos start_angle init_image_rot as super
  
  (* Nawet zwieksz odstep czasu do wystrzalu rakiety. *)
  method is_able_to_fire_rocket = ticks_check_passed last_fire_rocket_time 2000
  
  method angle_change_to_direction (p:c_pos) =
    let angle_to_p = self#pos#angle_deg_in_direction p in
    let self_angle = angle_deg_norm self#angle in
    let maybe_result = angle_to_p -. self_angle in
      if abs_float maybe_result <= 180. then
        maybe_result else
      if maybe_result < 0. (* czyli maybe_result < -180 *) then
        360. +.  maybe_result else
        (* czyli maybe_result > 180 *)
        maybe_result -. 360.        
end;;

(* ------------------------------------------------------------
   Rozne podklasy c_computer_ship (prywatne w tym module)
   implementujace rozne rodzaje AI. *)
   
(* Ot, takie zupe³nie losowe poruszanie siê po planszy. 
   Wyj±tkowo g³upi i ³atwy do pokonania, zreszt± czêsto sam zderza siê
   z planet±. *)
class c_computer_ship_stupido start_pos start_angle init_image_rot = 
object (self)
  inherit c_computer_ship start_pos start_angle init_image_rot as super

  val mutable ai_last_action_time = None 
  
  method move game_speed =
    super#move game_speed;
    
    (* zalazki sztucznej inteligencji statkow komputera sa tutaj *)
    if ticks_check_passed ai_last_action_time 1000 then
    begin
      ai_last_action_time <- Some (Sdltimer.get_ticks());
      match Random.int 12 with
        | 0 | 1 | 2 | 3 -> self#thrust
        | 4 | 5 | 6 -> self#rotate false
        | 7 | 8 -> self#rotate true (* celowa asymetria *)
        | _ -> self#fire_rocket 
    end else ()   
end;; 

(* Abstrakcyjna podklasa c_computer_ship: statek ktory unika
   zderzenia z planeta. Zajmie sie unikaniem zderzenia z planeta
   w move, ty masz juz tylko w podklasach pokryc move_dont_care_planet. *)
class virtual c_computer_ship_avoiding_planet start_pos start_angle init_image_rot = 
object (self)
  inherit c_computer_ship start_pos start_angle init_image_rot as super
  
  (* Czyli "zrób co¶ jak move ale nie przejmuj siê ju¿ unikaniem
     zderzenia z planet± (oraz wywo³aniem super#move)" *)
  method virtual move_dont_care_planet: float -> unit
  
  (* Ten statek dziala w dwoch trybach: albo usiluje oddalic sie od planety
     albo wykonuje move_dont_care_planet. *)
  val mutable away_from_planet_mode = false  
  
  method move game_speed =
    super#move game_speed;
    
    (* jezeli jestesmy za blisko planety to lepiej sie skoncentrowac
       na tym aby nieco sie od niej oddalic. Zwracam uwage ze warunki
       na przestawianie sie away_from_planet_mode na true i false sa
       nieco inne - chodzi o to zeby jak juz zaczniemy sie oddalac
       od planety to nie oddalac sie "tylko troszke zeby na chwile
       (ale tylko na chwile) wystarczylo" tylko zeby oddalic sie na tyle
       zeby przez jakis czas miec juz spokoj. *)
    begin
      let sqr_planet_distance = self#pos#sqr_board_distance (planet())#pos in
        if sqr_planet_distance < float_of_int (sqr ((planet())#size*2)) then
          away_from_planet_mode <- true else
        if sqr_planet_distance > float_of_int (sqr ((planet())#size*3)) then
          away_from_planet_mode <- false else
          ()
    end;
    
    if away_from_planet_mode then
    begin
      let angle_change_to_planet = 
          self#angle_change_to_direction (planet())#pos in
        if abs_float angle_change_to_planet < 75. then
          self#rotate (angle_change_to_planet < 0.) else
          self#thrust
    end else  
      self#move_dont_care_planet game_speed
end;;    

(* Ma³o sie rusza (tylko tyle ¿eby nie zderzyæ siê z planet±,
   tzn. przeciwdzia³a jej grawitacji). Ca³y czas stoi prawie w jednym 
   miejscu, celuje w gracza i kiedy wydaje mu siê ¿e dobrze wymierzy³ -
   - strzela. £atwo go trafiæ ale z drugiej strony jest trudny do
   pokonania bo sam strzela bardzo celnie. *)
class c_computer_ship_sniper start_pos start_angle init_image_rot = 
object (self)
  inherit c_computer_ship_avoiding_planet 
    start_pos start_angle init_image_rot as super

  method move_dont_care_planet game_speed =
    let angle_change_to_player = 
        self#angle_change_to_direction (player_ship())#pos in
      if angle_change_to_player > 30.    then self#rotate true else
      if angle_change_to_player < -. 30. then self#rotate false else
        self#fire_rocket
end;;  

(* Jeszcze jedna podklasa c_computer_ship. Tym razem chodzi o pewien
   kompromis miedzy sniperem a stupido : statek ma sie dosc szybko
   poruszac po planszy (ale w bardziej sensowny sposob niz _stupido)
   i strzelac (ale nie tak celnie jak sniper). *)
class c_computer_ship_quickie start_pos start_angle init_image_rot = 
object (self)
  inherit c_computer_ship_avoiding_planet 
    start_pos start_angle init_image_rot as super

  (* Albo ucieka albo sciga gracza. *)
  val mutable away_from_player_mode = false

  method move_dont_care_planet game_speed =
    begin
      let sqr_player_distance = self#pos#sqr_board_distance (player_ship())#pos in
        if sqr_player_distance < float_of_int (sqr (self#size)*3) then 
          away_from_player_mode <- true else
        if sqr_player_distance > float_of_int (sqr (self#size)*6) then
          away_from_player_mode <- false else
          ()
    end;

    let angle_change_to_player =
      self#angle_change_to_direction (player_ship())#pos in
    if away_from_player_mode then
    begin
     if abs_float angle_change_to_player < 60. then 
       self#rotate (angle_change_to_player < 0.) else
       self#thrust
    end else
    begin
     if abs_float angle_change_to_player > 60. then 
       self#rotate (angle_change_to_player > 0.) else
     if self#is_able_to_fire_rocket then
       self#fire_rocket else
       self#thrust
    end
end;;  

(* new_game ---------------------------------------- *)

type t_enemies_counts = { 
  ec_stupido:int ref; 
  ec_sniper:int ref; 
  ec_quickie:int ref; 
}  

let new_game enemies_counts planet_moves =
  f_planet := Some (new c_planet (new_random_pos()) planet_moves);
  
  let new_random_pos_planet_safe () =
      (* zwróc losow± pozycjê na planszy w bezpiecznej odleg³o¶ci od planet. *)
      new_random_pos_further (planet())#pos (float_of_int (planet())#size)
  in
  
  f_player_ship := Some (new c_ship (new_random_pos_planet_safe()) 
    (Random.float 360.) (new_rotated_image "player_ship_strip.png"));
    
  rockets := [];
  enemy_ships := [];
  
  let add_enemy_ships count (new_computer_ship_class: 
    BbBase.c_pos -> float -> BbRotatedImage.c_rotated_image -> c_computer_ship) =
    for i = 1 to count do 
      listr_add enemy_ships 
        ((new_computer_ship_class (new_random_pos_planet_safe())
          (Random.float 360.) (new_rotated_image "comp_ship_strip.png"))
          :>c_ship) 
    done
  in

  add_enemy_ships !(enemies_counts.ec_stupido) 
    (fun a b c -> ((new c_computer_ship_stupido a b c):>c_computer_ship));
  add_enemy_ships !(enemies_counts.ec_sniper) 
    (fun a b c -> ((new c_computer_ship_sniper a b c):>c_computer_ship));
  add_enemy_ships !(enemies_counts.ec_quickie) 
    (fun a b c -> ((new c_computer_ship_quickie a b c):>c_computer_ship));
;;

