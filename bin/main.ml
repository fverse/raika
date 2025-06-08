open Lwt.Syntax

type process = {
  proc_name: string;
  command: string;
}

let log prefix stream = 
  let rec loop () =
    let* line = Lwt_io.read_line_opt stream in 
    match line with 
    | Some line -> 
        Printf.printf "%s | %s\n" prefix line;
        loop()
    | None -> Lwt.return_unit
  in
  loop () 

(* Return the shell script based on the OS type. 
This function also works as a helper to raise an exception when the os is not supported by the app *)
let get_shell_command cmd =
  match Sys.os_type with
  | "Unix" -> ("", [|"/bin/sh"; "-c"; cmd|])
  | "Win32" -> ("", [|"cmd.exe"; "/c"; "\000" ^ cmd|])
  | _ -> failwith "Unsupported OS"
  
let exec_proc (proc : process) : unit Lwt.t =
  Printf.printf "\n>> Executing process: %s \n" proc.proc_name;

  let command = get_shell_command proc.command in
  let process = Lwt_process.open_process_full command in

  (* Log stdout and stderr with the process name as the prefix *)
  let log_stdout = log proc.proc_name process#stdout in
  let log_stderr = log (proc.proc_name ^ " (err)") process#stderr in

  let* () = Lwt.join [log_stdout; log_stderr] in

  (* Get the status of the process *)
  let* status = process#status in 
  (match status with
  | Unix.WEXITED 0 ->
      Printf.printf ">> Process '%s' finished successfully\n" proc.proc_name
  | Unix.WEXITED code ->
      Printf.printf ">> Process '%s' exited with error code %d\n" proc.proc_name code
  | _ -> Printf.printf ">> Process %s was terminated unexpectedly\n" proc.proc_name
      );
      
  Lwt.return_unit

