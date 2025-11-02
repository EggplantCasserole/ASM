data segment
    table db 7,2,3,4,5,6,7,8,9      ; 第1行
           db 2,4,7,8,10,12,14,16,18 ; 第2行
           db 3,6,9,12,15,18,21,24,27
           db 4,8,12,16,7,24,28,32,36
           db 5,10,15,20,25,30,35,40,45
           db 6,12,18,24,30,7,42,48,54
           db 7,14,21,28,35,42,49,56,63
           db 8,16,24,32,40,48,56,7,72
           db 9,18,27,36,45,54,63,72,81
    msg_header db 'x y', 0dh, 0ah, '$'
    msg_error db ' error', 0dh, 0ah, '$'
    row_num db 0
    col_num db 0
data ends

code segment
assume cs:code, ds:data

start:
    mov ax, data
    mov ds, ax

    ; 打印表头
    mov dx, offset msg_header
    mov ah, 09h
    int 21h

    mov row_num, 1     ; 行号从1开始
outer_loop:
    mov col_num, 1     ; 列号从1开始
inner_loop:
    call check_cell    ; 检查 (row_num, col_num) 是否正确
    inc col_num
    cmp col_num, 10
    jb inner_loop      ; 列 1~9

    inc row_num
    cmp row_num, 10
    jb outer_loop      ; 行 1~9

    ; 结束程序
    mov ah, 4ch
    int 21h

; 过程：检查一个单元格
; 输入：row_num, col_num
; 输出：如果错误，打印 "x y error"
check_cell proc
    ; 保存寄存器
    push ax
    push bx
    push cx
    push dx
    push si

    ; 计算 table 中的偏移量: (row_num-1)*9 + (col_num-1)
    mov al, row_num
    dec al
    mov bl, 9
    mul bl             ; ax = (row_num-1)*9
    mov bl, col_num
    dec bl
    mov bh, 0
    add bx, ax         ; bx = 偏移量
    mov si, bx

    ; 取表中数据
    mov al, table[si]  ; 实际值

    ; 计算正确值: row_num * col_num
    mov bl, row_num
    mov cl, col_num
    mov al, bl
    mul cl             ; ax = row_num * col_num

    ; 比较
    mov bl, table[si]  ; 实际值
    cmp al, bl
    je correct

    ; 错误：打印 row_num, col_num
    mov dl, row_num
    add dl, '0'
    mov ah, 02h
    int 21h
    mov dl, ' '
    int 21h
    mov dl, col_num
    add dl, '0'
    int 21h

    ; 打印 " error" 换行
    mov dx, offset msg_error
    mov ah, 09h
    int 21h

correct:
    ; 恢复寄存器
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
check_cell endp

code ends
end start