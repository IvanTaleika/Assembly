
.model small

.data 
    enterStr db "Enter string:",0Dh,0Ah,'$'
    enterSubStr db 0Dh,0Ah,"Enter substring:",0Dh,0Ah,'$'
    result db 0Dh,0Ah,"Result is:",0Dh,0Ah,'$' 
    
    sizeError db 0Dh,0Ah,"Enter substring:",0Dh,0Ah,'$'
    
    length equ 0CBh    ;203
    maxSybols equ 0C8h
    string db length dup('$')
    subString db length dup('$')


.code 

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
                     
                     
isEmpty:
    mov ah, [string[1]]
    cmp ah, 0
    je outputResult    
    mov al, [subString[1]] 
    cmp al, 0
    je outputResult
    jmp isBigEnough
    
isBigEnough:
    cmp ah,al
    jg findWord
    jmp outputResult

findWord:
    mov si, offset string[1]
    mov di, offset subString[2]    
findFirstSymbol:
    call isEnd
    cmp [si], ' '
    je findFirstSymbol
    mov dl, [si]  ;for cpm with another string symbol
    cmp dl, [di]    ;first subString symbol     
    je compareWords
    jmp skipWord
    
compareWords:
    inc di
    cmp [di], 0Dh   
    je checkEndOfWord
    call isEnd
    mov dl, [si]  ;for cpm with another string symbol  
    cmp dl, [di]
    je compareWords
    mov di, offset subString[2] ;check first symbol of subStr again
    jmp skipWord

skipWord:
    call isEnd            
    cmp [si], ' '
    je findFirstSymbol
    jmp skipWord

checkEndOfWord:
    call isEnd
    cmp [si], ' '
    je findNextWordStart
    mov di, offset subString[2] ;check first symbol of subStr again
    jmp skipWord

findNextWordStart:
    call isEnd
    cmp [si], ' '
    je findNextWordStart
    mov bx, si ;next word first symbol pos
    jmp findNextWordEnd

findNextWordEnd:
    inc si
    cmp [si], '$'
    je deleteNextWord
    cmp [si], ' '
    je deleteNextWord
    jmp findNextWordEnd
    
deleteNextWord:
    mov dl, [si]
    mov [bx], dl
    cmp [bx], '$'
    je outputResult
    inc bx
    inc si
    jmp deleteNextWord
    
        
isEnd proc   ;check next symbol with '$' symbol
    inc si
    cmp [si], '$'
    je outputResult
ret
isEnd endp 

;delete all subString words exept 1st
convertSubStringToWord proc
    lea si, subString[1]
convertSubStringToWordLoop:
    inc si    
    cmp [si], 0Dh
    je convertSubStringToWordEnd
    cmp [si], ' '
    jne convertSubStringToWordLoop

    mov [si], 0Dh
    mov [si+1], '$'        
convertSubStringToWordEnd:    
ret
convertSubStringToWord endp

start:

    mov ax, @data
    mov ds, ax 
    mov es, ax
    

    mov [string], maxSybols
    mov [subString], maxSybols
    
    mov dx, offset enterStr  ;output enterStr
    call outputString
    
    mov dx, offset string      ;input string
    call inputString
    
    mov dx, offset enterSubStr    ;output enterSubStr
    call outputString
    
    mov dx, offset subString      ;input string
    call inputString 
    
    call convertSubStringToWord
    
    jmp isEmpty
   
outputResult:    
    
    mov dx, offset result     ;output result
    call outputString
           
    mov dx, offset string[2]     ;output result
    call outputString
           
    
    mov ax, 4c00h ; exit to operating system.
    int 21h    

end start ; set entry point and stop the assembler.
