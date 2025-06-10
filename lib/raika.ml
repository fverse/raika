open Lwt.Syntax

type process = { proc_name : string; command : string }

let trim_string = String.trim

(* Parses a single, valid line into a 'process' *)
let parse_line line =
  match String.split_on_char ':' line with
  | [ name; command ] ->
      let proc_name = trim_string name in
      let command = trim_string command in
      if name <> "" && command <> "" then Some { proc_name; command } else None
  (* Ignore invalid lines *)
  | _ -> None

(* Reads a file and returns a list of parsed process defs *)
let load_procfile filepath =
  let channel = open_in filepath in
  let rec read_lines acc =
    try
      let line = input_line channel in
      read_lines (line :: acc)
    with End_of_file -> acc
  in
  let all_lines = read_lines [] in
  close_in channel;

  List.filter_map
    (fun line ->
      let trimmed = trim_string line in
      (* Skip comments and blank lines *)
      if String.length trimmed == 0 || String.starts_with ~prefix:"#" trimmed
      then None
      else parse_line trimmed)
    (List.rev all_lines)

let log prefix stream =
  let rec loop () =
    let* line = Lwt_io.read_line_opt stream in
    match line with
    | Some line ->
        Printf.printf "%s | %s\n" prefix line;
        loop ()
    | None -> Lwt.return_unit
  in
  loop ()

(* Return the shell script based on the OS type. 
This function also works as a helper to raise an exception when the os is not supported by the app *)
let get_shell_command cmd =
  match Sys.os_type with
  | "Unix" -> ("", [| "/bin/sh"; "-c"; cmd |])
  | "Win32" -> ("", [| "cmd.exe"; "/c"; "\000" ^ cmd |])
  | _ -> failwith "Unsupported OS"

let exec_proc (proc : process) : Lwt_process.process_full * unit Lwt.t =
  print_newline ();

  let command = get_shell_command proc.command in
  let process = Lwt_process.open_process_full command in

  let status =
    (* Log stdout and stderr with the process name as the prefix *)
    let log_stdout = log proc.proc_name process#stdout in
    let log_stderr = log (proc.proc_name ^ " (err)") process#stderr in

    let* () = Lwt.join [ log_stdout; log_stderr ] in

    (* Get the status of the process *)
    let* status = process#status in
    (match status with
    | Unix.WEXITED 0 ->
        Printf.printf ">> Process '%s' finished successfully\n" proc.proc_name
    | Unix.WEXITED code ->
        Printf.printf ">> Process '%s' exited with error code %d\n"
          proc.proc_name code
    | _ ->
        Printf.printf ">> Process %s was terminated unexpectedly\n"
          proc.proc_name);
    Lwt.return_unit
  in

  (process, status)
