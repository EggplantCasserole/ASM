assume cs:codesg

codesg segment
    ;设置寄存器初值
    mov dx, 0000H
    mov dl, 61H     ;从ASCII码为97的字符开始显示，即a
    mov cx, 0003H   ;设置外循环的次数3（26/13=2，但为了保险设3）
    mov ax, 0000H
    
    r:
        ; 检查是否超过 'z'
        cmp dl, 7AH     ; 'z' 的ASCII码是 7AH
        ja end_program  ; 如果超过 'z'，结束程序
        
        mov ah, 02H     ;设置显示方式
        push cx         ;保存外循环次数的计数
        mov cx, 000DH   ;设置内循环次数13，即一行13个字符
        
    c:
        ; 检查是否超过 'z'
        cmp dl, 7AH
        ja break_inner  ; 如果超过 'z'，跳出内循环
        
        int 21H         ;显示ASCII值为[dl]的字符
        push dx         ;保存dx的值
        mov dl, 20H     ;输出空格（正确的ASCII码）
        int 21H
        pop dx          ;恢复dx的值
        inc dx          ;产生下一个ASCII字符
        
        loop c
        
    break_inner:
        ;已经进行完了一次内循环
        pop cx          ;恢复外循环次数的计数
        
        ; 检查是否已经显示到 'z'
        cmp dl, 7AH
        ja end_program
        
        ; 输出回车换行
        push dx
        mov ah, 02H
        mov dl, 0dH     ;回车
        int 21H
        mov dl, 0aH     ;换行
        int 21H
        pop dx
        
        loop r
        
    end_program:
    mov ax, 4c00H
    int 21H
codesg ends
end