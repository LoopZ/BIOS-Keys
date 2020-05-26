; Copyright 2020 Jerome Shidel
; Released to Public Domain

    org 0x100

    use16

    call InitTraps

    mov     si, Message
    call    PrintString

BIOSInputLoop:

    ; Key keboard status
    mov     ah, 0x01
    int     0x16
    jnz     BIOSInputLoop

    ; Check if scan code is available
    test    ax, ax
    jz      BIOSInputLoop

    ; pull keystroke from buffer
    mov     ah, 0
    int     0x16

    push    ax
    mov     si, ScanCode
    call    PrintString
    mov     al, ah
    call    PrintHexAL
    pop     ax

    push    ax
    mov     si, AsciiValue
    call    PrintString
    call    PrintHexAL

    mov     si, CountInt1B
    call    PrintString
    mov     ax, [DataInt1B]
    call    PrintHexAX

    call    PrintCRLF
    pop     ax
    cmp     al, 27
    jne     BIOSInputLoop

Terminate:
    call    DoneTraps
    ; Terminate with no error
    mov     ax, 0x4c00
    int     0x21


Vector1B:
    dw 0,0

DataInt1B:
    dw 0

MyInt1B:
    push    ax
    mov     ax, [CS:DataInt1B]
    inc     ax
    mov     [CS:DataInt1B], ax
    pop     ax
    iret

InitTraps:
    mov [Vector1B], word MyInt1B
    mov [Vector1B+2],ds

    mov     al, 0x1b
    mov     di, Vector1B
    call    SwapVectors
    ret

DoneTraps:
    mov     al, 0x1b
    mov     di, Vector1B
    call    SwapVectors
    ret

SwapVectors:
    ; AL = Vector
    ; [di] = pointer
    push  bx
    push  dx
    push  es
    push  ds
    call  GetIntVector
    mov   dx, [di]
    mov   ds, [di+2]
    call  SetIntVector
    pop   ds
    mov   [di], bx
    mov   [di+2], es
    pop   es
    pop   dx
    pop   bx
    ret

GetIntVector:
    ; AL = vector
    ; Returns ES:BX
    push    ax
    mov     ah, 0x35
    int     0x21    ; returns es:bx
    pop     ax
    ret

SetIntVector:
    ; AL = vector
    ; DS:DX = Pointer
    push    ax
    mov     ah, 0x25
    int     0x21
    pop     ax
    ret

PrintHexAX:
    push    ax
    push    ax
    mov     al, ah
    call    PrintHexAL
    pop     ax
    call    PrintHexAL
    pop     ax
    ret

PrintHexAL:
    push    cx
    push    ax
    and     al, 0xf0
    mov     cl, 0x04
    shr     al, cl
    call    MapToHex
    call    PrintAL
    pop     ax
    push    ax
    and     al, 0x0f
    call    MapToHex
    call    PrintAL
    pop     ax
    pop     cx
    ret

MapToHex:
    add     al, 0x30
    cmp     al, 0x3a
    jb      .Done
    add     al, 0x07
.Done:
    ret

PrintAL:
    push    ax
    push    bx
    mov     bx, 0x0007
    mov     ah, 0x0e
    int     0x10
    pop     bx
    pop     ax
    ret

PrintString:
    push    ax
    push    bx
.Repeat:
    mov     al, [si]
    cmp     al, 0
    je      .Done
    inc     si
    call    PrintAL
    jmp     .Repeat
.Done:
    pop     bx
    pop     ax
    ret

PrintCRLF:
    push    si
    mov     si, CRLF
    call    PrintString
    pop     si
    ret


ScanCode:
    db 'Scancode: ',0
AsciiValue:
    db ', Ascii: ', 0
CountInt1B:
    db ', Count Int1B: ',0
Message:
    db 'Press the ESC key to exit'
CRLF:
    db 0xd,0xa,0
