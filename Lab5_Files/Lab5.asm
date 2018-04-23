;line 258
.model small 
.stack 400h
.data
    DTASize equ 128
      
    2InWord dw 2
    deletingEndPosition dw 0000h
    deletingStartPosition dw 0000h
    lastWordSize dw 0000h
    buffSize equ 1025 ;do 1025
    buff db buffSize dup(?) ;? = null
    readDescriptor dw 0000h
    writeDescriptor dw 0000h
    deleteFirstWordFlag db 00h
    
    txtFileExtention db ".txt",0
    destinationFilePath db "dest.txt",0 
    sourceFilePath DTASize dup(?)    
    invalidArgumentsMessage db "Error! Enter source file name (.txt).$" 
    sourceFileOpeningError db "Error! Can't open source file.$"
    destinationFileCreatingError db "Error! Can't create destination file.$"
    unknownErrorMessage db "Unknown error.$"
    closeFileError db "Error on file closing.",0Dh,0Ah,'$'
    
.code
;al - mode, ds:dx - name string adress, cl - mask 
openExistingFile proc
    mov ah, 3Dh
    int 21h
ret
;cf - error and ax - error code. if cf = 0, ax - file descripror 
openExistingFile endp

;al - mode, ds:dx - name string adress, cl - mask 
createFile proc
    mov ah, 3Ch
    int 21h
ret
;cf - error and ax - error code. if cf = 0, ax - file descripror 
createFile endp  

;bx - file descriptor, cx - chunk size. ds:dx - buff adress
readData proc
    mov ah, 3Fh    ;read data
    int 21h
ret
;ax - byte read, otherwise cf - error and ax - error code
readData endp

movePointer proc
    mov ah, 42h
    int 21h    
ret
movePointer endp

writeData proc
    mov ah, 40h
    int 21h
ret
writeData endp

closeFile proc
    mov ah, 3Eh     ;Close file
    int 21h;
ret
closeFile endp

;IN/OUT PROCEDURES 
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

invalidArguments:
    lea dx, invalidArgumentsMessage
    call outputString
    jmp endProgram

unknownError:
    lea dx, unknownErrorMessage
    call outputString
    jmp endProgram    

start:
    mov ax, @data
    mov ds, ax
       
    mov di, 80h
    xor cx, cx   
    mov cl, es:di
    cmp cl, 0
    je invalidArguments       
    lea si, sourceFilePath
    inc di
sourceFilePathInput:
    inc di
    mov al, es:di
    cmp al, 0Dh
    je startProgram
    mov ds:si, al
    inc si
    jne sourceFilePathInput

startProgram:    
    mov ax, @data
    mov es, ax
     
    lea si, sourceFilePath
    lea di, txtFileExtention
pathValidationCycle:
    cmp [si], 0
    je invalidArguments
    cmpsb
    je compareExtention
    dec di
    jmp pathValidationCycle
compareExtention:
    cmp [si], 0
    je invalidArguments
    cmpsb
    jne validateNext    
    cmp [di], 0
    jne compareExtention
validateNext:
    lea di, txtFileExtention
    cmp [si], 0
    jne pathValidationCycle    
    
    mov al, 0 ;read-only
    lea dx, sourceFilePath
    xor cx,cx
    call openExistingFile
    jnc openWriteFile
    lea dx, sourceFileOpeningError
    call outputString
    jmp endProgram 
openWriteFile:
    mov readDescriptor, ax
    lea dx, destinationFilePath
    xor cx, cx
    call createFile
    jnc startDeleting
    lea dx, destinationFileCreatingError
    call outputString
    jmp endProgram
    
startDeleting:
    mov writeDescriptor, ax
deleteFileEvenWords:
    mov bx, readDescriptor
    mov cx, buffSize
    sub cx, lastWordSize ;if we had last word that was cut 
    dec cx               ;last symbol should be 0
    lea dx, buff
    add dx, lastWordSize
    call readData
    jc unknownError
    cmp ax, 0
    je endDeleting
    add dx, ax
    mov si, dx  
    mov [si], 0
    mov lastWordSize, 0000h    
    lea si, buff
    xor cx, cx
    cmp deleteFirstWordFlag, 00h
    je markWords

deleteFirstWord:
    cmp [si], 0Dh
    je firstWordEnd
    cmp [si], 0Ah
    je firstWordEnd
    cmp [si], 0
    je firstWordEnd
    cmp [si], ' '
    je firstWordEnd
    cmp [si], 09h
    je firstWordEnd    
    inc cx
    inc si
    jmp deleteFirstWord
firstWordEnd:
    cmp cx, 0
    je firstWordDeletingCycleEnd
    lea di, buff
firstWordDeletingCycle:
    mov al, [si]
    mov [di], al
    cmp al, 0            
    je firstWordDeletingCycleEnd
    inc si
    inc di
    jmp firstWordDeletingCycle
firstWordDeletingCycleEnd: 
    lea si, buff
    mov deleteFirstWordFlag, 00h  
    xor cx, cx
        
