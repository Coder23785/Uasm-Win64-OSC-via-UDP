
;#########################
; ------------------------
; Written by Jay
; ------------------------
; Contact: 
; err_code_jay@outlook.com
; ------------------------
;        [NOTE]
; This file is only 
; included here because 
; another file requires it
; I believe. 
; ------------------------
;#########################

; I'll steal the linked list example  from Kip Irvine's course

;NODE STRUCT QWORD 
;    DATA_0 QWORD ?
;    DATA_1 QWORD ?
;NODE ENDS
;.data

;TotalNodeCount = 10
;NodeCount = 0
;LinkedList LABEL QWORD
;REPEAT TotalNodeCount
;    NodeCount = NodeCount + 1
;    NODE <NodeCount, ($ + NodeCount * SIZEOF NODE)>  
;ENDM

; Explanation...
;   "TotalNodeCount" and "NodeCount" are selfexplanatory.
;   "LinkedList LABEL QWORD" defines a symbol of data type QWORD called LinkedList.
;     Note that this doesn't actually make any data within the program itself. This is
;     exactly what it says it is; LinkedList is defined as a label and nothing else. It is
;     only there so that we can refer to the actual linked list defined just under it in code.
;     This is done because the way we are using the structure "NODE" doesn't ascribe a unique
;     symbol to each instance it occurs. Since there's no unique labels for each initialized 
;     "NODE" structure, there's no way to refer to the structures in code using a readable symbol,
;     hence the definition of the "LinkedList" label defined before the chain of initialized 
;     data structures.
;
;
;
;


; The "QWORD" in "GPRS64 STRUCT QWORD" the GPRS64 structure definition is the memory 
; alignment of the structure.

GPRS64 STRUCT QWORD 
    RAX_ QWORD ? 
    RBX_ QWORD ? 
    RCX_ QWORD ?
    RDX_ QWORD ?
    RSI_ QWORD ?
    RDI_ QWORD ?
    R8_  QWORD ?
    R9_  QWORD ?
    R10_ QWORD ?
    R11_ QWORD ?
    R12_ QWORD ?
    R13_ QWORD ?
    R14_ QWORD ?
    R15_ QWORD ?
    RSP_ QWORD ?
    RBP_ QWORD ?
    RIP_ QWORD ?
  
GPRS64 ENDS

;STRUCTDEF_GPRS32 MACRO
GPRS32 STRUCT DWORD
    EAX_  DWORD ?
          DWORD ?
    EBX_  DWORD ?
          DWORD ?
    ECX_  DWORD ?
          DWORD ?
    EDX_  DWORD ?
          DWORD ?
    ESI_  DWORD ?
          DWORD ?
    EDI_  DWORD ?
          DWORD ?
    R8D_  DWORD ?
          DWORD ?
    R9D_  DWORD ?
          DWORD ?
    R10D_ DWORD ?
          DWORD ?
    R11D_ DWORD ?
          DWORD ?
    R12D_ DWORD ?
          DWORD ?
    R13D_ DWORD ?
          DWORD ?
    R14D_ DWORD ?
          DWORD ?
    R15D_ DWORD ?
          DWORD ?
    ESP_  DWORD ? 
          DWORD ? 
    EBP_  DWORD ? 
          DWORD ? 
    EIP_  DWORD ? 
          DWORD ? 
GPRS32 ENDS 
;ENDM


GPRS64CAST32 UNION
    GPRS64 <>
    GPRS32 <>
GPRS64CAST32 ENDS

GPRCONTEXT STRUCT 
    GPRS64CAST32 <>
GPRCONTEXT ENDS

GPRCONTEXTPTR TYPEDEF PTR GPRCONTEXT

;WinShowLastError

;#### 7/4/2024 update

XMMREGS STRUCT
  _XMM0    OWORD ?
           OWORD ?
  _XMM1    OWORD ?
           OWORD ?
  _XMM2    OWORD ?
           OWORD ?
  _XMM3    OWORD ?
           OWORD ?
  _XMM4    OWORD ?
           OWORD ?
  _XMM5    OWORD ?
           OWORD ?
  _XMM6    OWORD ?
           OWORD ?
  _XMM7    OWORD ?
           OWORD ?
  _XMM8    OWORD ?
           OWORD ?
  _XMM9    OWORD ?
           OWORD ?
  _XMM10   OWORD ?
           OWORD ?
  _XMM11   OWORD ?
           OWORD ?
  _XMM12   OWORD ?
           OWORD ?
  _XMM13   OWORD ?
           OWORD ?
  _XMM14   OWORD ?
           OWORD ?
  _XMM15   OWORD ?
           OWORD ?
XMMREGS ENDS

YMMREGS STRUCT
   _YMM0   YMMWORD ?
   _YMM1   YMMWORD ?
   _YMM2   YMMWORD ?
   _YMM3   YMMWORD ?
   _YMM4   YMMWORD ?
   _YMM5   YMMWORD ?
   _YMM6   YMMWORD ?
   _YMM7   YMMWORD ?
   _YMM8   YMMWORD ?
   _YMM9   YMMWORD ?
   _YMM10  YMMWORD ?
   _YMM11  YMMWORD ?
   _YMM12  YMMWORD ?
   _YMM13  YMMWORD ?
   _YMM14  YMMWORD ?
   _YMM15  YMMWORD ?
YMMREGS ENDS

XMMYMMREGS UNION
    XMMREGS <>
    YMMREGS <>
XMMYMMREGS ENDS

AVXCONTEXT STRUCT
    XMMYMMREGS <>
AVXCONTEXT ENDS


GPRCONTEXTPTR TYPEDEF PTR GPRCONTEXT
AVXCONTEXTPTR TYPEDEF PTR AVXCONTEXT

;DATASTRUCT0 STRUCT QWORD
;DATASTRUCT0 ENDS

;make a proc replacement macro that would require you to specify the size
;of the stack frame. This might require disabling the autogeneration of
;stack frames. There are multiple ways to determine stack frame size
;either at runtime or preferrably at assembly. I want stack frame data
;included in debugging information.

PROCEX MACRO PROC_:REQ, Args:VARARG
    PROC_ PROC FRAME Args
      ret
    PROC_ ENDP
ENDM

;WinShowLastError

;Record Definitions (moved to datastructmacros.asm)
  MYRECORD32 RECORD rec_a:16,rec_b:10,rec_c:6
  MYRECORD64 RECORD rec64_a:16=0,rec64_b:16=0,rec64_c:16=0,rec64_d:16=0
  WSAVER     RECORD highbyte:8,lowbyte:8
;------------Windows Structures------------

;_WIN32_FIND_DATAA
; - Required by:
;     FindFirstFile
;     FindFirstFileEx
;     FindNextFile
;
_WIN32_FIND_DATAA STRUCT
  dwFileAttributes  DWORD ?
  ftCreationTime    FILETIME <?>
  ftLastAccessTime  FILETIME <?>
  ftLastWriteTime   FILETIME <?>
  nFileSizeHigh     DWORD ?
  nFileSizeLow      DWORD ?
  dwReserved        QWORD ?;DWORD ;RESERVED
  ;dwReserved1       DWORD ;RESERVED
  cFileName         CHAR MAX_PATH DUP (?)
  cAlternateFileName  CHAR 14 DUP (?)
_WIN32_FIND_DATAA ENDS
