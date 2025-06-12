open Cmdliner
open Lwt.Syntax

type command = { file : string; no_color : bool; shell : string }

let exec_processes (cmd : command) =
  (Lwt.async_exception_hook :=
     fun exn ->
       Printf.eprintf "Unhandled Lwt exception: %s\n" (Printexc.to_string exn));
  let main () =
    let proc_defs = Raika.load_procfile cmd.file cmd.no_color in
    let waiter, wakener = Lwt.wait () in

    if proc_defs = [] then (
      print_endline "Procfile is empty or not found";
      Lwt.return_unit)
    else
      let processes = ref [] in
      let process_statuses = ref [] in

      let _ =
        Lwt_unix.on_signal Sys.sigint (fun _ ->
            prerr_endline "\nCtrl+C, shutting down all processes...";

            (* Iterate over the processes list
         and call the 'terminate' method on each process *)
            List.iter (fun proc -> proc#terminate) !processes;
            Lwt.wakeup wakener ())
      in

      List.iter
        (fun proc_def ->
          let process, status = Raika.exec_proc proc_def cmd.shell in
          processes := process :: !processes;
          process_statuses := status :: !process_statuses)
        proc_defs;

      let* () = Lwt.pick [ Lwt.join !process_statuses; waiter ] in
      Lwt.return_unit
  in
  Lwt_main.run (main ())

let file_arg =
  let doc = "The path to the Procfile to execute." in
  let info = Arg.info [ "f"; "file" ] ~docv:"PATH" ~doc in

  Arg.value (Arg.opt Arg.string "Procfile" info)

let disable_colored_log =
  let doc = "Disable colored log." in
  let info = Arg.info [ "no-color" ] ~doc in

  Arg.value (Arg.flag info)

let shell =
  let doc = "Specify the shell to use." in
  let info = Arg.info [ "shell" ] ~doc in

  Arg.value (Arg.opt Arg.string "" info)

let command_term =
  let builder file no_color shell = { file; no_color; shell } in
  Term.(const builder $ file_arg $ disable_colored_log $ shell)

let main_term = Term.(const exec_processes $ command_term)

let cmd_info =
  Cmd.info "raika" ~version:"0.1.0" ~doc:"Procfile/Yaml based process manager."

let cmd = Cmd.v cmd_info main_term
let exec () = exit (Cmd.eval cmd)
