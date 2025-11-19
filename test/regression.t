
// usage message 

  $ ../bin/main.exe  --help
  usage: ../bin/main.exe [options] [input.gtirb output.gts]
  
    --json output json semantics to given file (default: none, use /dev/stderr for stderr)
    --serve Start server process (in foreground)
    --client Use client to server
    --offline Use offline lifter (implies --local)
    --shutdown-server Stop server process
    --no-time Don't show time elapsed on termination.
    -help  Display this list of options
    --help  Display this list of options

  $ ../bin/main.exe ../extras/example-bin/exampl2.gtirb out.gts --no-time --json example2.json 2>&1
  Lifting
  Successfully lifted 128 instructions (0 failure: 0 unique opcodes) (0.000000 cache hit rate)

 
  $ ../bin/main.exe ../extras/example-bin/exampl2.gtirb out.gts --no-time --json exampl2offline.json --offline 2>&1
  Lifting
  Successfully lifted 122 instructions (6 failure: 0 unique opcodes)


  $ ../bin/main.exe ../extras/example-bin/exampl2.gtirb out.gts --serve &
  Serving on domain socket GTIRB_SEM_SOCKET=aslp_rpc_socket
  Decoded 0 instructions (0 failure) (0 messages)

  $ ../bin/main.exe ../extras/example-bin/exampl2.gtirb out.gts --json exampl2client.json --client
  Lifting

  $ ../bin/main.exe --shutdown-server

