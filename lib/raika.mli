type process = { proc_name : string; command : string; color : string }

val load_procfile : string -> bool -> process list
val exec_proc : process -> string -> Lwt_process.process_full * unit Lwt.t
