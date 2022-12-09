type dir_tree = { mutable size : int; mutable children : dir_tree list }

let rec walk_tree f init dir =
  List.fold_left (walk_tree f) (f init dir) dir.children

let change_dir dirs loc =
  match loc with
  | ".." -> List.tl dirs
  | _ ->
      let new_dir = { size = 0; children = [] } in
      let dir = List.hd dirs in
      dir.children <- List.cons new_dir dir.children;
      List.cons new_dir dirs

let parse_command dirs parts =
  let command = List.hd parts in
  match command with "cd" -> change_dir dirs (List.nth parts 1) | _ -> dirs

let parse_item dirs parts =
  let first = List.hd parts in
  match first with
  | "dir" -> dirs
  | _ ->
      let dir = List.hd dirs in
      dir.size <- dir.size + int_of_string first;
      dirs

let parse_line dirs line =
  let parts = String.split_on_char ' ' line in
  let head = List.hd parts in
  match head with
  | "$" -> parse_command dirs (List.tl parts)
  | _ -> parse_item dirs parts

let parse_dir_tree lines =
  let root = { size = 0; children = [] } in
  List.fold_left parse_line [ root ] lines

let read_file =
  let file = "input.txt" in
  let lines = ref [] in
  let ic = open_in file in
  try
    while true do
      lines := input_line ic :: !lines
    done;
    !lines
  with End_of_file ->
    close_in ic;
    List.rev !lines

let dir_size dir =
  let add acc d = acc + d.size in
  walk_tree add 0 dir

let sum_part1 acc dir =
  let size = dir_size dir in
  if size < 100000 then size + acc else acc

let sum_part2 min_size acc dir =
  let size = dir_size dir in
  if size >= min_size && size < acc then size else acc

let () =
  let lines = List.tl read_file in
  let tree = List.hd (List.rev (parse_dir_tree lines)) in
  let print_tree acc dir =
    String.cat acc (Printf.sprintf " %d" dir.size)
  in
  let total_disc = 70000000 in
  let total_need = 30000000 in
  let current = dir_size tree in
  let available = total_disc - current in
  let min_size = total_need - available in
  print_endline (walk_tree print_tree "" tree);
  print_endline (string_of_int (walk_tree sum_part1 0 tree));
  print_endline
    (string_of_int (walk_tree (sum_part2 min_size) 9999999999999999 tree));
  flush stdout
