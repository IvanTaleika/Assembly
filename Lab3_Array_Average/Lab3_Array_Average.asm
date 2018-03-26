.model small 
.stack 100h
.data
    numberTen dw 000Ah
    sizeOfNumber equ 2
    maxAccuracy equ 10
    maxArrayLength equ 1Eh ;30
    numberStringLength equ 20  
    accuracy dw ?
    length dw ? 
    array dw maxArrayLength dup(0)                                     
    numberString db numberStringLength dup('$')
    inputLimitsString db "Max array length = 30. Max accuracy = 10. ", 0Dh, 0Ah, "Max array element value = 32767, min = -32767.$"
    invalidLengthString db "Invalid length input. 1 <= length <= 30.$"
    invalidAccuracyString db "Invalid accuracy input. 0 <= accuracy <= 10.$"
    inputLengthString db "Input array length:$" 
    inputArrayString db "Input array numbers:$" 
    inputAccuracyString db "Input accuracy:$"
    invalidInputString db "Invalid input. $" 
    overflowInputString db "Number is too big. $"
    overflowSumString db "Array sum overflow. Further work is impossible.$"
    tryAgainString db "Try again:$" 
    inputInviteString db "Enter number:$"
    newLine db 0Dh,0Ah,'$'
.code 
 
;NUMBER INPUTING
;cs - number of inputing elements; di - input destination
;After inputing di points on memory behind numbers
inputNumbers proc
    call printNewLine
    lea dx, inputInviteString
    call outputString
repeatElementInput:
    lea dx, numberString   ; load string adress offset
    call inputString          
    lea si, numberString[2]
    call parseString
    jc invalidInput
    call loadNumber 
    loop inputNumbers
ret

invalidInput:
    call printNewLine
    lea dx, invalidInputString
    call outputString
    jno tryAgainOutput
    lea dx, overflowInputString
    call outputString
tryAgainOutput:
    lea dx, tryAgainString
    call outputString
    jmp repeatElementInput
    
loadNumber:
    mov [di], ax
    add di, sizeOfNumber
ret 
inputNumbers endp

;STRING TO NUMBER PARSING
;Registers dx,bx,ax are required, si - adress of input string
;ax contents result, cf inducats errors    
parseString proc
    xor dx,dx
    xor bx,bx
    xor ax,ax
    jmp inHaveSign  
parseStringLoop:
    mov bl, [si]        ;1 numeral = 1 byte
    jmp isNumber
validString:
    sub bl, '0'
    imul numberTen             ; ax * 10
    jo invalidString           ; number > 16 bit
    js invalidString           ; number > 15 bit
    add ax, bx
    ;jo invalidString           ; number > 16 bit
    js invalidString           ; number > 15 bit 
    inc si
    jmp parseStringLoop
    
isNumber:
    cmp bl, 0Dh         ;enter key
    je endParsing       ;end of number
    cmp bl, '0'                               
    jl invalidString     ;not a number
    cmp bl, '9'
    jg invalidString     ;not a number      
    jmp validString      ;number

inHaveSign:
    cmp [si], '-'
    je negative
    push 1
    cmp [si], '+'
    jne isNullString
    inc si     
    jmp isNullString
    
negative:
    push -1
    inc si
    jmp isNullString

isNullString:
    cmp [si], 0Dh
    je invalidString
    jmp parseStringLoop
        
invalidString:
    pop bx   ;pop 1 or -1
    stc
ret

endParsing:
    pop bx
    imul bx
    clc
ret
parseString endp


;ARRAY SUM
;si - array; cx - array's size; ax - result
;of flag indicates overflow
findArraySum proc
    add ax, [si]
    jo endAddition
    add si, sizeOfNumber  
    loop findArraySum
endAddition:
ret
findArraySum endp

;NUMBER OUTPUT
;ax - quotient, dx - remainer, bx - divisor, cx - accuracy, di - result adress
;Registers ax, bx, dx, cx and stack are required 
;After converting di points after '$' symbol
numberToString proc
    push dx            ;remainer          
    push 0024h         ;$ - indicate end of number
    add ax, 0000h      ;find out if number < 0
    js numberIsNegative  
