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

(*
  TODO:
  - (estetyka) zrobic rozne obrazki dla roznych rodzajow enemy_ships, 
    w ogole zrobic lepsze obrazki dla ships. Biale kolka na obrazkach ships
    mialy byc testowe ale zostawiam je na razie bo obrazki bez kolek 
    sa zbyt ciemne (gdy sa uzywane obrazki bez kolek trudno jest sie 
    zorientowac na pierwszy rzut oka gdzie na planszy sa statki)
*)

open Sdlvideo;;
open Sdlevent;;
open Base;;
open BbBase;;
open BbGame;;
open BbTime;;
open BbMoveable;;
open SdlUtils;;
open BbRotatedImage;;
open BbWrite;;

(* EndGameOver b oznacza ze gra sie zakonczyla bo gracz wygral/przegral.
   Wartosc b mowi czy gracz wygral.
   EndGameCancel oznacza ze gracz zrezygnowal w trakcie gry. *)
type t_end_game_reason = EndGameOver of bool * (string list) | EndGameCancel;;
(* This should not be catched anywhere (except for finally constructs,
   only to reraise) except for the end of game loop.
   Raise this from anywhere to exit from main game loop. *)
exception E_End_Game of t_end_game_reason;;

(* funkcje zeby moc latwiej zapisywac rzucanie wyjatku E_End_Game *)
let end_game_cancel () = raise (E_End_Game EndGameCancel);;
let end_game player_won str_list = raise (E_End_Game (EndGameOver
  (player_won, str_list)));;

(* parse command-line ---------------------------------------- *)

let sdl_video_flags = ref [`DOUBLEBUF; `HWSURFACE] in

arg_parse
  [ ("--fullscreen",
     Arg.Unit (function () -> listr_add sdl_video_flags `FULLSCREEN),
     "Run game in fullscreen window.") ;

    ("--no-double-buffer",
     Arg.Unit (function () -> listr_delete sdl_video_flags `DOUBLEBUF),
     "Do not request double buffer (but we may get it anyway).\n" ^
     "    Should be used only for testing purposes.") ;

    ("--board",
     Arg.String (function s -> Scanf.sscanf s "%ux%u" init_board_size),
     "Specify game board size. Use like this: --board WIDTHxHEIGHT")
  ]
  (function s -> failwith ("Argument not allowed "^s))
  "Available options:"
;

(* init ---------------------------------------- *)

Random.self_init ();

