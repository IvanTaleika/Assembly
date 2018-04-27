.model tiny
.stack 100h 
.code
start: jmp init 
    color db 07h         ;white text, black background
    videobuffOffset dw 0000h

;read data (seconds, minuts or hours) from register specified in al
;and split data to bl (high ten) and al (low ten) 
getClockRegisterData proc
    out 70h, al ;70h - port whick choose what clock register we want
    in al, 71h  ;71h - port to read\write data from\in clock registers    
ret
getClockRegisterData endp    

;split BCD number from al to bl (high ten) and al (low ten)
;and convert to ascii code
splitBCD proc
    mov bl, al
    and al, 0Fh ;00001111b
    add al, '0' ;ASCII code
    shr bl, 4   ;>>4           
    add bl, '0'
ret
splitBCD endp
    
;write time (seconds, minuts or hours) from bx (high ten) and ax (low ten)
;to es:[si], es - videobuff, si, print offset.
;after proc si point to next time input place
;ah and bh - symbols attributes 
writeTimeToVideobuff proc
    mov es:[si], bx
    add si, 2
    mov es:[si], ax
    add si, 2  
ret
writeTimeToVideobuff endp

new70Handler proc far
    pusha
    mov ax, cs
    mov ds, ax 
    mov ax, 0B800h ;videobuff   
    mov es, ax
    mov si, videobuffOffset  ;first line last symbol
    mov ah, color    
    mov bh, ah
    
    mov al, 04h ;hours seconds register        
    call getClockRegisterData
    call splitBCD
    call writeTimeToVideobuff
    mov es:[si], 073Ah ;white ":" on black background
    add si, 2  
    
    mov al, 02h  ;minuts
    call getClockRegisterData
    call splitBCD
    call writeTimeToVideobuff
    mov es:[si], 073Ah 
    add si, 2      
   
    mov al, 00h   ;seconds
    call getClockRegisterData
    call splitBCD
    call writeTimeToVideobuff  
odlInt:    
    popa
    db 0EAh
    oldHandler dd ?
new70Handler endp

;di - from (command line), si - to (dw buff), ax - result, bx - corrupted
readPosition proc
    xor ax, ax
    xor bx, bx
skipSpaces:
    cmp ds:di, 0Dh
    je readError
    cmp ds:di, ' '
    jne getWord
    inc di
    jmp skipSpaces
getWord:      
    mov al, ds:di
    inc di
    sub al, '0'   

    mov bl, ds:di
    cmp bl, 0Dh
    je oneSymbol
    cmp bl, ' '
    je oneSymbol     
    inc di
    sub bl, '0' 
    mov bh, 0Ah
    mul bh    
    add al, bl
ret  
oneSymbol:
ret    
readError:
    stc    
ret
readPosition endp    

inputError:
    lea dx, invalidInputMessage
    mov ah, 09h
    int 21h
    jmp endProgram
    
init:
    mov di, 81h
    lea si, commandLineData

    call readPosition
    jc inputError
    cmp ax, 0
    jl inputError
    cmp ax, 24
    jg inputError
    cmp ds:di, 0Dh
    je inputError

    mul columsNumber
    mov videobuffOffset, ax
    
    lea si, commandLineData
    call readPosition
    jc inputError
    cmp ax, 0
    jl inputError
    cmp ax, 72     ;(80 minus place for clock)
    jg inputError
    
    cmp ds:di, 0Dh
    jne inputError
    
    add ax, videobuffOffset
    xor dx, dx
    mul bytesForSymbol
    mov videobuffOffset, ax  ;save place to display

    mov ax, 351Ch     ; get 1Ch interrupt handler
    int 21h
    mov  oldHandler, bx
    mov  oldHandler+2, es

    lea dx, new70Handler
    mov ax, 251Ch
    int 21h
    
    lea ax, readPosition
    sub ax, offset start
    add ax, 10fh
    xor dx, dx
    mov bx, 0010h
    div bx
    mov dx, ax
    mov ah, 31h
    int 21h

endProgram:    
    mov ax, 4c00h 
    int 21h    
ends 

    commandLineData db 2 dup(?)
    columsNumber db 80
    bytesForSymbol dw 2
    invalidInputMessage db "Input rows (0-24) and colums (0-72) where clock will be displayed.$"

end start