markWords:   
    cmp [si], 0Dh
    je skipSystemSymbols
    cmp [si], 0Ah
    je skipSystemSymbols
    cmp [si], 0
    je buffEnd
    cmp [si], ' '
    je skipSpaces
    cmp [si], 09h
    je skipSpaces
    push si  ;push word start adress
    inc cx     ;count push operation
    jmp skipWord

skipSystemSymbols:
    inc si
    jmp markWords
   
skipSpaces:
    inc si
    cmp [si], 0Dh     
    je lineEnd
    cmp [si], 0
    je buffEnd
    cmp [si], ' '
    je skipSpaces
    cmp [si], 09h
    je skipSpaces
    push si  ;push word start adress
    inc cx     ;count push operation
    je skipWord
     
skipWord:
    inc si
    cmp [si], 0Dh     ;CRET
    je lineEnd
    cmp [si], 0
    je buffEnd           
    cmp [si], ' '
    je wordEnd
    cmp [si], 09h
    je wordEnd
    jmp skipWord
wordEnd:
    push si  ;push word end adress
    inc cx   ;count push operation
    jmp skipSpaces    
    
buffEnd:
    cmp cx, 0
    je buffEndDeleting
    test cx, 1
    jz buffGetEvenWord
    mov ax, cx
    xor dx, dx
    div 2InWord
    test ax, 1
    jnz deleteLastWord
saveLastWord:
    pop di
    mov lastWordSize, si
    sub lastWordSize, di
    dec cx 
    cmp cx, 0
    je buffEndDeleting
    jmp buffEvenWord
deleteLastWord:
    mov deleteFirstWordFlag, 01h
    pop di
    mov al, [si]
    mov [di], al
    mov si, di
    dec cx
    jmp buffOddWord
buffGetEvenWord:
    mov ax, cx
    xor dx, dx
    div 2InWord  
    test ax, 1
    jz buffEvenWord
 
buffOddWord:    
    pop ax
    pop ax
    sub cx, 2
    cmp cx, 0
    je buffEndDeleting
      
buffEvenWord:
    pop di    
    pop si    
    sub cx, 2
buffDeleteWord: 
    mov al, [di]
    mov [si], al
    cmp al, 0
    je buffOddWord 
    inc si
    inc di
    jmp buffDeleteWord
buffEndDeleting:
    mov cx, si             ; cx - number of symbols in result string
    sub cx, offset buff      
    sub cx, lastWordSize
    mov bx, writeDescriptor
    lea dx, buff
    call writeData
    jc unknownError
    cmp lastWordSize, 0
    je deleteFileEvenWords
    lea di, buff
    sub si, lastWordSize
    mov cx, lastWordSize
lastWordToTheStartLoop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop lastWordToTheStartLoop
    jmp deleteFileEvenWords

     
lineEnd:
    mov deletingStartPosition, si
    cmp cx, 0
    je lineEndDeleting          
    test cx, 1  
    jz lineGetEvenWord      ;cx - even number
    push si
    inc cx
lineGetEvenWord:
    mov ax, cx
    xor dx, dx
    div 2InWord  
    test ax, 1
    jz lineEvenWord 
lineOddWord:    
    pop ax
    pop ax
    sub cx, 2
    cmp cx, 0
    je lineEndDeleting   
lineEvenWord:
    pop di    
    pop si    
    sub cx, 2
lineDeleteWord: 
    mov al, [di]
    mov [si], al
    cmp al, 0Ah
    je lineOddWord
    cmp al, 0
    je lineOddWord 
    inc si
    inc di
    jmp lineDeleteWord
lineEndDeleting:
    cmp [si], 0
    je buffEndDeleting
    cmp [si], 0Dh
    je repairPointer 
    mov deletingEndPosition, si
    mov di, deletingStartPosition    
    inc di
repairBuff:     
    inc si
    inc di
    mov al, [di]
    mov [si], al
    cmp al, 0
    jne repairBuff   
deleteNext:
    mov si, deletingEndPosition
    inc si
    jmp markWords

repairPointer:
    inc si
    cmp [si], 0
    je buffEndDeleting
    cmp [si], 0Ah
    je repairPointer
    jmp markWords

    
endDeleting:
    cmp lastWordSize, 0
    je closeDestinationFile
    mov cx, lastWordSize
    mov bx, writeDescriptor
    lea dx, buff
    call writeData
    jc unknownError    

closeDestinationFile:    
    mov bx, writeDescriptor
    call closeFile
    jc unknownError
    
closeSourceFile:
    mov bx, readDescriptor
    call closeFile
    jc unknownError

deleteSourceFile:
    lea dx, sourceFilePath
    mov ah, 41h
    int 21h
    jc unknownError
    
renameDestinationFile:
    lea dx, destinationFilePath
    lea di, sourceFilePath 
    mov ah, 56h
    int 21h
           
endProgram: 
    mov ax, 4c00h ; exit to operating system.
    int 21h    
ends

end start