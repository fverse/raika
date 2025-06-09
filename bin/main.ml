open Lwt.Syntax

let exec_processes () =
  (* TODO: take file as a command line argument *)
  let proc_defs = Raika.load_procfile "Procfile" in
  let (waiter, wakener) = Lwt.wait () in

  if proc_defs = [] then
    begin
      print_endline "Procfile is empty or not found";
      Lwt.return_unit
    end
  else
    begin
      let processes = ref [] in
      let process_statuses = ref [] in

      let _ = Lwt_unix.on_signal Sys.sigint (fun _ ->
        prerr_endline "\nCaught Ctrl+C, shutting down all processes...";

         (* Iterate over the processes list
         and call the 'terminate' method on each process *)
         List.iter (fun proc ->
           proc#terminate
         ) !processes;
        Lwt.wakeup wakener ();
      ) in

      List.iter (fun proc_def ->
        let (process, status) = Raika.exec_proc proc_def in
        processes := process :: !processes;
        process_statuses := status :: !process_statuses;
      ) proc_defs;

      let* () = Lwt.pick [Lwt.join !process_statuses; waiter] in
      Lwt.return_unit
    end

let () =
  Lwt.async_exception_hook := (fun exn ->
    Printf.eprintf "Unhandled Lwt exception: %s\n" (Printexc.to_string exn)
  );
  
  Lwt_main.run (exec_processes ())