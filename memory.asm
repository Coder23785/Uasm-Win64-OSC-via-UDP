;memory mangement functions (memory.asm)

;#########################
; ------------------------
; Written by Jay
; ------------------------
; Contact: 
; err_code_jay@outlook.com
; ------------------------
;#########################

  ;Zero16ByteAlignedMemory TEXTEQU <ZeroMemoryAVX>
ZeroMemoryAVX PROTO :QWORD, :QWORD
OverwriteMemoryAVX2 PROTO :QWORD, :QWORD
DisplayMemory PROTO :QWORD, :QWORD, :QWORD
DisplayMemoryDouble PROTO :QWORD, :QWORD, :QWORD ;(4/28/2024)
DisplayMemoryEx PROTO :QWORD, :QWORD, :QWORD, :QWORD ;(updated 8/7/2024)

;BroadcastPattern's first two parameters are addresses.
;One is an address to the numeric pattern and the other
;is the destination address. The third controls how much is
;copied over to the destination address. (use number of bytes
;or use attempted number of pattern replicas?)
BroadcastPattern PROTO :QWORD, :QWORD, :QWORD ;a memory testing function.
.data
    fmtPrintByte      db "%02x ",0
    fmtPrintReal4     db "%02x ",0   ;DisplayMemoryDouble doesn't use this since a double and a real4 aren't the same data
                                     ;"types" (they are floats but one is double the size in bytes of the other)
    fmtPrintReal8     db "%#1.2f ",0
    fmtPrintNewLine   db 13,10,0
    ;#####################
    ;Following data are used with DisplayMemoryEx
    ;#####################
      fmtPrintQwordHexOffset  db "+%016llx: ",0
      fmtPrintQwordHex  db "%016llx ",0
.code

;The function "ZeroMemoryAVX" only works with memory 
;block sizes that are divisible by 32. 
PROCX ZeroMemoryAVX, memoryBlockAddr:QWORD, sizeOfMemBlock:QWORD
  @FuncInit:
    mov rax, memoryBlockAddr  ;move address of memory block to rax
    mov rbx, sizeOfMemBlock
    xor rcx, rcx
    vpxor ymm0,ymm0,ymm0      ;(zero out ymm0)
    vmovdqu ymm1, ymm0        ;move double quadword unaligned
  @WriteToMemBlock:
    vmovdqu ymmword ptr [rax+rcx], ymm0
    add rcx, 32     ;32 bytes written per iteration
    cmp rcx, rbx
    jnge @WriteToMemBlock   ;check for edge cases
  @FuncExit:
    ret
ZeroMemoryAVX endp

PROCX OverwriteMemoryAVX2, memoryBlockAddr:QWORD, sizeOfMemBlock:QWORD
  @FuncInit:
    mov rax, memoryBlockAddr
    mov rbx, sizeOfMemBlock
    xor rcx, rcx
    mov rdx, -1234
    movq xmm0, rdx  ;move quadword (SSE)
    vpbroadcastq ymm0,xmm0 ;broadcast packed quadword (AVX2) 
  @WriteToMemBlock:
    vmovdqu ymmword ptr [rax+rcx], ymm0
    add rcx, 32
    cmp rcx, rbx
    jnge @WriteToMemBlock
  @FuncExit:
    ret
OverwriteMemoryAVX2 endp

PROCX DisplayMemory, MemAddr:QWORD, NumOfBytes:QWORD, hConInput:QWORD
    mov rax, MemAddr
    mov rcx, NumOfBytes
    xor rbx, rbx ;number of values printed in column
    xor r12, r12
  @DisplayRow:
    @DisplayData:
      mov r10, qword ptr [rax]  ;get 8 bytes to print
      test r10, r10
      jnz @DisplayDataByteIsNotZero
      @DisplayDataByteEquZero:
        mdbgSaveGPRsInMem
        ;WinCall SetConsoleTextAttribute, WINC_ERRCHK, hConInput, FOREGROUND_RED or FOREGROUND_BLUE or FOREGROUND_GREEN ; white text, black background
        mdbgRestoreGPRsFromMem
        jmp @f ;jump over '@DisplayDataByteIsNotZero' and finish preparing for the rest of procedure

      @DisplayDataByteIsNotZero:
        mdbgSaveGPRsInMem
        ;WinCall SetConsoleTextAttribute, WINC_ERRCHK, hConInput, FOREGROUND_RED ; red text, black background
        mdbgRestoreGPRsFromMem

      @@:
      mov r11, 8 ;r10 needs to be shifted by 8 to the right 8 times
      @DisplayDataShiftRegBy8:
        mdbgSaveGPRsInMem
        invoke printf, ADDR fmtPrintByte, r10b
        mdbgRestoreGPRsFromMem

        shr r10, 8 ;display next byte for printing
        dec r11 ;decrement before the inital test in the loop means we can use 8 and not 7
        cmp r11, 0
        jnle @DisplayDataShiftRegBy8
      @DisplayDataPrepForNextInteration:
        mdbgSaveGPRsInMem
        invoke printf, ADDR fmtPrintNewLine; new line per 8 bytes printed
        mdbgRestoreGPRsFromMem

        add rax, 8 ;move mem addr 8 bytes up because 8 bytes have been printed by @DisplayDataShiftRegBy8
        add r12, 8
        cmp r12, NumOfBytes
        jnge @DisplayData

  @DisplayNewline:
    invoke printf, ADDR fmtPrintNewLine
  @FuncExit:

    ret
DisplayMemory endp

