
type process = {
  proc_name    : string;
  command : string;
}
val load_procfile : string -> process list

val exec_proc : process -> (Lwt_process.process_full * unit Lwt.t)