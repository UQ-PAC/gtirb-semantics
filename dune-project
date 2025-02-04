(lang dune 3.6)

(name gtirb_semantics)

(generate_opam_files true)

(source
 (github UQ-PAC/gtirb-semantics))

(authors "Chris Binggeli/GNUNotUsername")

(maintainers "UQ-PAC")

(license Apache-2.0)

(homepage https://github.com/UQ-PAC/gtirb-semantics)

(package
 (name gtirb_semantics)
 (synopsis "Add semantic information to the IR of a disassembled ARM64 binary")
 (depends ocaml dune yojson asli (ocaml-protoc-plugin (>= 6.1.0)) base64 aslp_client_server_ocaml lwt mtime)
 (tags
  (decompilers instruction-lifters static-analysis)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
