.model small
.stack 100h

.data
    msg db "Sum (stored in register): $"
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
    
    ; 此时AX寄存器中存储结果5050
    ; 直接使用AX寄存器中的值进行打印
    call print_number
    
    ; 显示换行
    mov ah, 09h
    lea dx, newline
    int 21h
    
    ; 退出程序
    mov ah, 4Ch
    int 21h
main endp

; 数字打印子程序 - 将AX中的数字转换为字符串并显示
print_number proc
    push bx
    push cx
    push dx
    
    mov bx, 10          ; 除数10
    mov cx, 0           ; 数字位数计数器
    
    ; 将数字转换为字符串（反向压栈）
convert_loop:
    xor dx, dx          ; 清零DX，为除法做准备
    div bx              ; DX:AX ÷ 10，商在AX，余数在DX
    add dl, '0'         ; 数字转ASCII
    push dx             ; 将字符压栈
    inc cx              ; 位数计数加1
    test ax, ax         ; 检查商是否为0
    jnz convert_loop    ; 如果不为0，继续转换
    
    ; 从栈中弹出字符并显示
display_loop:
    pop dx
    mov ah, 02h         ; 显示字符功能
    int 21h
    loop display_loop
    
    pop dx
    pop cx
    pop bx
    ret
print_number endp

end main