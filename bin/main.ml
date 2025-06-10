open Lwt.Syntax
open Cmdliner

let file_arg =
  let doc = "The path to the Procfile to execute." in
  let info = Arg.info [ "f"; "file" ] ~docv:"PATH" ~doc in

  Arg.value (Arg.opt Arg.string "Procfile" info)

let exec_processes filepath =
  (Lwt.async_exception_hook :=
     fun exn ->
       Printf.eprintf "Unhandled Lwt exception: %s\n" (Printexc.to_string exn));
  let main () =
    let proc_defs = Raika.load_procfile filepath in
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
          let process, status = Raika.exec_proc proc_def in
          processes := process :: !processes;
          process_statuses := status :: !process_statuses)
        proc_defs;

      let* () = Lwt.pick [ Lwt.join !process_statuses; waiter ] in
      Lwt.return_unit
  in
  Lwt_main.run (main ())

let main_term = Term.(const exec_processes $ file_arg)

let cmd_info =
  Cmd.info "raika" ~version:"0.1.0" ~doc:"Procfile/Yaml based process manager."

let cmd = Cmd.v cmd_info main_term
let () = exit (Cmd.eval cmd)
