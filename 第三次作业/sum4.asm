.model small
.stack 100h

.data
prompt db 'Enter a number n(1-100): $'
result db 0Dh, 0Ah, 'The sum of 1+2+...+n is: $'
errorMsg db 0Dh, 0Ah, 'Input error! Please enter a number between 1-100.$'
newline db 0Dh, 0Ah, '$'

buffer db 6, ?, 6 dup('$')  ; Input buffer
num dw 0
sum dw 0

.code
main proc
    mov ax, @data
    mov ds, ax
    
    ; Display prompt
    mov ah, 09h
    lea dx, prompt
    int 21h
    
    ; Read user input
    mov ah, 0Ah
    lea dx, buffer
    int 21h
    
    ; Convert input string to number
    call string_to_number
    mov num, ax
    
    ; Validate input range (1-100)
    cmp ax, 1
    jl invalid_input
    cmp ax, 100
    jg invalid_input
    
    ; Calculate sum of 1+2+...+n
    call calculate_sum
    
    ; Display result
    mov ah, 09h
    lea dx, result
    int 21h
    
    ; Display sum
    mov ax, sum
    call display_number
    
    ; New line
    mov ah, 09h
    lea dx, newline
    int 21h
    
    jmp exit_program

invalid_input:
    mov ah, 09h
    lea dx, errorMsg
    int 21h

exit_program:
    mov ah, 4Ch
    int 21h
main endp

; Convert string to number
string_to_number proc
    push bx
    push cx
    push dx
    push si
    
    mov si, offset buffer + 2  ; Skip length bytes
    xor ax, ax
    xor cx, cx
    mov cl, buffer + 1         ; Actual character count
    
convert_loop:
    mov bl, [si]
    cmp bl, '0'
    jl convert_done
    cmp bl, '9'
    jg convert_done
    
    sub bl, '0'               ; Convert to digit
    mov dx, 10
    mul dx                    ; ax = ax * 10
    add ax, bx                ; Add current digit
    
    inc si
    loop convert_loop
    
convert_done:
    pop si
    pop dx
    pop cx
    pop bx
    ret
string_to_number endp

; Calculate sum from 1 to n
calculate_sum proc
    push ax
    push cx
    
    mov ax, 0
    mov cx, 1
    
sum_loop:
    add ax, cx
    inc cx
    cmp cx, num
    jle sum_loop
    
    mov sum, ax
    
    pop cx
    pop ax
    ret
calculate_sum endp

; Display number (0-65535)
display_number proc
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10
    xor cx, cx           ; Clear counter
    
divide_loop:
    xor dx, dx
    div bx               ; ax = ax/10, dx = remainder
    push dx              ; Save remainder
    inc cx
    test ax, ax
    jnz divide_loop
    
display_loop:
    pop dx               ; Get remainder
    add dl, '0'          ; Convert to ASCII
    mov ah, 02h          ; Display character
    int 21h
    loop display_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
display_number endp

end main