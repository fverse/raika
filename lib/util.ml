let print_error err =
  let red = "\027[31m" in
  let reset_color = "\027[0m" in
  Printf.eprintf "%s%s%s\n" red err reset_color

let trim_string = String.trim
