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

exception E_Internal_Error of string;;

(* wewnetrzne exception pomocnicze do array_is_mem *)
exception E_ArrayIsMemFound;;

let repeat instr cond =
  instr ();
  while not (cond ()) do instr (); done
;;
(* testy: 
let x = ref 0 in 
  repeat (function () -> print_int !x; incr x) (function () -> !x >= 3);;
(* => output 012 *)
let x = ref 0 in 
  repeat (function () -> print_int !x; incr x) (function () -> !x >= -1);;
(* => output 0 *)
*)

let while_some provider consumer =
  let e = ref None in
  while e := provider(); !e <> None do 
    match !e with
      | Some evalue -> consumer evalue
      | _ -> raise (E_Internal_Error "bbUtils.while_some")
  done
;;

exception E_Try_Finally_Exit;;
let try_finally a b =
  (* Jezeli a wywolalo wyjatek, to wykonamy b i zrobimy reraise wyjatku.
     Jezeli a nie wywolalo wyjatku to zrobimy "sztuczny" wyjatek
       E_Try_Finally_Exit ktory spowoduje ze i tak wywolamy b,
       a sam wyjatek E_Try_Finally_Exit zostanie wyciszony.
     Jezeli b wywolalo wyjatek to wyjatek ten zasloni ew. wyjatek
       rzucony przez a.
     Opieramy sie wszedzie tutaj na fakcie ze ani a ani b nie moga
       wywolac wewnetrznego wyjatku E_Try_Finally_Exit. *)
  try
    try a(); raise E_Try_Finally_Exit; with e -> begin b(); raise e end;
  with E_Try_Finally_Exit -> ()
;;
(* testy:
exception E_Test_1;;
exception E_Test_2;;
try_finally 
  (function () -> print_endline "a"; raise E_Test_1; print_endline "a_never")
  (function () -> print_endline "b");; (* a, b, Exception E_Test_1 *)
try_finally 
  (function () -> print_endline "a")
  (function () -> print_endline "b");; (* a, b *)  
try_finally 
  (function () -> print_endline "a"; raise E_Test_1; print_endline "a_never")
  (function () -> print_endline "b"; raise E_Test_2; print_endline "b_never");;   
  (* a, b, Exception E_Test_2 *)    
try_finally 
  (function () -> print_endline "a")
  (function () -> print_endline "b"; raise E_Test_2; print_endline "b_never");;   
  (* a, b, Exception E_Test_2 *)      
*)

let fract x = fst (modf x);;

let round x = 
  let tx = truncate x and fx = fract x in
    if x >= 0.0 then
      if fx >= 0.5 then tx+1 else tx
    else 
      if fx >= -0.5 then tx else tx-1
;;
(* testy: 
round (-1.9);;
round (-1.3);;
round (-0.8);;
round (-0.4);;
round (0.4);;
round 1.0;;
round 1.3;;
round 1.7;;
round 2.3;;
round 2.9;;
*)

let int_floor x = 
  let tx = truncate x in
  if x >= 0.0 then 
    tx else 
    if fract x < 0.0 then tx-1 else tx
;;
(* testy: 
int_floor (-1.9);;
int_floor (-1.3);;
int_floor (-0.8);;
int_floor (-0.4);;
int_floor (0.4);;
int_floor 1.0;;
int_floor 1.3;;
int_floor 1.7;;
int_floor 2.3;;
int_floor 2.9;;
*)

let int_ceil x = 
  let tx = truncate x in
  if (x >= 0.0) && (fract x > 0.0) then tx+1 else tx 
;;
(* testy:
int_ceil (-1.9);;
int_ceil (-1.3);;
int_ceil (-0.8);;
int_ceil (-0.4);;
int_ceil (0.4);;
int_ceil 1.0;;
int_ceil 1.3;;
int_ceil 1.7;;
int_ceil 2.3;;
int_ceil 2.9;;
*)

let rec list_delete l a =
  match l with 
    | [] -> []
    | x::xs -> if x=a then xs else x::(list_delete xs a)
