%macro write_string 2
    ; save rsi, rdx registers
    push rsi
    push rdx

    mov	rdx, %2	    ;message length
    mov	rsi, %1	    ;message to write
    mov	rdi, 1	    ;file descriptor (stdout)
    mov	rax, 1	    ;system call number (sys_write)
    syscall  	    ;call kernel

    ; restore registers
    pop rdx
    pop rsi
%endmacro

%macro configureSingleInput 0
    ; Get current settings
    mov  eax, 16             ; syscall number: SYS_ioctl
    mov  edi, 0              ; fd:      STDIN_FILENO
    mov  esi, 0x5401         ; request: TCGETS
    mov  rdx, termios        ; request data
    syscall

    ; Modify flags
    and byte [c_lflag], 0FDh  ; Clear ICANON to disable canonical mode

    ; Write termios structure back
    mov  eax, 16             ; syscall number: SYS_ioctl
    mov  edi, 0              ; fd:      STDIN_FILENO
    mov  esi, 0x5402         ; request: TCSETS
    mov  rdx, termios        ; request data
    syscall
%endmacro

%macro exit_program 0
    mov	eax, 1	;system call number (sys_exit)
    int	0x80	;call kernel
%endmacro

section   .text
    global    _main

_main:

    configureSingleInput
    ; to fill all data
    mov [ userIntput ], dword 0

mainLoop:
    ; convert string to number
    lea rsi, userIntput
    mov bh, 4
    call hex2number

    lea rsi, buffer
    call numbler2string

    lea ecx, [ buffer ]
    call stringLength

    push rax
    write_string dec, decLen
    write_string buffer, rsi
    write_string endOfLine, endOfLineLen
    pop rax

    lea ecx, [ userIntput ]
    call stringLength

    push rax
    write_string hex, hexLen
    write_string userIntput, rsi
    write_string endOfLine, endOfLineLen
    pop rax

    lea rsi, buffer
    call numbler2octa

    lea ecx, [ buffer ]
    call stringLength

    push rax
    write_string oct, octLen
    write_string buffer, rsi
    write_string endOfLine, endOfLineLen
    pop rax

    lea rsi, buffer
    call numbler2binary

    lea ecx, [ buffer ]
    call stringLength

    write_string bin, binLen
    write_string buffer, rsi
    write_string endOfLine, endOfLineLen

    write_string msg, len

    mov	rdx, 4	;message length
    mov	rsi, userIntput	;message to read
    mov	rdi, 0	    ;file descriptor (stdout)
    mov	rax, 0	    ;system call number (sys_read)
    syscall  	    ;call kernel

    jmp mainLoop

    ; exit program
    exit_program

;-----------------------------------------------
; INPUT  ECX - String
; OUTPUT RSI - string offset
stringLength:
    mov  rsi, 0

countLenth:
    cmp byte [ ecx ], 0
    jz countFinish

    inc rsi
    inc ecx
    jmp countLenth

countFinish:
    ret

;-----------------------------------------------
; INPUT  AX - Number to oct
;        SI - offset string
; OUTPUT AX - oct number as string

numbler2binary:
    push rax
    mov rbx, 2  ; digits extracted dividing by 2
    mov rcx, 0  ; for extended digits

numberBinaryCycle:
    mov  rdx, 0 ; to divide by bx
    div  bx    ; resoult in dx:ax / 2 - ax main number dx reminder

    push dx    ; save for later
    inc  cx

    cmp ax, 0  ; in digit non zero -> loop
    jne numberBinaryCycle

    ;get digits from stack
    lea rsi, buffer

numberBinaryCycle2:
    pop dx
    add dl, 48 ; convert digit to asci char
    mov [ rsi ], dl
    inc rsi
    loop numberOctCycle2

    pop rax
    ret

;-----------------------------------------------
; INPUT  AX - Number to oct
;        SI - offset string
; OUTPUT AX - oct number as string

numbler2octa:
    push rax
    mov rbx, 8  ; digits extracted dividing by 8
    mov rcx, 0  ; for extended digits

numberOctCycle:
    mov  rdx, 0 ; to divide by bx
    div  bx    ; resoult in dx:ax / 8 - ax main number dx reminder

    push dx    ; save for later
    inc  cx

    cmp ax, 0  ; in digit non zero -> loop
    jne numberOctCycle

    ;get digits from stack
    lea rsi, buffer

numberOctCycle2:
    pop dx
    add dl, 48 ; convert digit to asci char
    mov [ rsi ], dl
    inc rsi
    loop numberOctCycle2

    pop rax
    ret

;-----------------------------------------------
; INPUT  AX - Number to decimal
;        SI - offset string
; OUTPUT AX - number as string

numbler2string:
    push rax
    mov rbx, 10 ; digits extracted dividing by 10
    mov rcx, 0  ; for extended digits

numberCycle:
    mov  rdx, 0 ; to divide by bx
    div  bx    ; resoult in dx:ax / 10 - ax main number dx reminder

    push dx    ; save for later
    inc  cx

    cmp ax, 0  ; in digit non zero -> loop
    jne numberCycle

    ;get digits from stack
    lea rsi, buffer

numberCycle2:
    pop dx
    add dl, 48 ; convert digit to asci char
    mov [ rsi ], dl
    inc rsi
    loop numberCycle2

    pop rax
    ret

;-----------------------------------------------
; INPUT  BH - String length
;        RSI - offset string address
; OUTPUT RAX - number

hex2number:
    mov rax, 0 ; clear rax register

    ; Shift register AL left 4 times
shiftAX4Times:
    mov BL, [ rsi ]

    ;validate entered string
    cmp bl, '0'
    jb  hexFinish     ;IF BL < '0'

    cmp bl, 'F'
    ja  hexFinish     ;IF BL > 'F'

    cmp bl, '9'
    jbe validateOk        ;IF BL <= '9'

    cmp bl, 'A'
    jae validateOk        ;IF BL >= 'A'
validateOk:
    shl AL, 1
    rcl AH, 1

    shl AL, 1
    rcl AH, 1

    shl AL, 1
    rcl AH, 1

    shl AL, 1
    rcl AH, 1

    cmp bl, 'A' ; check if content of register is a letter
    jae hexLetter

    sub bl, 48 ; places ready number to AX reg
    jmp hexFinish

hexLetter:
    sub bl, 55 ; letter to number from asci table

hexFinish:
    or al, bl  ; clear upper 4 bits
    inc rsi    ; next char from SI
    dec bh
    cmp bh, 0  ; if BH == 0, all chars has been converted
    jnz shiftAX4Times

    ret

section   .data
    bin:      db      "[bin] = "
    binLen    equ     $ - bin

    oct:      db      "[oct] = "
    octLen    equ     $ - oct

    dec:      db      "[dec] = "
    decLen    equ     $ - dec

    hex:      db      "[hex] = "
    hexLen    equ     $ - hex

    msg:      db      "           Linia poleceń: "
    len       equ     $ - msg

    endOfLine:      db      "", 10
    endOfLineLen    equ     $ - endOfLine

section   .bss
    buffer:          resq     2
    userIntput:      resq     4

    termios:
      c_iflag resd 1   ; input mode flags
      c_oflag resd 1   ; output mode flags
      c_cflag resd 1   ; control mode flags
      c_lflag resd 1   ; local mode flags
      c_line  resb 1   ; line discipline
      c_cc    resb 19  ; control characters

