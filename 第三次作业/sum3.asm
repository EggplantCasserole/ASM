.model small
.stack 100h

.data
    msg db "Sum (stored in stack): $"
    newline db 0Dh, 0Ah, '$'

.code
main proc
    mov ax, @data
    mov ds, ax
    
    ; 显示提示信息
    mov ah, 09h
    lea dx, msg
    int 21h
    
    ; 计算1+2+...+100
    mov ax, 0           ; 累加器清零
    mov cx, 1           ; 计数器从1开始

sum_loop:
    add ax, cx          ; 累加：AX = AX + CX
    inc cx              ; 计数器加1
    cmp cx, 100         ; 比较CX和100
    jle sum_loop        ; 如果CX <= 100，继续循环
    
    ; 将结果压入栈中
    push ax
    
    ; 从栈中弹出结果并打印
    pop ax
    call print_number
    
    ; 显示换行
    mov ah, 09h
    lea dx, newline
    int 21h
    
    ; 退出程序
    mov ah, 4Ch
    int 21h
main endp

; 数字打印子程序
print_number proc
    push bx
    push cx
    push dx
    
    mov bx, 10
    mov cx, 0
    
convert_loop:
    xor dx, dx
    div bx
    add dl, '0'
    push dx
    inc cx
    test ax, ax
    jnz convert_loop
    
display_loop:
    pop dx
    mov ah, 02h
    int 21h
    loop display_loop
    
    pop dx
    pop cx
    pop bx
    ret
print_number endp

end main