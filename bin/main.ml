open Lwt.Syntax

let exec_processes () =
  (* TODO: take file as a command line argument *)
  let proc_defs = Raika.load_procfile "Procfile" in

  if proc_defs = [] then
    begin
      print_endline "Procfile is empty or not found";
      Lwt.return_unit
    end
  else
    begin
      let promises =
        List.map
          (fun proc_def -> Raika.exec_proc proc_def)
          proc_defs
      in

      let* () = Lwt.join promises in

      Lwt.return_unit
    end

let () =
  Lwt.async_exception_hook := (fun exn ->
    Printf.eprintf "Unhandled Lwt exception: %s\n" (Printexc.to_string exn)
  );
  
  Lwt_main.run (exec_processes ())