Sdl.init [`VIDEO; `TIMER];
try_finally
  (function () ->

  let screen = Sdlvideo.set_video_mode
    (board_width()) (board_height()) !sdl_video_flags in
  set_caption "";
  Sdlmouse.show_cursor false;

  let image_bg = load_image "bg_tileable.png" false in
  let image_no_rocket = load_image "no_rocket.png" true in
  let image_title_screen = load_image "title_screen.png" false in

  let start_enemies_count = 
    { ec_stupido = ref 1; ec_sniper = ref 0; ec_quickie = ref 0; } in
  let planet_moves = ref false in  
  let won_games_count = ref 0 in
  let games_count = ref 0 in

  (** Daj userowi mo¿liwosc zmiany konfiguracji gry ([start_enemies_count], 
      [planet_moves]), startu gry i wyjscia z gry. 
      Zwraca czy user wybra³ start gry (true) czy wyj¶cie z programu (false). *)
  let menu () =
    let almost_result = ref None in
    Sdlkey.enable_key_repeat ();
    while !almost_result = None do
      fill_rect screen (map_RGB screen black);
      let {r_x=x0; r_y=y0} = blit_surface_center image_title_screen screen in
      write_list screen (Normal (x0+40)) (Normal (y0+170))
      [ "[ENTER] to play";
        "[Q] to quit";
        "";
        "Enemies on board:";
        (Printf.sprintf "\"Stupidos\": %d [s]" !(start_enemies_count.ec_stupido));
        (Printf.sprintf "\"Snipers\" : %d [n]" !(start_enemies_count.ec_sniper));
        (Printf.sprintf "\"Quickies\": %d [i]" !(start_enemies_count.ec_quickie));
        (Printf.sprintf "Planet moves: %s [p]" (bool_to_yn !planet_moves));
        "";
        (Printf.sprintf "%d wins (%d games)" !won_games_count !games_count);
      ];
      flip screen;
      let incr_event value key_event =
        if key_event.keymod land Sdlkey.kmod_shift = 0 then
          incr value else
        if (!value > 0) && (!(start_enemies_count.ec_stupido) +
                            !(start_enemies_count.ec_sniper) +
                            !(start_enemies_count.ec_quickie) > 1) then
          decr value else
          ()
      in
      let ke = wait_for_keypress [Sdlkey.KEY_RETURN; Sdlkey.KEY_q;
        Sdlkey.KEY_s; Sdlkey.KEY_n; Sdlkey.KEY_i; Sdlkey.KEY_p;] in
      match ke.keysym with
        | Sdlkey.KEY_RETURN -> almost_result := Some true
        | Sdlkey.KEY_q -> almost_result := Some false
        | Sdlkey.KEY_s -> incr_event start_enemies_count.ec_stupido ke
        | Sdlkey.KEY_n -> incr_event start_enemies_count.ec_sniper ke
        | Sdlkey.KEY_i -> incr_event start_enemies_count.ec_quickie ke
        | Sdlkey.KEY_p -> planet_moves := not !planet_moves
        | _ -> raise (E_Internal_Error "badBlaster.menu invalid key")
    done;
    Sdlkey.disable_key_repeat ();
    match !almost_result with
      | Some result -> result
      | None -> raise (E_Internal_Error "badBlaster.menu unexpected None")
  in

  while menu() do
  
    new_game start_enemies_count !planet_moves;
    incr games_count;

    (* below is useful so I can write code like player_ship#fire_rocket
       instead of ugly (player_ship())#fire_rocket *)
    let player_ship = player_ship() and
        planet = planet() in

    (* Ustawienie tej zmiennej na true wylacza wszelkie sprawdzanie kolizji
       (czyli zadna rakieta nie niszczy zadnego statku, statki moga
       swobodnie przelatywac przez planete i przez inne statki)
       co czyni debuggowanie latwiejszym. Ale oczywiscie w wersji koncowej
       to ma byc zawsze false. *)
    let debug_collision_checking_off = false in

    (* local functions ---------------------------------------- *)

    let for_all_moveable (f: c_moveable->unit) =
      f (planet :> c_moveable);
      f (player_ship :> c_moveable);
      List.iter f ((!enemy_ships) :> c_moveable list);
      List.iter f ((!rockets) :> c_moveable list);
    in

    let draw_game () =
      (* image_bg z pomoca GIMPa zostal zrobiony tak ze mozna
         go skladac. Wiec wykorzystujemy to ponizej.
         Wszystko dlatego ze staramy sie ponizej dzialac poprawnie
         na dowolnie duzym board_width/height (no, w granicach dostepnego
         ekranu), w szczegolnosci na wiekszym niz sam image_bg. *)
      tile_surface image_bg screen;
      for_all_moveable (function moveable -> moveable#draw screen);
      if not player_ship#is_able_to_fire_rocket then
        blit_surface ~src:image_no_rocket ~dst:screen ~dst_rect:
          (rect 10 (board_height() - 30) 0 0) ();
    in

    let move_game game_speed =
      (* move all objects *)
      for_all_moveable (function moveable -> moveable#move game_speed);
      (* tutaj przez krotka chwile mozemy miec rakiety not active
         na liscie !rockets *)
      rockets := List.filter (function rocket -> rocket#active) !rockets;

      if not debug_collision_checking_off then
      begin
        (* check for collisions.
           Mamy cztery typy obiektow: player_ship, planeta, enemy_ships, rockets.
           enemy_ships i rockets sa w liczbie mnogiej wiec moga sie zderzac
           takze ze soba nawzajem.
           Mozliwe kolizje:
             rakieta z player_ship -> rakieta znika, EndGameOver false
             rakieta z jednym z enemy_ships -> rakieta znika, usun go z enemy_ships
             rakieta z planeta -> rakieta znika
             (nie sprawdzaj kolizji rakieta z rakieta)
             player_ship z enemy_ship -> EndGameOver false
             player_ship z planeta -> EndGameOver false
             enemy_ship z innym enemy_ship -> 
               mozna sie zastanawiac; w tej chwili nie badam takich kolizji -
               kiedy jest wiecej niz 1 statek komputera na planszy to
               ich prymitywne AI nie zabezpieczaja ich przed omylkowym
               strzelaniem w swoim kierunku, nie mowiac juz o unikaniu
               zderzen z samym soba; po prostu gdyby badac kolizje
               enemy_ship z innym enemy_ship to statki same by sie eliminowaly,
               co pozwoliloby userowi bardzo szybko podrasowac swoje 
               enemies_destroyed_count.
             usun oba z enemy_ships
             enemy_ship z planeta -> usun go z enemy_ships
           Jesli enemy_ships = [] na koncu to EndGameOver true
        *)
        (* sprawdza kolizje image_and_pos z moveable_listr, czyli referencji
           na liste c_moveable. Zwraca bool czy znalazl kolizje
           i przy okazji usuwa element z listy z ktorym byla kolizja
           (jesli not remove_all to usuwa tylko pierwszy element z jakim 
           znajdzie kolizje, dalej juz nie szuka;
           wpp. znajduje i usuwa wszystkie elementy z ktorymi byla kolizja) *)
        let is_collision_with_moveable_listr moveable_listr collider
          remove_all =
          let (new_moveable_listr, was_collision) =
              (if remove_all then list_find_and_remove_all else list_find_and_remove)
              (function moveable -> moveable#is_collision collider)
              !moveable_listr in
            moveable_listr:=new_moveable_listr;
            was_collision
        in
        let is_collision_with_rockets =
              is_collision_with_moveable_listr rockets and
            is_collision_with_enemy_ships =
              is_collision_with_moveable_listr enemy_ships in

        (* kolizja player_ship - rocket *)
        if is_collision_with_rockets (player_ship:>c_moveable) false then
          end_game false ["You were"; "hit by a rocket !"; "Game over"];

        (* kolizja enemy_ship - rocket *)
        enemy_ships := List.filter
          (function enemy_ship ->
            not (is_collision_with_rockets (enemy_ship:>c_moveable) false))
          (!enemy_ships);

        (* kolizja rocket - planet *)
        ignore( is_collision_with_rockets planet true );

        (* kolizja player_ship - enemy_ships *)
        if is_collision_with_enemy_ships (player_ship:>c_moveable) false then
          end_game false ["You crashed"; "with enemy ship !"; "Game over"];

        (* kolizja player_ship - planet *)
        if planet#is_collision (player_ship:>c_moveable) then
          end_game false ["You crashed"; "with a planet !"; "Game over"];

        (* kolizja enemy_ships - planet *)
        ignore( is_collision_with_enemy_ships planet true );

        (* sprawdz czy moze wszystkie enemy_ships zostaly zniszczone *)
        if !enemy_ships = [] then
          end_game true ["All enemy ships"; "destroyed !"; "Victory !"];
      end;
    in

    let screen_dump () =
      let fname = filename_auto_inc "bb_screen%d.bmp" in
        save_BMP screen fname;
        print_endline (Printf.sprintf "Screen dumped to \"%s\"" fname)
    in

    (* game loop ---------------------------------------- *)

    try
      while true do
        frame_render_begin ();
        draw_game ();
        flip screen;

        let game_speed = frame_render_end () in
        move_game game_speed;

        (* Below we handle not just one event, we handle *all* pending events.
           This is because draw_game may take a while and of course we do not
           want to have some "latency" in event handling *)
        while_some poll
          (function
            | KEYDOWN { keysym = ksym } ->
              begin
                match ksym with
                  | Sdlkey.KEY_ESCAPE -> end_game_cancel ()
                  | Sdlkey.KEY_F10 -> screen_dump ()
                  | Sdlkey.KEY_SPACE -> player_ship#fire_rocket
                  | Sdlkey.KEY_p ->
                     write_list screen Middle Middle 
                       ["Game paused"; "Press [P] to resume"];
                     flip screen;
                     ignore( wait_for_keypress [Sdlkey.KEY_p] );
                  | _ -> ()
              end
            | _ -> ()
          );

        (* Handle some input things based on State of some input
           (e.g. the state of key) *)
        match (Sdlkey.is_key_pressed Sdlkey.KEY_LEFT,
               Sdlkey.is_key_pressed Sdlkey.KEY_RIGHT) with
          | (true, false) -> player_ship#rotate true
          | (false, true) -> player_ship#rotate false;
          | _ -> ()
        ;

        if Sdlkey.is_key_pressed Sdlkey.KEY_UP then
          player_ship#thrust;
      done
    with
      E_End_Game reason ->
        match reason with
          | EndGameOver (player_won, str_list) ->
            begin
              if player_won then incr won_games_count else ();
              
              (* draw_game one last time, to show that all rocktes
                 that hit something (and all enemy_ships, if player
                 won) disappeared *)
              draw_game ();
              write_list screen Middle Middle str_list;
              flip screen;
              (* NIE dawaj tu spacji - spacja strzela rakiete co grozi ze user
                 omylkowo wcisnie spacje i nie zdazy nawet zobaczyc co mu
                 napisalismy na ekranie *)
              ignore( wait_for_keypress [Sdlkey.KEY_RETURN; Sdlkey.KEY_ESCAPE] )
            end
          | EndGameCancel -> ()
  done;
  )

  (* finalization ---------------------------------------- *)

  Sdl.quit

(* eof ------------------------------------------------------------ *)
