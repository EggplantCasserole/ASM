.model small
.stack 100h

.data
    prompt db 'The 9mu19 table:', 0Dh, 0Ah, '$'
    newline db 0Dh, 0Ah, '$'
    buffer db 10 dup('$')

.code
main proc
    mov ax, @data
    mov ds, ax
    
    ; 输出标题
    mov dx, offset prompt
    mov ah, 09h
    int 21h
    
    ; 外层循环：被乘数从9到1
    mov bl, 9                   ; BL = 被乘数
    
outer_loop:
    cmp bl, 0
    jle end_program             ; 如果被乘数 <= 0，结束程序
    
    ; 内层循环：乘数从1到当前被乘数
    mov bh, 1                   ; BH = 乘数
    
inner_loop:
    cmp bh, bl
    jg next_outer               ; 如果乘数 > 被乘数，进入下一个被乘数
    
    ; 调用过程输出乘法表达式
    call print_multiplication
    
    inc bh                      ; 乘数加1
    jmp inner_loop
    
next_outer:
    ; 输出换行
    mov dx, offset newline
    mov ah, 09h
    int 21h
    
    dec bl                      ; 被乘数减1
    jmp outer_loop

end_program:
    mov ax, 4C00h
    int 21h
main endp

; 过程：输出乘法表达式
; 输入：BL = 被乘数，BH = 乘数
print_multiplication proc
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; 输出被乘数
    mov dl, bl
    add dl, '0'
    mov ah, 02h
    int 21h
    
    ; 输出 'x'
    mov dl, 'x'
    int 21h
    
    ; 输出乘数
    mov dl, bh
    add dl, '0'
    int 21h
    
    ; 输出 '='
    mov dl, '='
    int 21h
    
    ; 计算乘积
    mov al, bl                  ; AL = 被乘数
    mul bh                      ; AX = AL * BH (乘积)
    
    ; 调用过程输出数字
    call print_number
    
    ; 输出制表符（用于对齐）
    mov dl, 09h                 ; 制表符ASCII码
    mov ah, 02h
    int 21h
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_multiplication endp

; 过程：输出数字（处理1位或2位数）
; 输入：AX = 要输出的数字
print_number proc
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 0                   ; CX 用作计数器（数字位数）
    mov bx, 10                  ; BX = 10（除数）
    
convert_loop:
    mov dx, 0                   ; 清零DX（被除数高位）
    div bx                      ; AX / 10，商在AX，余数在DX
    push dx                     ; 保存余数（数字位）
    inc cx                      ; 数字位数加1
    
    cmp ax, 0
    jne convert_loop            ; 如果商不为0，继续循环
    
output_loop:
    pop dx                      ; 取出数字位
    add dl, '0'                 ; 转换为ASCII字符
    mov ah, 02h                 ; 输出字符
    int 21h
    loop output_loop            ; 循环输出所有数字位
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number endp

end main