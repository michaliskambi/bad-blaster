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

(** Zbiór niezwi±zanych funkcji pomocniczych.
   Tutejsze funkcje nie maj± nic wspólnego z gr± "Bad Blaster", 
   nie u¿ywaj± te¿ Sdla, s± to po prostu ogólne funkcje pomocnicze
   dla OCamla.
*)

(** This exception should be used throughout whole program
   to signal something that means "we have a bug".
   As such this exception should not be ever caught (except in finally
   constructs, only to reraise it) *)
exception E_Internal_Error of string

(** {1 Konstrukcje imperatywne} *)

(** [repeat instr cond] wykonuje [instr ()] a¿ [cond] zwróci [true]. 
   Bardziej formalnie robi po prostu [instr (); while not cond () do 
   instr () done]. *)
val repeat: (unit -> unit) -> (unit -> bool) -> unit

(** [while_some provider consumer] w pêtli wywo³uje [provider ()].
   Je¿eli [provider] zwróci³ [Some x] to wywo³uje [consumer x],
   wpp. koñczy dzia³anie. *)
val while_some: (unit -> 'a option) -> ('a -> unit) -> unit

(** [try_finally a b] wykona [a()] i na pewno, bez wzglêdu
   na to czy w [a()] wyst±pi czy nie wyst±pi wyj±tek, wykona te¿ [b()].
   Czyli robi znane z ObjectPascala i Javy [try a() finally b() end;] 
   (i, podobnie jak w [try a() finally b() end], je¶li [b] samo wywo³a
   wyj±tek to wyjdziemy z try_finally z wyj±tkiem wywo³anym z [b]
   (co oznacza ¿e wyj±tek wywo³any przez a mo¿e zostaæ zapomniany;
   w praktyce zazwyczaj bêdziesz chcia³ pisaæ kod w taki sposób
   ¿eby [b] nie mog³o wywo³aæ ¿adnego wyj±tku)). *) 
val try_finally: (unit -> unit) -> (unit -> unit) -> unit

(** {1 Konwersja float na int} 
   
   OCaml definiuje [floor] i [ceil] i [modf]
   aby zwraca³y czê¶æ ca³kowit± jako float co jest o tyle uzasadnione
   ¿e zakres floatów jest wiêkszy od zakresu dowolnego inta
   ale z drugiej strony jest to zazwyczaj kompletnie bezu¿yteczne bo
   zazwyczaj podczas zaokr±glania chcemy po prostu za³o¿yæ ¿e rezultat 
   mie¶ci siê w zakresie inta i zale¿y nam aby mieæ w rezultacie 
   co¶ o typie int. 
   
   Jedna funkcja OCamla [truncate] (= [int_of_float]) robi konwersjê
   float -> int ale zaokr±gla w stronê 0, zazwyczaj nie chcemy
   tego. Wiec poni¿sze funkcje implementuj± inne zaokr±glenia
   na bazie [truncate]. *) 
   
(** Return fractional part (i.e. [first modf]). [fract] of negative value
   gives negative result (e.g. [fract -1.9] = -[0.9]) so always
   x = truncate x + fract x *)
val fract: float -> float

(** [round x] = closest integer to x, i.e. 
   [if x >= floor x + 0.5 then floor x else ceil x] *)
val round: float -> int

val int_floor: float -> int

val int_ceil: float -> int

(** {1 Operations on lists} *)

(** [list_delete l a] returns [l] with first (if any) occurence of [a] removed *)
val list_delete: 'a list -> 'a -> 'a list

(** [listr_add l a] does [l:=a::!l] *)
val listr_add: 'a list ref -> 'a -> unit

(** [listr_delete l a] does [l:= list_delete l a] *)
val listr_delete: 'a list ref -> 'a -> unit

(** [list_find_and_remove pred list] finds the first item 
   on the list that satisfies pred. If such item exists
   it returns ([list] with this item removed, [true]) else
   it returns ([list] (maybe not necessarily physically equal to [list],
   but a copy), [false]).
   
   Second result part could be removed (e.g. [pred] function might
   set some bool ref to flag it), but this is just convenient
   to have it already. *)
val list_find_and_remove: ('a -> bool) -> 'a list -> ('a list * bool)

(** [list_find_and_remove_all pred list] zwraca pare [(a,b)] gdzie
   [a = filter (not pred) list] a [b] okre¶la czy [pred] zwróci³ true
   dla choæ jednego elementu (czyli czy odfiltrowali¶my choæ jeden element).
   Zwracam uwagê ¿e funkcja ta ma identyczny typ co [list_find_and_remove]. *)
val list_find_and_remove_all: ('a -> bool) -> 'a list -> ('a list * bool)

(** {1 Operations on file names} *)

(** [filename_auto_inc pattern] bêdzie robi³ [Printf.sprintf pattern] i
   dla i = 0,1,... tak d³ugo a¿ w koñcu otrzyma filename które
   nie istnieje. *)
val filename_auto_inc: (int -> string, unit, string) format -> string

(** Zwraca [Filename.basename Sys.executable_name] 
   z usunietym rozszerzeniem .exe lub .opt. *)
val program_name: string

(** Zwróæ ¶cie¿kê do katalogu z danymi programu, zakoñczon± / lub \.
   Nazwa katalogu jest ustalana m.in. na podstawie [Sys.executable_name].
   Jest to dobry katalog na dane gry. Pod Windowsem zwraca
     Filename.dirname Sys.executable_name,
   pod UNIX-o podobnymi systemami (Linux, Cygwin)
   /usr/local/share/ program_name /
     lub (je¶li nie istnieje)
     ~/. program_name .data/ *)
val data_path: string

(** {1 Some trivial math functions and consts} *)

val pi: float

val sqrt2: float

val deg_to_rad:float -> float

val rad_to_deg:float -> float

(** [float_norm x bound] = "normalize" x to be inside \[0; bound\].
   Returns x + k*bound where k:int is adjusted 
   in such way that result is for sure in range \[0; bound\]. *) 
val float_norm: float -> float -> float

(** [angle_deg_norm x] = float_norm 360.0 *)
val angle_deg_norm: float -> float

(** [int_norm x bound] = make x inside \[0; bound). When x is >= 0 it is 
   the same as [x mod bound], when x<0 it does something slightly different.
   It ensures that returned result is always equal to some
   x + bound*k, where k is some integer. *)
val int_norm: int -> int -> int

val sqr: int -> int 

(** {1 Inne} *)

(** [clamped val min max] zwraca max(min, min(max, val)),
   zawsze podawaj min<=max *)
val clamped: 'a -> 'a -> 'a -> 'a

(** [arg_parse speclist anon_fun usage_msg] calls [Arg.parse] with 
   almost the same params, it only appends to the end of [speclist]
   [("--", Rest ANON_FUNC, "Do not interpret following argumets")].
   I think this is a standard and I want to use it always. *)
val arg_parse: 
  (Arg.key * Arg.spec * Arg.doc) list -> Arg.anon_fun -> Arg.usage_msg -> unit
  
(** Zamieñ warto¶æ boolowsk± na "yes" lub "no" *)
val bool_to_yn: bool -> string
