(lang dune 3.6)

(name gtirb_semantics)

(generate_opam_files true)

(source
 (github UQ-PAC/gtirb-semantics))

(authors "Chris Binggeli/GNUNotUsername")

(maintainers "UQ-PAC")

(license LICENSE)

(documentation https://github.com/UQ-PAC/gtirb-semantics)

(package
 (name gtirb_semantics)
 (synopsis "Add semantic information to the IR of a disassembled ARM64 binary")
 (description "A longer description")
 (depends ocaml dune asli.libASL ocaml-protoc-plugin hextring base64)
 (tags
  (decompilers instruction-lifters static-analysis)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