// client is the same as the server

  $ diff example2.json exampl2client.json

  $ cat example2.json
  {
    "wnPR9BjMS/aehLrQO9j68A==": [
      [],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Cse0__5\",Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"SP_EL0\");'1111111111111111111111111111111111111111111111111111111111110000']))",
        "Stmt_TCall(\"Mem.set.0\",[8],[Expr_Var(\"Cse0__5\");8;0;Expr_Array(Expr_Var(\"_R\"),29)])",
        "Stmt_TCall(\"Mem.set.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"Cse0__5\");'0000000000000000000000000000000000000000000000000000000000001000']);8;0;Expr_Array(Expr_Var(\"_R\"),30)])",
        "Stmt_Assign(LExpr_Var(\"SP_EL0\"),Expr_Var(\"Cse0__5\"))"
      ],
      [ "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),29),Expr_Var(\"SP_EL0\"))" ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),30),'0000000000000000000000000000000000000000000000000000010110010000')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),'0000000000000000000000000000000000000000000000000000011000110100')"
      ]
    ],
    "+fSWLbjIRvizEoinlUdPFg==": [
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp16__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_Var(\"SP_EL0\");8;0]))",
        "Stmt_ConstDecl(Type_Bits(64),\"Exp18__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"SP_EL0\");'0000000000000000000000000000000000000000000000000000000000001000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),29),Expr_Var(\"Exp16__5\"))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),30),Expr_Var(\"Exp18__5\"))",
        "Stmt_Assign(LExpr_Var(\"SP_EL0\"),Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"SP_EL0\");'0000000000000000000000000000000000000000000000000000000000010000']))"
      ],
      [
        "Stmt_Assign(LExpr_Var(\"BTypeNext\"),'00')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),Expr_Array(Expr_Var(\"_R\"),30))"
      ]
    ],
    "/6QZmme7QXK8Xii+ZDlWkg==": [
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Cse0__5\",Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"SP_EL0\");'1111111111111111111111111111111111111111111111111111111111110000']))",
        "Stmt_TCall(\"Mem.set.0\",[8],[Expr_Var(\"Cse0__5\");8;0;Expr_Array(Expr_Var(\"_R\"),16)])",
        "Stmt_TCall(\"Mem.set.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"Cse0__5\");'0000000000000000000000000000000000000000000000000000000000001000']);8;0;Expr_Array(Expr_Var(\"_R\"),30)])",
        "Stmt_Assign(LExpr_Var(\"SP_EL0\"),Expr_Var(\"Cse0__5\"))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),16),'0000000000000000000000000000000000000000000000011111000000000000')"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),16);'0000000000000000000000000000000000000000000000000000111110101000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),17),Expr_Var(\"Exp14__5\"))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),16),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),16);'0000000000000000000000000000000000000000000000000000111110101000']))"
      ],
      [
        "Stmt_Assign(LExpr_Var(\"BTypeNext\"),'01')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),Expr_Array(Expr_Var(\"_R\"),17))"
      ]
    ],
    "E5iR3RuHTR+XarB8t/peNg==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),16),'0000000000000000000000000000000000000000000000011111000000000000')"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),16);'0000000000000000000000000000000000000000000000000000111110110000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),17),Expr_Var(\"Exp14__5\"))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),16),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),16);'0000000000000000000000000000000000000000000000000000111110110000']))"
      ],
      [
        "Stmt_Assign(LExpr_Var(\"BTypeNext\"),'01')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),Expr_Array(Expr_Var(\"_R\"),17))"
      ]
    ],
    "JnIejshOTLitfBx4eYY2eQ==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),16),'0000000000000000000000000000000000000000000000011111000000000000')"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),16);'0000000000000000000000000000000000000000000000000000111110111000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),17),Expr_Var(\"Exp14__5\"))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),16),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),16);'0000000000000000000000000000000000000000000000000000111110111000']))"
      ],
      [
        "Stmt_Assign(LExpr_Var(\"BTypeNext\"),'01')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),Expr_Array(Expr_Var(\"_R\"),17))"
      ]
    ],
    "XmL+r7XfS3+5VQnZpHoA9Q==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),16),'0000000000000000000000000000000000000000000000011111000000000000')"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),16);'0000000000000000000000000000000000000000000000000000111111000000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),17),Expr_Var(\"Exp14__5\"))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),16),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),16);'0000000000000000000000000000000000000000000000000000111111000000']))"
      ],
      [
        "Stmt_Assign(LExpr_Var(\"BTypeNext\"),'01')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),Expr_Array(Expr_Var(\"_R\"),17))"
      ]
    ],
    "G+uAis0JQQ6p1DOcOJBtWQ==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),16),'0000000000000000000000000000000000000000000000011111000000000000')"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),16);'0000000000000000000000000000000000000000000000000000111111001000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),17),Expr_Var(\"Exp14__5\"))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),16),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),16);'0000000000000000000000000000000000000000000000000000111111001000']))"
      ],
      [
        "Stmt_Assign(LExpr_Var(\"BTypeNext\"),'01')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),Expr_Array(Expr_Var(\"_R\"),17))"
      ]
    ],
    "kq1HB97SQemKPTx+YpLZxw==": [
      [],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),29),'0000000000000000000000000000000000000000000000000000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),30),'0000000000000000000000000000000000000000000000000000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),5),Expr_Array(Expr_Var(\"_R\"),0))"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_Var(\"SP_EL0\");8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),1),Expr_Var(\"Exp14__5\"))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),2),Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"SP_EL0\");'0000000000000000000000000000000000000000000000000000000000001000']))"
      ],
      [ "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),6),Expr_Var(\"SP_EL0\"))" ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000011111000000000000')"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000111111110000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_Var(\"Exp14__5\"))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),3),'0000000000000000000000000000000000000000000000000000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),4),'0000000000000000000000000000000000000000000000000000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),30),'0000000000000000000000000000000000000000000000000000011000110000')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),'0000000000000000000000000000000000000000000000000000010111000000')"
      ]
    ],
    "Ld1W6RQpT0istn13rz+8ew==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),30),'0000000000000000000000000000000000000000000000000000011000110100')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),'0000000000000000000000000000000000000000000000000000010111110000')"
      ]
    ],
    "X9mailtWR/WXG+tZmn4LBg==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000011111000000000000')"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000111111101000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_Var(\"Exp14__5\"))"
      ],
      [
        "Stmt_If(Expr_TApply(\"eq_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000000000000000']),[\nStmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"));\nStmt_Assign(LExpr_Var(\"_PC\"),'0000000000000000000000000000000000000000000000000000011001000100')\n],[],[])"
      ]
    ],
    "Fzx2bkZVQbayx5OzGMfj3w==": [
      [
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),'0000000000000000000000000000000000000000000000000000010111100000')"
      ]
    ],
    "4I51ajd/SLmpLdx+EuNvhw==": [
      [
        "Stmt_Assign(LExpr_Var(\"BTypeNext\"),'00')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),Expr_Array(Expr_Var(\"_R\"),30))"
      ]
    ],
    "B6dVs7LMRZqzDXDmweozFg==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000000000010000']))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),1),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),1),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),1);'0000000000000000000000000000000000000000000000000000000000010000']))"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Cse2__5\",Expr_TApply(\"not_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0)]))",
        "Stmt_ConstDecl(Type_Bits(64),\"Cse0__5\",Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),1);Expr_TApply(\"not_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0)])]))",
        "Stmt_Assign(LExpr_Field(LExpr_Var(\"PSTATE\"),\"V\"),Expr_TApply(\"not_bits.0\",[1],[Expr_TApply(\"cvt_bool_bv.0\",[],[Expr_TApply(\"eq_bits.0\",[128],[Expr_TApply(\"SignExtend.0\",[64;128],[Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"Cse0__5\");'0000000000000000000000000000000000000000000000000000000000000001']);128]);Expr_TApply(\"add_bits.0\",[128],[Expr_TApply(\"add_bits.0\",[128],[Expr_TApply(\"SignExtend.0\",[64;128],[Expr_Array(Expr_Var(\"_R\"),1);128]);Expr_TApply(\"SignExtend.0\",[64;128],[Expr_Var(\"Cse2__5\");128])]);'00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001'])])])]))",
        "Stmt_Assign(LExpr_Field(LExpr_Var(\"PSTATE\"),\"C\"),Expr_TApply(\"not_bits.0\",[1],[Expr_TApply(\"cvt_bool_bv.0\",[],[Expr_TApply(\"eq_bits.0\",[128],[Expr_TApply(\"ZeroExtend.0\",[64;128],[Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"Cse0__5\");'0000000000000000000000000000000000000000000000000000000000000001']);128]);Expr_TApply(\"add_bits.0\",[128],[Expr_TApply(\"add_bits.0\",[128],[Expr_TApply(\"ZeroExtend.0\",[64;128],[Expr_Array(Expr_Var(\"_R\"),1);128]);Expr_TApply(\"ZeroExtend.0\",[64;128],[Expr_Var(\"Cse2__5\");128])]);'00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001'])])])]))",
        "Stmt_Assign(LExpr_Field(LExpr_Var(\"PSTATE\"),\"Z\"),Expr_TApply(\"cvt_bool_bv.0\",[],[Expr_TApply(\"eq_bits.0\",[64],[Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"Cse0__5\");'0000000000000000000000000000000000000000000000000000000000000001']);'0000000000000000000000000000000000000000000000000000000000000000'])]))",
        "Stmt_Assign(LExpr_Field(LExpr_Var(\"PSTATE\"),\"N\"),Expr_Slices(Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"Cse0__5\");'0000000000000000000000000000000000000000000000000000000000000001']),[Slice_LoWd(63,1)]))"
      ],
      [
        "Stmt_If(Expr_TApply(\"eq_bits.0\",[1],[Expr_Field(Expr_Var(\"PSTATE\"),\"Z\");'1']),[\nStmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"));\nStmt_Assign(LExpr_Var(\"_PC\"),'0000000000000000000000000000000000000000000000000000011001111100')\n],[],[])"
      ]
    ],
    "WXmM8113QhKDJOPY4dtqMA==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),1),'0000000000000000000000000000000000000000000000011111000000000000')"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),1);'0000000000000000000000000000000000000000000000000000111111011000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),1),Expr_Var(\"Exp14__5\"))"
      ],
      [
        "Stmt_If(Expr_TApply(\"eq_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),1);'0000000000000000000000000000000000000000000000000000000000000000']),[\nStmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"));\nStmt_Assign(LExpr_Var(\"_PC\"),'0000000000000000000000000000000000000000000000000000011001111100')\n],[],[])"
      ]
    ],
    "ZdN5SXieRlyWErTPBqnt1w==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),16),Expr_Array(Expr_Var(\"_R\"),1))"
      ],
      [
        "Stmt_Assign(LExpr_Var(\"BTypeNext\"),'01')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),Expr_Array(Expr_Var(\"_R\"),16))"
      ]
    ],
    "Vv+GLmgfSBaGVpaNlyu7Iw==": [
      [
        "Stmt_Assign(LExpr_Var(\"BTypeNext\"),'00')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),Expr_Array(Expr_Var(\"_R\"),30))"
      ]
    ],
    "BMTRa8obR++tS20dAg4+sA==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000000000010000']))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),1),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),1),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),1);'0000000000000000000000000000000000000000000000000000000000010000']))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),1),Expr_TApply(\"add_bits.0\",[64],[Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),1);Expr_TApply(\"not_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0)])]);'0000000000000000000000000000000000000000000000000000000000000001']))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),2),Expr_TApply(\"ZeroExtend.0\",[1;64],[Expr_Slices(Expr_Array(Expr_Var(\"_R\"),1),[Slice_LoWd(63,1)]);64]))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),1),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),2);Expr_TApply(\"asr_bits.0\",[64;4],[Expr_Array(Expr_Var(\"_R\"),1);'0011'])]))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),1),Expr_TApply(\"SignExtend.0\",[63;64],[Expr_Slices(Expr_Array(Expr_Var(\"_R\"),1),[Slice_LoWd(1,63)]);64]))"
      ],
      [
        "Stmt_If(Expr_TApply(\"eq_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),1);'0000000000000000000000000000000000000000000000000000000000000000']),[\nStmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"));\nStmt_Assign(LExpr_Var(\"_PC\"),'0000000000000000000000000000000000000000000000000000011010111000')\n],[],[])"
      ]
    ],
    "y6El8tPtRke9ngHUSGAMsQ==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),2),'0000000000000000000000000000000000000000000000011111000000000000')"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),2);'0000000000000000000000000000000000000000000000000000111111111000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),2),Expr_Var(\"Exp14__5\"))"
      ],
      [
        "Stmt_If(Expr_TApply(\"eq_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),2);'0000000000000000000000000000000000000000000000000000000000000000']),[\nStmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"));\nStmt_Assign(LExpr_Var(\"_PC\"),'0000000000000000000000000000000000000000000000000000011010111000')\n],[],[])"
      ]
    ],
    "AJG+Ds6QQS2mYWOqHcK7jA==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),16),Expr_Array(Expr_Var(\"_R\"),2))"
      ],
      [
        "Stmt_Assign(LExpr_Var(\"BTypeNext\"),'01')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),Expr_Array(Expr_Var(\"_R\"),16))"
      ]
    ],
    "Ks2KtI9vS1+ii2SpWARcPA==": [
      [
        "Stmt_Assign(LExpr_Var(\"BTypeNext\"),'00')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),Expr_Array(Expr_Var(\"_R\"),30))"
      ]
    ],
    "KXDwv3cyQMWMK2ZJSrrfkg==": [ [] ],
    "iTbis3dPR1y01dUXkBNIlg==": [
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Cse0__5\",Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"SP_EL0\");'1111111111111111111111111111111111111111111111111111111111100000']))",
        "Stmt_TCall(\"Mem.set.0\",[8],[Expr_Var(\"Cse0__5\");8;0;Expr_Array(Expr_Var(\"_R\"),29)])",
        "Stmt_TCall(\"Mem.set.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"Cse0__5\");'0000000000000000000000000000000000000000000000000000000000001000']);8;0;Expr_Array(Expr_Var(\"_R\"),30)])",
        "Stmt_Assign(LExpr_Var(\"SP_EL0\"),Expr_Var(\"Cse0__5\"))"
      ],
      [ "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),29),Expr_Var(\"SP_EL0\"))" ],
      [
        "Stmt_TCall(\"Mem.set.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"SP_EL0\");'0000000000000000000000000000000000000000000000000000000000010000']);8;0;Expr_Array(Expr_Var(\"_R\"),19)])"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),19),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(8),\"Exp11__5\",Expr_TApply(\"Mem.read.0\",[1],[Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),19);'0000000000000000000000000000000000000000000000000000000000010000']);1;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_TApply(\"ZeroExtend.0\",[32;64],[Expr_TApply(\"ZeroExtend.0\",[8;32],[Expr_Var(\"Exp11__5\");32]);64]))"
      ],
      [
        "Stmt_If(Expr_TApply(\"not_bool.0\",[],[Expr_TApply(\"eq_bits.0\",[32],[Expr_Slices(Expr_Array(Expr_Var(\"_R\"),0),[Slice_LoWd(0,32)]);'00000000000000000000000000000000'])]),[\nStmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"));\nStmt_Assign(LExpr_Var(\"_PC\"),'0000000000000000000000000000000000000000000000000000011011111100')\n],[],[])"
      ]
    ],
    "/0iHpfdlRUuREKT8PSJN5w==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000011111000000000000')"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000111111100000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_Var(\"Exp14__5\"))"
      ],
      [
        "Stmt_If(Expr_TApply(\"eq_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000000000000000']),[\nStmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"));\nStmt_Assign(LExpr_Var(\"_PC\"),'0000000000000000000000000000000000000000000000000000011011110000')\n],[],[])"
      ]
    ],
    "UmGn47ygRg+22T1+nxC5zQ==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000000000001000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_Var(\"Exp14__5\"))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),30),'0000000000000000000000000000000000000000000000000000011011110000')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),'0000000000000000000000000000000000000000000000000000010111010000')"
      ]
    ],
    "kUaeebk2TlupuStH9vWzRA==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),30),'0000000000000000000000000000000000000000000000000000011011110100')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),'0000000000000000000000000000000000000000000000000000011001010000')"
      ]
    ],
    "1Wm9jAS2TlyVKrjbApbn4g==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000000000000000000001')"
      ],
      [
        "Stmt_TCall(\"Mem.set.0\",[1],[Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),19);'0000000000000000000000000000000000000000000000000000000000010000']);1;0;Expr_Slices(Expr_Array(Expr_Var(\"_R\"),0),[Slice_LoWd(0,8)])])"
      ]
    ],
    "zmrdp+uzQ5q2p6qvHtS9bA==": [
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"SP_EL0\");'0000000000000000000000000000000000000000000000000000000000010000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),19),Expr_Var(\"Exp14__5\"))"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp16__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_Var(\"SP_EL0\");8;0]))",
        "Stmt_ConstDecl(Type_Bits(64),\"Exp18__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"SP_EL0\");'0000000000000000000000000000000000000000000000000000000000001000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),29),Expr_Var(\"Exp16__5\"))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),30),Expr_Var(\"Exp18__5\"))",
        "Stmt_Assign(LExpr_Var(\"SP_EL0\"),Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"SP_EL0\");'0000000000000000000000000000000000000000000000000000000000100000']))"
      ],
      [
        "Stmt_Assign(LExpr_Var(\"BTypeNext\"),'00')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),Expr_Array(Expr_Var(\"_R\"),30))"
      ]
    ],
    "EK/+F8f5SrKtfOQfsIcxNQ==": [ [], [] ],
    "tb3/4QlSTPSKs95747qw0A==": [
      [
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),'0000000000000000000000000000000000000000000000000000011010000000')"
      ]
    ],
    "JgXUTTeoR9qjEjJwNU/5+w==": [
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000000000011100']))"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(32),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[4],[Expr_Array(Expr_Var(\"_R\"),0);4;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),1),Expr_TApply(\"ZeroExtend.0\",[32;64],[Expr_Var(\"Exp14__5\");64]))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000000000010100']))"
      ],
      [
        "Stmt_TCall(\"Mem.set.0\",[4],[Expr_Array(Expr_Var(\"_R\"),0);4;0;Expr_Slices(Expr_Array(Expr_Var(\"_R\"),1),[Slice_LoWd(0,32)])])"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000000000010100']))"
      ],
      [
        "Stmt_TCall(\"Mem.set.0\",[4],[Expr_Array(Expr_Var(\"_R\"),0);4;0;'00000000000000000000000000000000'])"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000000000010100']))"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(32),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[4],[Expr_Array(Expr_Var(\"_R\"),0);4;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),1),Expr_TApply(\"ZeroExtend.0\",[32;64],[Expr_Var(\"Exp14__5\");64]))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000000000011000']))"
      ],
      [
        "Stmt_TCall(\"Mem.set.0\",[4],[Expr_Array(Expr_Var(\"_R\"),0);4;0;Expr_Slices(Expr_Array(Expr_Var(\"_R\"),1),[Slice_LoWd(0,32)])])"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000000000011100']))"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(32),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[4],[Expr_Array(Expr_Var(\"_R\"),0);4;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),1),Expr_TApply(\"ZeroExtend.0\",[32;64],[Expr_Var(\"Exp14__5\");64]))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000000000010100']))"
      ],
      [
        "Stmt_TCall(\"Mem.set.0\",[4],[Expr_Array(Expr_Var(\"_R\"),0);4;0;Expr_Slices(Expr_Array(Expr_Var(\"_R\"),1),[Slice_LoWd(0,32)])])"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000000000010100']))"
      ],
      [
        "Stmt_ConstDecl(Type_Bits(32),\"Exp14__5\",Expr_TApply(\"Mem.read.0\",[4],[Expr_Array(Expr_Var(\"_R\"),0);4;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),1),Expr_TApply(\"ZeroExtend.0\",[32;64],[Expr_Var(\"Exp14__5\");64]))"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000100000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),Expr_TApply(\"add_bits.0\",[64],[Expr_Array(Expr_Var(\"_R\"),0);'0000000000000000000000000000000000000000000000000000000000011000']))"
      ],
      [
        "Stmt_TCall(\"Mem.set.0\",[4],[Expr_Array(Expr_Var(\"_R\"),0);4;0;Expr_Slices(Expr_Array(Expr_Var(\"_R\"),1),[Slice_LoWd(0,32)])])"
      ],
      [
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),0),'0000000000000000000000000000000000000000000000000000000000000000')"
      ],
      [
        "Stmt_Assign(LExpr_Var(\"BTypeNext\"),'00')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),Expr_Array(Expr_Var(\"_R\"),30))"
      ]
    ],
    "GBb7LATIS92OQzoZaJodlg==": [
      [],
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Cse0__5\",Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"SP_EL0\");'1111111111111111111111111111111111111111111111111111111111110000']))",
        "Stmt_TCall(\"Mem.set.0\",[8],[Expr_Var(\"Cse0__5\");8;0;Expr_Array(Expr_Var(\"_R\"),29)])",
        "Stmt_TCall(\"Mem.set.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"Cse0__5\");'0000000000000000000000000000000000000000000000000000000000001000']);8;0;Expr_Array(Expr_Var(\"_R\"),30)])",
        "Stmt_Assign(LExpr_Var(\"SP_EL0\"),Expr_Var(\"Cse0__5\"))"
      ],
      [ "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),29),Expr_Var(\"SP_EL0\"))" ]
    ],
    "oPH6kEc/T1urbtl09Si6vw==": [
      [
        "Stmt_ConstDecl(Type_Bits(64),\"Exp16__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_Var(\"SP_EL0\");8;0]))",
        "Stmt_ConstDecl(Type_Bits(64),\"Exp18__5\",Expr_TApply(\"Mem.read.0\",[8],[Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"SP_EL0\");'0000000000000000000000000000000000000000000000000000000000001000']);8;0]))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),29),Expr_Var(\"Exp16__5\"))",
        "Stmt_Assign(LExpr_Array(LExpr_Var(\"_R\"),30),Expr_Var(\"Exp18__5\"))",
        "Stmt_Assign(LExpr_Var(\"SP_EL0\"),Expr_TApply(\"add_bits.0\",[64],[Expr_Var(\"SP_EL0\");'0000000000000000000000000000000000000000000000000000000000010000']))"
      ],
      [
        "Stmt_Assign(LExpr_Var(\"BTypeNext\"),'00')",
        "Stmt_Assign(LExpr_Var(\"__BranchTaken\"),Expr_Var(\"TRUE\"))",
        "Stmt_Assign(LExpr_Var(\"_PC\"),Expr_Array(Expr_Var(\"_R\"),30))"
      ]
    ]
  }
