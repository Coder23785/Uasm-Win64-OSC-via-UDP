;#########################
; ------------------------
; Date: 2/4/2024 
; My first use of Win 
; Sockets 2 and networking 
; in general with the 
; Winapi. 
; ------------------------
; Date: [02/04/2025]
; ------------------------
; Written by Jay
; ------------------------
; Contact: 
; err_code_jay@outlook.com
; ------------------------
;#########################

.x64
option Literals:on ; allow literal string usage in function parameters
option win64:8
option frame:auto ; [Jwasm/Uasm]:generate SEH-compliant procedure prologues and epilogues
include winsock2.inc

;############# procedures
main proto
Real4ToBigEndian proto :REAL4
;#############

$WSAVER RECORD _hiword_wsaver:16, _lowword_wsaver:16

PADDRINFO TYPEDEF PTR ADDRINFO
$PSOCKADDR_IN TYPEDEF PTR SOCKADDR_IN
.const
  RECVBUFSIZE EQU <4096>           ;size of buffer for receiving data (in bytes as always)
  SENDBUFSIZE EQU <4096>
  ;numeric constants for ports listed above in string form
    _PORT  =  9000 
    _PORT2 =  9001
.data?
  hInstance HINSTANCE ?
  wsadata WSADATA <>

  addrinfohints ADDRINFO <>
  addrinforesult QWORD ? 

  recvbuf BYTE RECVBUFSIZE dup (?) ;buffer for receiving data from connection
  sendbuf BYTE SENDBUFSIZE dup (?) ;buffer for sending data 
  ClientService SOCKADDR_IN <>
.data
  ConnectSocket  SOCKET 0; INVALID_SOCKET ;for receiving data 
  ConnectSocket1 SOCKET 0; INVALID_SOCKET ;for sending data

  IntroMsg  db "|-------------------------------------|",13,10
            db "|   OSC over UDP example program",13,10  
            db "|-------------------------------------|",13,10
            db "| Made by:  'Jay'",13,10
            db "| Contact:   err_code_jay@outlook.com",13,10
            db "|-------------------------------------|",13,10
            db "Crafted in the fires of UASM, an MASM compatible assembler...",13,10,10,0
  EndMsg    db "Press any key to continue...",13,10,0
  hostaddr  db "127.0.0.1",0
  port      db "9000",0 
  port2     db "9001",0
  ;OSCMsg    db "/testing/1/Float ,",0 ;unused
  OSCMsg1 LABEL BYTE
            db "/test/2/Vector2" 
            db 0
            db ",ff",0          ;indicate that two floats are in this OSC message
            db 03Fh,040h,0h,0h  ;(Big Endian single precision float) 
            dd 0000603Fh        ;(Big Endian single precision float)
  OSCMs1Size EQU ($ - OSCMsg1)

  ;#############################
  ; The data below is just
  ; for seeing how floating 
  ; point numbers look when
  ; viewed in byte form.
  ; A disassembler isn't needed,
  ; just look at the listing 
  ; file winsock2.lst!
  ;#############################
  TESTREALNUMS LABEL DWORD
  REAL4 0.0
  REAL4 0.1
  REAL4 0.2
  REAL4 0.5  
  REAL4 0.6
  REAL4 1.0
  REAL4 440.0

.code
WinMainCrtStartup proc
  @Start:
    invoke main
    invoke printf, ADDR EndMsg
    invoke _getch
    invoke ExitProcess, eax 
  @End:
WinMainCrtStartup endp