;;
(* testy:
list_delete [] 1;;
list_delete [2; 3] 1;;
list_delete [2; 1; 3] 1;;
list_delete [2; 1; 3; 1] 1;;
*)

let listr_add l a = l := a::!l;;
let listr_delete l a = l := list_delete !l a;;

let rec list_find_and_remove pred = function
  | [] -> ([], false)
  | x::xs -> if pred x then (xs, true) else 
      let (resultxs, resultbool) = list_find_and_remove pred xs in
        (x::resultxs, resultbool)
;;
(* testy: 
list_find_and_remove (function x -> 1 = x) [2;3;4];; (* => ([2; 3; 4], false) *)
list_find_and_remove (function x -> 1 = x) [2;1;3;4];; (* => ([2; 3; 4], true) *)
list_find_and_remove (function x -> 1 = x) [2;1;3;1;4];; (* => ([2; 3; 1; 4], true) *)
*)

let list_find_and_remove_all pred list =
  let some_removal_done = ref false in
  let a = List.filter 
          (function item -> 
            let result = not (pred item) in 
              if result then () else some_removal_done:=true;
              result)
          list in
    (a, !some_removal_done)
;;
(* testy: 
list_find_and_remove_all (function x -> 1 = x) [2;3;4];; (* => ([2; 3; 4], false) *)
list_find_and_remove_all (function x -> 1 = x) [2;1;3;4];; (* => ([2; 3; 4], true) *)
list_find_and_remove_all (function x -> 1 = x) [2;1;3;1;4];; (* => ([2; 3; 1; 4], true) *)
*)

let filename_auto_inc s = 
  let result = ref "" and i = ref 0 in
    repeat
      (function () -> result:=Printf.sprintf s !i; incr i)
      (function () -> not (Sys.file_exists !result));
    !result
;;

let program_name = 
  let name = Filename.basename Sys.executable_name in
  if Filename.check_suffix name ".exe" then
    Filename.chop_suffix name ".exe" else
  if Filename.check_suffix name ".opt" then
    Filename.chop_suffix name ".opt" else    
    name
;;

let path_delim =
  match Sys.os_type with
    | "Win32" -> '\\'
    | "Unix" | "Cygwin" -> '/'
    | _ -> raise (E_Internal_Error "Base.path_delim: unknown OS")
;;

let incl_path_delim s = 
  s ^ (if (s="") || (s.[String.length s - 1] <> path_delim) then  
         (String.make 1 path_delim)
         else "")
;; 

let data_path =
  match Sys.os_type with
    | "Win32" -> incl_path_delim (Filename.dirname Sys.executable_name)
    | "Unix" | "Cygwin" ->
      let system_wide_path = "/usr/local/share/" ^ program_name ^ "/" in
        if Sys.file_exists system_wide_path then 
          system_wide_path else 
          (incl_path_delim (Sys.getenv "HOME")) ^ "." ^ program_name ^ ".data/"
    | _ -> raise (E_Internal_Error "Base.data_path: unknown OS")
;;

let pi = 3.14159265358979323846;;
let sqrt2 = 1.41421356237309504880;;

let deg_to_rad x = x *. pi/.180.0;;
let rad_to_deg x = x *. 180.0/.pi;;

let float_norm x bound =
  if x >= 0.0 then 
    mod_float x bound else
    (bound -. mod_float (-.x) bound)
;;

let angle_deg_norm x = float_norm x 360.0;;
  
let int_norm x bound = let m = x mod bound in if m<0 then bound+m else m;;

let sqr x = x*x;;

let clamped value min max =
  if value < min then min else 
    if value > max then max else
      value
;;
(* testy: 
clamped 0 2 5;;
clamped 3 2 5;;
clamped 100 2 5;;
*)

let arg_parse speclist anon_fun usage_msg =
  Arg.parse 
    (speclist @ 
      [("--", Arg.Rest anon_fun, "Do not interpret following argumets")])
    anon_fun usage_msg
;;

let bool_to_yn value = if value then "yes" else "no";;