quotientToStringConvertingLoop:    
    xor dx,dx ;for remainer of division
    div numberTen
    add dx, '0'
    push dx
    cmp ax, 0h
    jne quotientToStringConvertingLoop   
moveQuotientToBuffer:
    pop ax
    cmp al, '$'
    je moveRemainerToBuffer
    mov [di], al
    inc di
    jmp moveQuotientToBuffer
moveRemainerToBuffer:
    pop ax       ;pop remainver
    cmp cx, 0
    je endConverting
    mov [di], '.'
    inc di    
remainerConvertingLoop:
    mul numberTen
    idiv bl         ;divisor <= 30(maxLength)
    add al, '0'
    mov [di], al
    inc di
    mov al, ah
    xor ah, ah
    loop remainerConvertingLoop
endConverting:
    mov [di], '$'
ret

numberIsNegative:
    mov [di], '-'
    inc di
    not ax          
    inc ax          ;for right converting from negative to positive
    jmp quotientToStringConvertingLoop 
numberToString endp    

;LENGTH INPUT
lengthInput proc
    call printNewLine    
    lea dx, inputLengthString
    call outputString         
    lea di, length  
    mov cx, 0001h         ;one number input
    call inputNumbers
    cmp ax, maxArrayLength
    jg invalidLengthInput
    cmp ax, 0001h
    jl invalidLengthInput     
    call printNewLine
ret

invalidLengthInput:
    call printNewLine
    lea dx, invalidLengthString
    call outputString
    call printNewLine
    jmp lengthInput  
lengthInput endp

;ARRAY INPUT
arrayInput proc
    call printNewLine 
    lea dx, inputArrayString
    call outputString             
    xor cx, cx
    mov cx, length     
    lea di, array  ;load array offset
    call inputNumbers
    call printNewLine 
ret
arrayInput endp

;ACCURACY INPUT
accuracyInput proc
    call printNewLine     
    lea dx, inputAccuracyString
    call outputString                          
    lea di, accuracy  
    mov cx, 0001h
    call inputNumbers
    cmp ax, maxAccuracy
    jg invalidAccuracyInput
    cmp ax, 0000h
    jl invalidAccuracyInput     
    call printNewLine
ret

invalidAccuracyInput:
    call printNewLine
    lea dx, invalidAccuracyString
    call outputString
    call printNewLine
    jmp accuracyInput
      
accuracyInput endp

;FIND AVERAGE
;ax - quotient, dx - remainer
findAverage proc
    mov cx, length
    lea si, array
    xor ax,ax
    call findArraySum
    jo overflowSum
    call axToDword
    idiv length
    add dx, 0000h      ;find out if number < 0
    jns findAverageEnd
    not dx          
    inc dx          ;for right converting from negative to positive
findAverageEnd:     
ret

overflowSum:
    call printNewLine
    lea dx, overflowSumString
    call outputString
    jmp exit
findAverage endp 

;AX TO DX:AX number converting
;convert 16 bit number in ax to 32 number in dx:ax
axToDword proc          
    xor dx,dx          ;for remainder
    add ax, 0000h      ;find out if number < 0
    jns axToDwordEnd
    not dx
axToDwordEnd:
ret
axToDword endp

;IN/OUT PROCEDURES 
printNewLine proc
    lea dx, newLine
    call outputString
ret
printNewLine endp

outputString proc
    mov ah, 09h
    int 21h    
ret
outputString endp

inputString proc
    mov ah, 0Ah
    int 21h
ret
inputString endp

;START
start:
    mov ax, data
    mov ds, ax
    mov es, ax
    xor ax, ax 
    
    mov [numberString], numberStringLength
    
    lea dx, inputLimitsString
    call outputString
    call printNewLine

    call lengthInput
    call arrayInput 
    call accuracyInput    
    call findAverage
 
    mov bx, length
    mov cx, accuracy
    lea di, numberString[2]
    call numberToString       ;Convert quotient to string

    lea dx, numberString[2]
    call outputString         ;Output result    
    
exit:    
    mov ax, 4c00h ; exit to operating system.
    int 21h    
ends

end start ; set entry point and stop the assembler.    