PROCX DisplayMemoryDouble, MemAddr:QWORD, NumOfDoubles:QWORD, hConInput:QWORD
    mov rax, MemAddr
    mov rcx, NumOfDoubles
    xor rbx, rbx ;number of columns printed
    xor r12, r12
  @DisplayRow:
    @DisplayData:
      mov r10, rax  ;get the address for the 1st element in the row to be printed
      mov r11, 8 ;8 doubles per row
      xor r13, r13 ;offset for selected double in current row being displayed

      @DisplayDataRow:
        mov r14, [r10+r13] ;get double to print
        mdbgSaveGPRsInMem
        invoke printf, ADDR fmtPrintReal8, r14
        mdbgRestoreGPRsFromMem
        add r13, 8 ;add 8 to offset because doubles are 8 bytes in size
        dec r11 ;decrement before the inital test in the loop means we can use 8 and not 7
        cmp r11, 0
        jnle @DisplayDataRow

        ;(Potential edge case?)[This particular error shouldn't  matter as much for Display
        ;since it only displays on a byte by byte basis.]

        ;r12 has 8 added to it (and rax, 64) regardless if the iteration has ended early or not
        ;On 2nd thought, it can't end early until the entire row is finished, which means if
        ;there aren't enough doubles in the provided array left to fill the row entirely, the function
        ;will start reading past the array.

        ;logic that would rely on the number of doubles printed in total would be broken because
        ;the total number of doubles isn't reliably recorded.


      @DisplayDataPrepForNextIteration:
        mdbgSaveGPRsInMem
        invoke printf, ADDR fmtPrintNewLine; new line per 8 bytes printed
        mdbgRestoreGPRsFromMem

        inc rbx     ;increment the number of columns printed so far (unused metric)
        add rax, 64 ;move mem addr 64 bytes up because 8 doubles have been printed by @DisplayDataRow
        add r12, 8  ;8 new doubles have been displayed
        cmp r12, NumOfDoubles
        jnge @DisplayData

  @DisplayNewline:
    invoke printf, ADDR fmtPrintNewLine
  @FuncExit:

    ret
DisplayMemoryDouble endp

;###########################
;_todo:
;         - replace all immediates with named constants
;         - needs to be rewritten to be threadsafe
;         -
;LengthOfRow is measured in # of data items in row, regardless of data size
;###########################
PROCX DisplayMemoryEx, MemAddr:QWORD, NumOfDataItems:QWORD, LengthOfRow:QWORD, OutputBufferAddr:QWORD
  @FuncInit:
    mov rax, MemAddr
    mov rdx, NumOfDataItems
    mov r11, LengthOfRow
    xor rcx, rcx  ;loop iteration counter
    xor r9,r9     ;row byte offset (should be redone to account for different data types [base+(offset*size)+displacement])
    xor r13,r13   ;holds offset for printing
    mov r12, OutputBufferAddr
    xor r14,r14   ;offset for OutputBufferAddr 
  @DisplayMemListingHeader:
    ;print a single line that lables columns
  @DisplayMemLoopMain:
    @PrintCurrentOffset:
      ;Display offset of 1st item in row from address in MemAddr
      mdbgSaveGPRsInMem
      ;############################
      ;print row address offset label
      ;############################
        ;invoke StringCchPrintf, r12,"+%012llx:  ",r13;r9
        invoke sprintf, r12, ADDR fmtPrintQwordHexOffset,r13
        movq xmm0, rax ; terrible but oh well (save # of characters written)
      mdbgRestoreGPRsFromMem
      ;############################
      ;update addr in r12 for printing
      ;############################
        push rax
        movq rax, xmm0 ;get # of characters written
        add r12, rax ;offset r12 by # of characters written
        pop rax
      ;Prepare for printing the row of data
      ;rcx is still 0
      ;rax is still MemAddr
      ;rdx is still NumOfDataItems
      ;r12 is the address of the output buffer 
      ;r14 is the offset of the current character
      xor rcx,rcx
      xor r9,r9     ;row byte offset (should be redone to account for different data types [base+(offset*size)+displacement])
    @PrintCurrentRowLoop: ;
      ;-----------redo to support differently sized data---------------
          ;get a qword from memory block pointed to by MemAddr to print in row
          mov r8, [rax+r9]
      
      mdbgSaveGPRsInMem
      ;invoke StringCchPrintf, OutputBufferAddr,ADDR fmtPrintQwordHex,r8
      ;lea r12, [r12+r9] ;offset r12 by row byte offset
      invoke sprintf, r12, ADDR fmtPrintQwordHex, r8 
      movq xmm0, rax ;save # of characters written
      mdbgRestoreGPRsFromMem
      push rax
      movq rax, xmm0
      add r12, rax ;offset r12 byte # of characters written to buffer
      pop rax

      dec rdx ;decrement number of data items (redundant)
      inc rcx ;increment iteration counter
      ;-----------redo to support differently sized data---------------
          add r9, 8   ;add 8 to offset (8 bytes per qword)
      ;xor r12, r12
      test rdx, rdx ;if there are no data items left to print, exit loop
      jz @f
      cmp rcx, r11
      jnge @PrintCurrentRowLoop ;repeat until the current row has been printed
      add rax, r9   ;update base address for next row
      add r13, r9   ;update offset used for labeling row offsets
      add r12, r9   ;update OutputBufferAddr offset 
      mdbgSaveGPRsInMem
      invoke sprintf, r12,"\n"        ;print new line after row has been printed
      movq xmm0, rax
      mdbgRestoreGPRsFromMem
      push rax
      movq rax, xmm0
      add r12, rax; add 2 bytes to account for the newline
      ;add r12, 2; add 2 bytes to account for the newline
      pop rax
      jmp @DisplayMemLoopMain   ;start new iteration of main loop
  @@:
      invoke sprintf, OutputBufferAddr,"\n"        ;print new line at the end of last data item in last row

  @FuncExit:
    ret
DisplayMemoryEx endp
