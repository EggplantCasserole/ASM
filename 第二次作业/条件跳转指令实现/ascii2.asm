assume cs:codesg

codesg segment
    ;设置寄存器初值
    mov dl, 61H     ;从ASCII码为97的字符开始显示，即a
    mov cx, 0003H   ;设置外循环的次数3
    
    r:
        ; 检查是否超过 'z'
        cmp dl, 7AH
        ja end_program
        
        mov ah, 02H     ;设置显示方式
        push cx         ;保存外循环次数的计数
        mov cx, 000DH   ;设置内循环次数13
        
    c:
        ; 检查是否超过 'z'
        cmp dl, 7AH
        ja break_inner
        
        ; 显示字符
        int 21H
        
        ; 显示空格
        push dx
        mov dl, 20H
        int 21H
        pop dx
        
        ; 下一个字符
        inc dx
        
        ; 内循环控制（替代loop指令）
        dec cx
        jnz c          ; 如果cx≠0，继续内循环
        
    break_inner:
        ;已经进行完了一次内循环
        pop cx          ;恢复外循环次数的计数
        
        ; 检查是否已经显示到 'z'
        cmp dl, 7AH
        ja end_program
        
        ; 输出回车换行
        push dx
        mov ah, 02H
        mov dl, 0dH
        int 21H
        mov dl, 0aH
        int 21H
        pop dx
        
        ; 外循环控制（替代loop指令）
        dec cx
        jnz r          ; 如果cx≠0，继续外循环
        
    end_program:
    mov ax, 4c00H
    int 21H
codesg ends
end