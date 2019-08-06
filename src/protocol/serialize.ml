open Core_kernel

(* Everything is encapsulated in messages,
   so everything will have a field id and a type assigned to it.
*)
type field =
  | Varint of int (* int32, int64, uint32, uint64, sint32, sint64, bool, enum *)
  | Fixed_64_bit of float (* fixed64, sfixed64, double *)
  | Length_delimited of string (* string, bytes, embedded messages, packed repeated fields *)
  | Fixed_32_bit of float

(* fixed32, sfixed32, float *)

(** Some buffer to hold data, and to read and write data *)
module Buffer = struct
  let incr = 128

  type t = {
    mutable offset : int;
    mutable data : Bytes.t;
  }

  let init ?(length = incr) () = {data = Bytes.create length; offset = 0}

  let ensure_capacity ?(cap = 1) t =
    let length = Bytes.length t.data in
    let remain = length - t.offset in
    match cap - remain with
    | n when n <= 0 -> ()
    | n ->
        let data' = Bytes.create (length + max n incr) in
        Bytes.blit ~src:t.data ~src_pos:0 ~dst:data' ~dst_pos:0 ~len:length;
        t.data <- data'

  let add_byte t v =
    ensure_capacity t;
    Bytes.set t.data t.offset @@ Char.of_int_exn v;
    t.offset <- t.offset + 1

  let write : t -> int -> field -> unit =
   fun t _index v ->
    let _ =
      match v with
      | Varint v ->
          let rec write_varint v =
            match v land 0x7F, v lsr 7 with
            | v, 0 -> add_byte t v
            | v, rem ->
                add_byte t (v lor 0x80);
                write_varint rem
          in
          write_varint v
      | Length_delimited s -> ignore s; failwith "Not implemented"
      | Fixed_32_bit f -> ignore f; failwith "Not implemented"
      | Fixed_64_bit f -> ignore f; failwith "Not implemented"
    in
    ()

  let rec write_varint t v =
    match v land 0x7F, v lsr 7 with
    | v, 0 -> add_byte t v
    | v, rem ->
        add_byte t (v lor 0x80);
        write_varint t rem

  let write_varint_signed t v =
    let v =
      match v with
      | v when v < 0 -> (((v * -1) - 1) * 2) + 1
      | v -> v * 2
    in
    write_varint t v

  (** Dont really know how to write an unsiged 32 bit *)
  let write_int32 t v =
    ensure_capacity ~cap:4 t;
    EndianBytes.LittleEndian.set_int32 t.data t.offset v;
    t.offset <- t.offset + 4

  let write_int64 t v =
    ensure_capacity ~cap:8 t;
    EndianBytes.LittleEndian.set_int64 t.data t.offset v;
    t.offset <- t.offset + 8

  let write_double t v =
    ensure_capacity ~cap:8 t;
    EndianBytes.LittleEndian.set_double t.data t.offset v;
    t.offset <- t.offset + 8

  let write_float t v =
    ensure_capacity ~cap:4 t;
    EndianBytes.LittleEndian.set_float t.data t.offset v;
    t.offset <- t.offset + 4
end

let serialize_field : int -> field -> unit =
 fun _ -> function
  | Varint v -> ignore v; failwith "Not implemented"
  | Length_delimited s -> ignore s; failwith "Not implemented"
  | Fixed_32_bit f -> ignore f; failwith "Not implemented"
  | Fixed_64_bit f -> ignore f; failwith "Not implemented"

(*

(* And functions to serialize individual elements *)

type (_) protobuf_type =
  | Double: float protobuf_type
  | Float: float protobuf_type
  | Int64: int protobuf_type
  | Uint64: int protobuf_type
  | Int32: int protobuf_type
  | Fixed64: int protobuf_type
  | Fixed32: int protobuf_type
  | Sfixed32: int protobuf_type
  | Sfixed64: int protobuf_type
  | Sint32: int protobuf_type
  | Sint64: int protobuf_type
  | Uint32: int protobuf_type
  | Bool: bool protobuf_type
  | String: string protobuf_type
  | Bytes: bytes protobuf_type
  | Message: ('a -> string) -> 'a option protobuf_type (* Hmm. How will we do this?? *)
  | Enum: ('a -> int) -> 'a protobuf_type
  | Repeated: 'a protobuf_type -> 'a list protobuf_type

(** Serialize a primitive type *)
(* 08 96 01 *)
(* First is 08 : *)
let serialize: type t. t protobuf_type -> t -> string = function
  | Double -> fun d ->
    let bytes = Bytes.create 8 in
    EndianBytes.LittleEndian.set_double d;


  | Float: float protobuf_type
  | Int64: int protobuf_type
  | Uint64: int protobuf_type
  | Int32: int protobuf_type
  | Fixed64: int protobuf_type
  | Fixed32: int protobuf_type
  | Sfixed32: int protobuf_type
  | Sfixed64: int protobuf_type
  | Sint32: int protobuf_type
  | Sint64: int protobuf_type
  | Uint32: int protobuf_type
  | Bool: bool protobuf_type
  | String: string protobuf_type
  | Bytes: bytes protobuf_type


(*
Autogenerated code:

(* Simple with string and int *)
(* What is the signature here??? *)
val Runtime.to_protobuf: field list -> Buffer.t (* So we hold the result here... *)
let to_protobuf { a; b} = Runtime.(to_protobuf [(2, serialize Int a); (3, serialize String b);])


(* Referencing a message *)
let to_protobuf { a; b} = Runtime.(to_protobuf [(2, serialize Int a); (3, serialize (Message Message.to_protobuf) message);])

(* It would be so nice if we could return the type...

(* Enum types? *)
to_protobuf = function
| x ->

to_protobuf: ... -> field


*)

*)

*)
