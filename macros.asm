;Originally created around December or November 2023

;#########################
; ------------------------
; Written by Jay
; ------------------------
; Contact: 
; err_code_jay@outlook.com
; ------------------------
;#########################

VARARGS_TEST MACRO ArgV:VARARG
  LOCAL textConst,cnt
  textConst equ <"Number of arguments: >
  ;ProcName equ @ProcName
  ;textConst CATSTR textConst, %ProcName, <">


  IFNB <ArgV>   ;if ArgV isn't blank
    cnt = 0     ;argument index (add 1 to get #) 
    ;proc_info
    FOR current_arg, <ArgV>
      cnt = cnt + 1
    ENDM
    textConst CATSTR textConst, %cnt, <"> 
    IFNDEF VARARGS_TEST_DATA 
      .data
        testMsg db textConst,0
        macrodata_regsave0 qword 0
        ;numofargs qword cnt
    DEFINE VARARGS_TEST_DATA
  ENDIF
    .code
      mov macrodata_regsave0, r10 ;dont want to touch the stack
      xor r10, r10
      lea rax, [testMsg]
      ;mov rax, OFFSET @ProcName ;ProcName is broken in UASM
      invoke MessageBoxA, r10, rax, rax, r10d 
      mov r10, macrodata_regsave0
  ENDIF
ENDM

;MacroDbgInit textequ <DbgInit>
MacroDbgInit MACRO
  IFNDEF MACRO_DBGDATA_INITIALIZED
    .data?
    ;DbgSys_Buffer: 
    ;  OWORD ? ;what is this going to be used for?
    ;  OWORD ?
    RegBuffer STRUCT
      dbgrax qword ?
      dbgrbx qword ?
      dbgrcx qword ?
      dbgrdx qword ?
      dbgrsi qword ?
      dbgrdi qword ?
      dbgrsp qword ?
      dbgrbp qword ?
      dbgrip qword ?
    RegBuffer ENDS
    DEFINE MACRO_DBGDATA_INITIALIZED
    .code
  ENDIF
ENDM

;"DEFDBGMACRO - Helps with the defining of macros for the 
;   set of debugging macros. Does some automatic checks
;   for misuse of the macros after they've been defined.
;   For example, this macro adds a little check to see if
;   macros created with it are being used prior to using
;   the required MacroDbgInit / DbgInit macro which defines
;   some data used by associated macros.

DEFDBGMACRO MACRO MacroName:REQ, MacroArgV:VARARG
  MacroName MACRO
    .data
      Attention db "Attention!",0
      TestMacroMessage db "The DEFDBGMACRO macro is working!",0
    .code
      xor rcx, rcx
      lea rdx, [TestMacroMessage]
      mov r9, OFFSET Attention
      xor r10, r10
      mov r10d, MB_OK
      enter 50h, 0
      call MessageBoxA 
      leave
      ;invoke MessageBoxA, 0, OFFSET Attention, OFFSET TestMacroMessage, MB_OK OR MB_HELP
    nop
  ENDM
ENDM


; DbgProc:
;   main debugging function that is called after the debugging 
;   macro (hasnt been made yet(not the MacroDbgInit macro)) has
;   saved registers values, saved a complete snapshot of the current
;   stackframe, and performed other tasks that may aid with debugging.
;   
;  - Is incharge of creating the debugging window and all prerequisite tasks
;   * Registering the window class for the debugging window
;   * 
DbgProc proto 

; DbgProcWnd:
;   DbgProcWnd is the window procedure for the debugging window.
;   Does what a normal WndProc function does (allows gui to respond to
;   windows messages).
DbgProcWnd proto

; DbgEmergencyExit:
;   This function is a last resort fail-safe in case that runs if the main
;   debugging procedure crashes. Also used for debugging the main debugging procedure
;   (DbgProc) and associated debugging functions
;
;    
DbgEmergencyExit proto

DbgProc proc FRAME : DbgEmergencyExit
  
  ret
DbgProc endp

DbgProcWnd proc
  ret
DbgProcWnd endp

DbgEmergencyExit proc
  ret
DbgEmergencyExit endp

;######## 7/4/2024 update
;[3/7/2024] @ 7:11pm

; Credits to Vortex on the MasmForums for the original "PROCX" macro below.
; It's been modified as the origial wasn't functional in my case.
; The macro is a custom version of PROC that allows you to get the name
; of the current procedure (a feature that, at the time of writing, doesn't seem
; to be functional in Uasm).

;updated on 8/9/2024: added PROCX_DEBUG_CONSOLE switch
PROCX MACRO procname:REQ,args:VARARG 
  IFDEF PROCX_DEBUG_CONSOLE
    LOCAL PROCXNAME
  ENDIF
  procname PROC args
  IFDEF PROCX_DEBUG_CONSOLE
    .data
        PROCXNAME db "Current Procedure: &procname",13,10,0
    .code
        invoke printf, ADDR PROCXNAME
  ENDIF
ENDM
procx TEXTEQU <PROCX>

; [4/7/2024] @ 8:40pm

;the "WinCall" macro just bolts some QOL enhancements (like an optional call to GetLastError)
;to the preexisting "invoke" macro

WINCALL MACRO procname:REQ,ErrChk:REQ,args:VARARG
  LOCAL _$CodeStart,_$procname
IFNDEF WINC_DBG_OFF
  IFNDEF WINCALLDATA
    .data
      _$lastErrorMsg db "Call to '%s' failed with error code (from GetLastError): %d\n",0
    .data?
      _$lastError QWORD ?
      _$lastErrorMsgPtr QWORD ?
    DEFINE WINCALLDATA
  ENDIF
ENDIF
.code
;IFNDEF WINC_DBG_OFF ;uncomment this and test it later
  jmp _$CodeStart
  ;;#########################################
  ;;Define name of function in code segement
  ;;#########################################
  IFDEF WINC_UNICODE
    _$procname dw "&procname",0 
  ELSE
    _$procname db "&procname",0 
  ENDIF
;ENDIF
_$CodeStart:
  invoke procname, args
  ;push rax ;preserve func ret value
  IFNDEF WINC_DBG_OFF
	  IF ErrChk EQ 0
	    ;Winapi functions that use GetLastError usually return 0 upon some form of error.
	    cmp rax, 0
	    jne @f  ;if winapi function returned non zero value, skip call to GetLastError and printf
	      invoke GetLastError
	      mov _$lastError, rax ;save last error
	      invoke FormatMessage, FORMAT_MESSAGE_ALLOCATE_BUFFER or FORMAT_MESSAGE_FROM_SYSTEM, \
	          NULL, eax, 0, addr _$lastErrorMsgPtr, 0, 0
	      mov rax, _$lastErrorMsgPtr ;get pointer to formatted error message
	      invoke printf, rax  ;print formatted error message
	      invoke printf, "\n" ;print new line
	      mov rax, _$lastError ;restore last error for printing 
	      ;invoke printf, "Call to '&procname' failed with error code (from GetLastError): %d\n", rax
        invoke printf, OFFSET _$lastErrorMsg, OFFSET _$procname, rax
	    @@:
	  ENDIF
  ENDIF
  ;pop rax ;restore func ret value
ENDM
WinCall TEXTEQU <WINCALL>
WINC_ERRCHK   EQU 1
WINC_NOERRCHK EQU 0
;##########################################
; - Added 8/10/2024
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;		The "WINCALLMANUAL" macro is
;		the "WinCall" macro from the DirectX 11
;		ASM series of articles. Standard invoke
;		requires more work to use with the 
;		DirectX COM methods in the jerry-rigged 
;		Vtables. I'm also doing this because
;   I need a more concrete understanding
;   of things like stack setup for calling
;   functions with fastcall.
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;###########################################

WinCallManual MACRO Func, ParamCount, Fnames:VARARG 
    LOCAL jump_1, jump_2, lPointer
    
    mov rax, ParamCount
    cmp rax, 4
    jge @jump_1
    mov rax, 4 ;4 for 4 parameters
    shl rax, 3 ;2^2 = 4 --> 2^(2+3) = 32 bytes for 4 paramters on stack
@jump_1:
@jump_2:

ENDM

mDefReal4Num MACRO Num
LOCAL EvalNum,NumTxt
EvalNum = &Num&
NumTxt TEXTEQU %EvalNum
.data
  REAL4 NumTxt.0 
ENDM

  
;[4/21/2024]
		;The "DEFCMD" macro is a macro that is used to define a command in the command table.
		;This macro can only be used in the data section and as such, redundantly sets the current section
		;to the data section (this is mainly for reasons of readability as well as mostly preventing it's use in the middle
		;of the code section)
		;(think of a linked list of sorts)

;[4/22/2024] @ 4:28pm
		;table entry example
		;string1 addr, string2 addr, string1 data
		;string2 addr, string3 addr, string2 data
		;---
		;the jump table example above wouldn't have much use
		;unless the variable length aspect of the command strings
		;themselves were removed from the table and instead replaced with
		;a pointer for each individual command string. A macro can be made
		;to achieve this without much visual difference.


DEFCMD MACRO cmdName:REQ, cmdString:REQ
LOCAL nextCmdAddr
cmdStrLen = 0
  .data ;this macro is supposed to leave the current section as the data section.
      cmdName db "&cmdString",0
      cmdStrLen = LENGTHOF &cmdName& + 1 ; = LENGTHOF cmdString + 1 (the '+ 1' is to account for terminating zero at the end of command strings)
        QWORD cmdStrLen ;this part is for testing
ENDM


;#################################
; ===============================
; =High performance timer macros=
; ===============================
;#################################

HiPerformanceCountStart MACRO LocalVarAddr:REQ
  invoke QueryPerformanceCounter, LocalVarAddr
ENDM

HiPerformanceCountEnd MACRO LocalVarAddr:REQ
  invoke QueryPerformanceCounter, LocalVarAddr
ENDM

;#################################
; ===============================
; =       Utility Macros        =
; ===============================
;#################################

;-----------------------------------------------
; Define a wide-character string and move its 
; address into a specified register
;-----------------------------------------------
wstr$ MACRO reg:REQ, string:REQ
  LOCAL varname
  .data
    varname dw "&string&",0
  .code
    mov &reg&, OFFSET varname 
ENDM
;---------------------------------
; source: macros64.inc (MASM64 SDK)
;---------------------------------

;---------------------------------
; "The supplied name... is set to 
; the aligned variable"
;---------------------------------

VAR64 MACRO varname
  LOCAL varlbl
  .data?
    align 8
    varlbl dq ?
  .code
  varname = varlbl
ENDM

;-----------------------------------------------
; Convert value to hex equivalent in string form
;-----------------------------------------------

hex$ MACRO value
  LOCAL buffer,pbuf
  .data?
    buffer db 32 dup (?)
  .data
    pbuf dq buffer
  .code
    invoke _i64toa value,buffer,16
    EXITM <pbuf>
ENDM

;-----------------------------------------------
; Convert value to decimal equivalent in string 
; form
;-----------------------------------------------
str$ MACRO value
  LOCAL buffer,pbuf
  .data?
    buffer db 32 dup (?)
  .data
    pbuf dq buffer
  .code
    invoke _i64toa value,buffer,10
    EXITM <pbuf>
ENDM

;-----------------------------------------------
; A debugging macro that prints the name and value
; of a variable to the console [unfinished]
;-----------------------------------------------
Dbout MACRO value,varname
  LOCAL var,$varname,$curraddr
  $curraddr = $ ;I want to use this for the var name if it hasn't
                ;been set already
  .data
  IFNB varname              ;if a variable name has been set
    $varname db "&varname",0
  ELSE                      ;if a variable name hasn't been set
    $varname db "Variable placeholder",0
  ENDIF
  IF (SIZEOF value EQ 8)      ;qword
    var dq &value
  ELSEIF (SIZEOF value EQ 6)  ;fword (6 bytes)
    var df &value
  ELSEIF (SIZEOF value EQ 4)  ;dword 
    var dd &value
  ELSEIF (SIZEOF value EQ 2)  ;word 
    var dw &value
  ELSEIF (SIZEOF value EQ 1)  ;byte
    var db &value
  ELSE                        ;error, unsupported size 
    .ERR Unsupported Size used.
  ENDIF
  .code
    IF (SIZEOF value EQ 8)
      ;mov rax, 
    ELSEIF (SIZEOF value LE 4) 
    ENDIF
    invoke printf, "[DBOUT]|> %s:%016llx"
ENDM

;---------------------------------
; $DefErrCode takes a constant
; and defines it as a string.
; Helpful for printing the names
; of NAMED ERRORS WITH NO STRING
; EQUIVALENT.
; Unfinished
;---------------------------------
$DefErrCode MACRO ErrCode:REQ
  db "&ErrCode&"
ENDM
;-------------------------------------------
; Not a macro I know, but it's going in
; here anyways for now since there is
; no generic asm file for useful procedures
; ive made yet.
;-------------------------------------------
; Arg1 % Arg2 (this is for unsigned values only)
Modulo proc Arg1:QWORD, Arg2:QWORD
  ;#################################
  ; Rdx must be clear before div
  ; because div uses the value in
  ; Rdx as the "most significant
  ; word of the dividend" 
  ; (From section on the div
  ; instruction, the AMD ISA Manual)
  ;#################################
  xor rdx, rdx
  mov rax, Arg1
  mov rcx, Arg2
  div rcx
  ;##############################
  ;rdx has the remainder, which
  ;is what we want for modulo.
  ;##############################
  mov rax, rdx
@End:
  ret
Modulo endp

;#################################
; ===============================
; =                             =
; ===============================
;#################################