main proc
  LOCAL Temp:QWORD

  invoke printf, ADDR IntroMsg 
  @StartupWSA:
    mov eax, $WSAVER<2,2>
    invoke WSAStartup, ax, ADDR wsadata
    test rax, rax
    jz @f
      printf("Call to 'WSAStartup' failed with error code: %ld\n",rax)
      jmp @MainExit
  @@:
  ;################################################
  ; "Setup hints address info structure which is 
  ; passed to the getaddrinfo() function" - From
  ; WinApi documentation on the getaddrinfo 
  ; function in the winsock api.
  ;################################################
    ASSUME RAX:PADDRINFO
    mov rax, OFFSET addrinfohints
    mov [rax].ai_family, AF_INET        ;Use IPv4
    mov [rax].ai_socktype, SOCK_DGRAM   ;SOCK_DGRAM = Datagram socket, required for UDP
    mov [rax].ai_protocol, IPPROTO_UDP  ;Check OSC docs to see what is required for protocol.
    ASSUME RAX:NOTHING
    invoke getaddrinfo, ADDR hostaddr, ADDR port, rax, ADDR addrinforesult
    test rax, rax 
    jz @f   
      printf("Call to getaddrinfo failed with error code: %ld\n",rax)
      jmp @ShutdownWSA
  @@:
  ;##########################
  ; See if addrinforesult has
  ; a valid pointer in it
  ;##########################
    mov rax, addrinforesult
    printf("Value in 'addrinforesult': %ld\n",rax)

    ASSUME RAX:PADDRINFO
    mov rax, addrinforesult ; addrinforesult holds ptr to addrinfo struct
    mov ebx, [rax].ai_family
    mov r13d, [rax].ai_socktype
    mov r14d, [rax].ai_protocol
    ASSUME RAX:NOTHING
    COMMENT *
    invoke socket, AF_UNSPEC,\      ;AF_INET = IPv4
                    SOCK_STREAM,\ ;
                    IPPROTO_TCP   ;Use TCP protocol
                    *
    invoke socket, ebx, r13d, r14d
    ;#############################
    ; Debugging
    ;=============================
    ;save socket ret value
    mov Temp, rax

    ASSUME RAX:PADDRINFO
    mov rax, addrinforesult
    mov ebx, [rax].ai_family
    mov r13d, [rax].ai_socktype
    mov r14d, [rax].ai_protocol
    ASSUME RAX:NOTHING
    printf("addrinforesult.ai_family: %d\naddrinforesult.ai_socktype: %d\naddrinforesult.ai_protocol: %d\n",\
                 ebx,r13d,r14d) 
    
    ;Restore socket ret value
    mov rax, Temp     
    ;=============================
    ;#############################

    ;cmp rax, INVALID_SOCKET
    test rax, rax
    jnz @f                        ;INVALID_SOCKET = 0? ("#define INVALID_SOCKET (SOCKET)(~0)")
      invoke WSAGetLastError
      printf("Call to 'socket' failed with error code: %ld\n",rax)
      jmp @ShutdownWSA
  @@:
    mov ConnectSocket, rax        ;save SOCKET
    printf("Return value of socket: %ld\n",rax)
    invoke WSAGetLastError
    printf("(after call to socket) WSAGetLastError error code: %ld\n",rax)
  ;################################################
  ; "The sockaddr_in" structure specifies the 
  ;  address family, IP address, and port of the
  ;  server to be connected to" - WinApi WinSock
  ;  documentation for the "send" function.
  ;################################################
    ASSUME R8:$PSOCKADDR_IN
    mov r8, OFFSET ClientService
    mov [r8].sin_family, AF_INET    ;IPv4
    mov Temp, r8
    invoke inet_addr, ADDR hostaddr ;hostaddr "127.0.0.1" 
    mov r8, Temp
    mov [r8].sin_addr.s_addr, eax 
    mov Temp, r8
    invoke htons, _PORT
    mov r8, Temp
    mov [r8].sin_port, ax
    ASSUME R8:NOTHING

    ;#############################
    ; Debugging
    ;=============================
    invoke WSAGetLastError
    printf("(after filling ClientService struct) WSAGetLastError error code: %ld\n",rax)
    ;=============================
    ;#############################

  ;###################
  ; Connect to server
  ;###################
    invoke connect, ConnectSocket,\
                    ADDR ClientService,\
                    SIZEOF ClientService
    cmp rax, SOCKET_ERROR
    jne @f
      invoke WSAGetLastError
      printf("Call to 'connect' failed with error code: %ld\n",rax)
      jmp @CloseSocket  
  @@:
    ;#############################
    ; Debugging
    ;=============================
    invoke WSAGetLastError
    printf("(after call to 'connect') WSAGetLastError error code: %ld\n",rax)
    ;=============================
    ;#############################
  ;#############
  ; Send data
  ;#############
  @SendData:
    ;invoke send, ConnectSocket, ADDR sendbuf, SENDBUFSIZE, 0
    invoke send, ConnectSocket, ADDR OSCMsg1, OSCMs1Size, 0
    cmp rax, SOCKET_ERROR
    jne @f
      invoke WSAGetLastError
      printf("Call to 'send' failed with error code: %ld\n",rax)
      jmp @CloseSocket  
  @@:
    printf("Number of bytes sent: %ld\n",eax)
    invoke shutdown, ConnectSocket, SD_SEND 
    cmp rax, SOCKET_ERROR
    jne @f
      invoke WSAGetLastError
      printf("Call to 'shutdown' failed with error code: %ld\n",rax)
      jmp @CloseSocket
  @@:
    invoke WSAGetLastError
    printf("WSAGetLastError error code: %ld\n",rax)
    invoke DisplayMemory, ADDR OSCMsg1, OSCMs1Size, NULL 
  @CloseSocket:
    invoke closesocket, ConnectSocket
    invoke freeaddrinfo, addrinforesult 
  @ShutdownWSA:
    invoke WSACleanup
  @MainExit:
    ret 0; return value, (given to ExitProcess as parameter)
main endp

;###########################
; Real4ToBigEndian 
;---------------------------
; This procedure is untested
;---------------------------
; Converts a little Endian
; single precision floating-
; point number into its big
; endian equivalent
;---------------------------
; It is worth noting that
; the Winsock API has 
; functions for converting 
; different variables into 
; their big endian 
; equivalent.
;###########################
Real4ToBigEndian proc num:REAL4
  mov ebx, num ;copy num to ebx and ecx so bytes can be reordered 
  mov ecx, ebx 
  shr ecx, 16  ;shift high word from "num" into 16-bit cx register
  ;bl = byte 1 (lowest byte in little endian,highest in big endian) 
  ;bh = byte 2
  ;cl = byte 3
  ;ch = byte 4 (highest byte in little endian)
  mov ah, bl
  mov al, bh
  shl eax, 16 ;shift high word for big endian float into upper 16bits of eax
  mov ah, cl ;ah = byte 3
  mov al, ch ;al = byte 4 (highest byte in little endian, now the lowest byte)
  ret
Real4ToBigEndian endp

end

