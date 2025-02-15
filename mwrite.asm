;First written to on 11/10/2023 at 9:31pm

;#########################
; ------------------------
; Written by Jay
; ------------------------
; Contact: 
; err_code_jay@outlook.com
; ------------------------
;#########################

dbgPrintRegisters proto 
;dbg proto

.const
;MW = M_WRITE
;MW_DISPLAY


.data
  MsgDbgPrintRax  db "| rax: %012llx",13,10
                  db "| rbx: %012llx",13,10
                  db "| rcx: %012llx",13,10
                  db "| rdx: %012llx",13,10,0
                  
  MsgDbgPrintGPRs db "| rax: %012llx",13,10
                  db "| rbx: %012llx",13,10
                  db "| rcx: %012llx",13,10
                  db "| rdx: %012llx",13,10
                  db "| rsi: %012llx | r11: %012llx",13,10 
                  db "| rdi: %012llx | r12: %012llx",13,10
                  db "| r8:  %012llx | r13: %012llx",13,10
                  db "| r9:  %012llx | r14: %012llx",13,10
                  db "| r10: %012llx | r15: %012llx",13,10,0

  MsgDbgHeader    db ".-~=Debug Print=~-.",13,10,0
  MsgDbgPrintWinProcParams LABEL BYTE
                  db "|(QWORD) hWin:   %012llx",13,10
                  db "|(DWORD) uMsg:   %012llx",13,10
                  db "|(QWORD) lparam: %012llx",13,10
                  db "|(QWORD) wparam: %012llx",13,10,0
.data?
  RegisterData GPRCONTEXT <>
  AVXRegisterData AVXCONTEXT <> ;YMM0-YMM15
  SSERegisterData AVXCONTEXT <> ;XMM0-XMM15
  ;TestingConst EQU QWORD PTR MsgDbgHeader
.code
;The dbgPrintRegisters function prints (some) general purpose
; registers to the console using printf for debugging purposes.
dbgPrintRegisters proc
  nop
  ;printf, addr MsgDbgPrintRax,rax
  ret
dbgPrintRegisters endp 

;The 'mdbgSaveGPRsInMem' macro stores most general purpose registers
; into a structure[0]. This is good for situations in which storing
; so many values on the stack is not possible or desirable.
mdbgSaveGPRsInMem MACRO 
  mov qword ptr [RegisterData].RAX_, rax  ;[1] Store initial value of rax 1st
  lea rax, qword ptr RegisterData         ;Then store addr of struct in rax
  ASSUME RAX:GPRCONTEXTPTR                   ;Enable type constraints
  mov [rax].RBX_, rbx
  mov [rax].RCX_, rcx
  mov [rax].RDX_, rdx
  mov [rax].R8_,  r8 
  mov [rax].R9_,  r9 
  mov [rax].R10_, r10
  mov [rax].R11_, r11
  mov [rax].R12_, r12
  mov [rax].R13_, r13
  mov [rax].R14_, r14
  mov [rax].R15_, r15
  ;############################
  ;rsp and rbp are ONLY saved.
  ;They aren't restored with the
  ;other macro
  ;############################
  mov [rax].RSP_, rsp
  mov [rax].RBP_, rbp
  ;mov [rax].RIP_,    ;More thought needs to be put in before RIP is added
  ASSUME RAX:NOTHING                      ;Remove type constraints
  mov rax, qword ptr [RegisterData]       ;Restore original value of rax
ENDM
;Footnotes
;[0] - The combination of this statement and the macro name may imply that structures
;       can only be used with predefined data, however this is far from the truth.
;[1] - Saving rax before anything is done makes it possible to restore it later on 
;       without having to use the stack.

;The 'mdbgRestoreGPRsFromMem' macro restores most general purpose registers
; from a specific structure in memory of type GPRCONTEXT that they were saved
; to earlier from the 'mdbgSaveGPRsInMem' macro. 
mdbgRestoreGPRsFromMem MACRO
  lea rax, qword ptr RegisterData         ;Store addr of struct in rax
  ASSUME RAX:GPRCONTEXTPTR
  mov rbx, [rax].RBX_
  mov rcx, [rax].RCX_
  mov rdx, [rax].RDX_
  mov r8,  [rax].R8_
  mov r9,  [rax].R9_
  mov r10, [rax].R10_
  mov r11, [rax].R11_
  mov r12, [rax].R12_
  mov r13, [rax].R13_
  mov r14, [rax].R14_
  mov r15, [rax].R15_
  ;############################
  ;rsp and rbp are *not*
  ;restored from this
  ;############################
  ASSUME RAX:NOTHING
  mov rax, qword ptr [RegisterData]       ;Load rax from stored value
ENDM

mdbgSaveGPRsOnStack MACRO
  push rax
  push rbx
  push rcx
  push rdx
  push rsi
  push rdi
  push r8
  push r9
  push r10
  push r11
  push r12
  push r13
  push r14
  push r15
ENDM

mdbgRestoreGPRsOnStack MACRO
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi 
    pop rdx
    pop rcx
    pop rbx
    pop rax
