
type process = {
  proc_name    : string;
  command : string;
}
val load_procfile : string -> process list

val exec_proc : process -> unit Lwt.t