ENDM

;["OptionalMessageFlag" flags table]
; [bits] - 
;  [00] - Display MsgDbgHeader Message above message printouts
;  [01]
;  [02]
        
;  [03]
;  [04]
;  [05]
;  [06]
;  [07]

;The mdbgPrintRegisters macro prints (some) general purpose
; registers to the console using printf for debugging purposes.
mdbgPrintRegisters MACRO OptionalMessageFlag
  push rax
  push rbx
  push rcx
  push rdx
  push rsi
  push rdi
  IF OptionalMessageFlag
    lea rax, MsgDbgHeader
    invoke printf, rax
    
    pop rdi
    pop rsi 
    pop rdx
    pop rcx
    pop rbx
    pop rax

    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
  ENDIF
   
  invoke printf, addr MsgDbgPrintRax,rax,rbx,rcx,rdx
  pop rdi
  pop rsi 
  pop rdx
  pop rcx
  pop rbx
  pop rax
ENDM

mdbgPrintWinProcParams MACRO 
  mdbgSaveGPRsInMem

  invoke printf, addr MsgDbgPrintWinProcParams,rax,rbx,rcx,rdx  
  mdbgRestoreGPRsFromMem
ENDM

; 3/22/2024 Extentions written for macro testing project

mdbgPrintRegistersEx MACRO 
  mdbgSaveGPRsInMem
  invoke printf, addr MsgDbgPrintGPRs, rax, rbx, rcx, rdx, rsi, r11, rdi, \
          r12, r8, r12, r9, r14, r10, r15 
  mdbgRestoreGPRsFromMem
ENDM

mSaveXMM MACRO  
    push rax 
    ASSUME RAX:AVXCONTEXTPTR
    lea rax, SSERegisterData
    vmovdqu [rax]._XMM0, xmm0
    vmovdqu [rax]._XMM1, xmm1
    vmovdqu [rax]._XMM2, xmm2
    vmovdqu [rax]._XMM3, xmm3
    vmovdqu [rax]._XMM4, xmm4 
    vmovdqu [rax]._XMM5, xmm5
    vmovdqu [rax]._XMM6, xmm6
    vmovdqu [rax]._XMM7, xmm7 
    vmovdqu [rax]._XMM8, xmm8
    vmovdqu [rax]._XMM9, xmm9
    vmovdqu [rax]._XMM10, xmm10
    vmovdqu [rax]._XMM11, xmm11
    vmovdqu [rax]._XMM12, xmm12
    vmovdqu [rax]._XMM13, xmm13
    vmovdqu [rax]._XMM14, xmm14
    vmovdqu [rax]._XMM15, xmm15
    ASSUME RAX:NOTHING
    pop rax
ENDM

mSaveYMM MACRO
    push rax 
    ASSUME RAX:AVXCONTEXTPTR
    lea rax, AVXRegisterData
    vmovdqu [rax]._YMM0, ymm0
    vmovdqu [rax]._YMM1, ymm1
    vmovdqu [rax]._YMM2, ymm2
    vmovdqu [rax]._YMM3, ymm3
    vmovdqu [rax]._YMM4, ymm4 
    vmovdqu [rax]._YMM5, ymm5
    vmovdqu [rax]._YMM6, ymm6
    vmovdqu [rax]._YMM7, ymm7 
    vmovdqu [rax]._YMM8, ymm8
    vmovdqu [rax]._YMM9, ymm9
    vmovdqu [rax]._YMM10, ymm10
    vmovdqu [rax]._YMM11, ymm11
    vmovdqu [rax]._YMM12, ymm12
    vmovdqu [rax]._YMM13, ymm13
    vmovdqu [rax]._YMM14, ymm14
    vmovdqu [rax]._YMM15, ymm15
    ASSUME RAX:NOTHING
    pop rax
ENDM

mRestoreYMM MACRO
    push rax
    ASSUME RAX:AVXCONTEXTPTR
    lea rax, AVXRegisterData
    vmovdqu ymm0 ,[rax]._YMM0
    vmovdqu ymm1 ,[rax]._YMM1
    vmovdqu ymm2 ,[rax]._YMM2
    vmovdqu ymm3 ,[rax]._YMM3
    vmovdqu ymm4 ,[rax]._YMM4 
    vmovdqu ymm5 ,[rax]._YMM5
    vmovdqu ymm6 ,[rax]._YMM6
    vmovdqu ymm7 ,[rax]._YMM7
    vmovdqu ymm8 ,[rax]._YMM8
    vmovdqu ymm9 ,[rax]._YMM9
    vmovdqu ymm10 ,[rax]._YMM10
    vmovdqu ymm11 ,[rax]._YMM11
    vmovdqu ymm12 ,[rax]._YMM12
    vmovdqu ymm13 ,[rax]._YMM13
    vmovdqu ymm14 ,[rax]._YMM14
    vmovdqu ymm15 ,[rax]._YMM15
    ASSUME RAX:NOTHING
    pop rax
ENDM
