.model small
.stack 100h

.data
SEGMENT1C DW 0
OFF1C DW 0
BOARD DW 24 DUP(?),0FFFFH
Y DB ?          ; 当前行
TY DB ?         ; 暂存行
XR DB ?
XL DB ?
NOW DB ?
DIRE DB ?
NXT DB ?
TIM DB 0
SPEED DB 0
CON DB 0
DV DB 0
FLG DB 0

; 方块数据 - 压缩为字节形式
PAD DB 7*4*4 DUP(?)  ; 7种方块 * 4个方向 * 4行 = 112字节

P1 DW 4 DUP(?)
P2 DW 4 DUP(?)
SHIFT_CNT DB 6         ; 初始移位计数 (Center in 16-bit: 111 0000000000 111. Middle is bit 8. Block is 4 wide. So shift 6?)
COLOR DB 00001001b,00001010b,00001011b,00001100b,00001101b,00001110b,00000001b
NCOLOR DB ?
SCORE DB 5 DUP('0'),'$'
PADMSG DB 25 DUP(219)
TMPMSG DB 25 DUP(?)
STARTMSG1 DB 0DH,0AH,'Select speed.',0DH,0AH,'$'
STARTMSG2 DB 20H,20H,'1. Fast',0DH,0AH,'$'
STARTMSG3 DB 20H,20H,'2. Middle',0DH,0AH,'$'
STARTMSG4 DB 20H,20H,'3. Slow',0DH,0AH,'$'
STARTMSG5 DB 20H,20H,'0. Exit',0DH,0AH,'$'
ENDMSG DB 0DH,0AH,'Good Bye!',0DH,0AH,'$'
SCOREMSG1 DB 201,19 dup(205),187
SCOREMSG2 DB 186,' Score: ',32
SCOREMSG3 DB 32,9 dup(32),186
SCOREMSG4 DB 186,19 dup(32),186
SCOREMSG5 DB 186,19 dup(32),186
SCOREMSG6 DB 186,19 dup(32),186
SCOREMSG7 DB 186,19 dup(32),186,186,19 dup(32),186
SCOREMSG8 DB 204,19 dup(205),185
SCOREMSG9  DB 186,4 dup(32),' Left  : A  ',3 dup(32),186
SCOREMSG10 DB 186,4 dup(32),' Right : D  ',3 dup(32),186
SCOREMSG11 DB 186,4 dup(32),' Rotate: W  ',3 dup(32),186
SCOREMSG12 DB 186,4 dup(32),' Down  : S  ',3 dup(32),186
SCOREMSG13 DB 186,'-------------------',186
SCOREMSG14 DB 186,3 dup(32),' Exit  : Esc ',3 dup(32),186
SCOREMSG15 DB 200,19 dup(205),188
GAMEOVER_STR DB 'GAME OVER'
EXIT_STR DB 'Press ESC to Exit'

.code
START:
    mov ax, @data
    mov ds, ax
    mov es, ax
    
    ; 初始化方块数据
    call INIT_PAD_DATA
    
    PUSH DS                    ; 保存DS的值        
    MOV AL,1CH                 ; 设置AL = 中断号
    MOV AH,35H                 ; ES:BX为入口
    INT 21H
    MOV SEGMENT1C,ES           ; 将ES的值给1C中断段
    MOV OFF1C,BX               ; 设置关中断的地址
    MOV DX,OFFSET INT1C        ; 调用子函数INT1C取偏移地址
    PUSH DS                    ; <--- 新增，保存当前DS
    MOV AX,SEG INT1C           ; SEG标号段地址
    MOV DS,AX
    MOV AL,1CH
    MOV AH,25H                 ; 设置新的中断向量，DS:DX为入口
    INT 21H
    POP DS    
    
GAMEOVER:
    MOV AH,00H                 ; 设置显示模式3（80*25*16色）
    MOV AL,03H                        
    INT 10H
    
SELECTSPEED:
    MOV AH,09H                 ; 显示字符串
    MOV DX,OFFSET STARTMSG1    ; Select speed.
    INT 21H
    MOV DX,OFFSET STARTMSG2    ; 1. Fast
    INT 21H
    MOV DX,OFFSET STARTMSG3    ; 2. Middle
    INT 21H
    MOV DX,OFFSET STARTMSG4    ; 3. Slow    
    INT 21H
    MOV DX,OFFSET STARTMSG5    ; 0. Exit
    INT 21H
    MOV AH,08H                 ; 输入一个字符                    
    INT 21H
    SUB AL,'0'                        
    MOV CL,AL                        
    AND AL,3
    CMP AL,CL
    JNE SELECTSPEED            ; 如果不是0-3继续输入
    INC AL
    INC CL
    MUL CL
    CMP CL,1H                  ; 如果是0则结束
    JZ EXIT
    MOV SPEED,AL               ; 设置速度
    MOV AH,00H
    MOV AL,12H
    INT 10H                    ; 设置显示模式（640*480*16色）
    MOV AH,0BH                 ; 设置调色板、背景色或边框
    MOV BH,01                  ; 选择调色板
    MOV BL,00H                 ; 选择调色板0（RGB）
    INT 10H                    ; 开始游戏
    CALL INITGAME
    CALL BEGIN
    CALL DELAY
    MOV TIM,0H                        
    
LOOP1:
    STI                        ; 开中断
    MOV AL,TIM
    CMP AL,SPEED
    JG TIME
    MOV AH,1
    INT 16H                    ; 读键盘
    JZ LOOP1
    MOV AH,0
    INT 16H                    ; 读键盘
    CMP AL,1BH                 ; 如果是Esc键则退出
    JZ EXIT
    CMP AL,'a'                 ; 按键a跳转
    JZ KA
    CMP AL,'w'                 ; 按键w跳转
    JZ KW
    CMP AL,'d'                 ; 按键d跳转
    JZ KD
    CMP AL,'s'                 ; 按键s跳转
    JNZ TIME
    
KS:
    CALL DELAY                 ; 如果是s键则一直下落
    CALL DOWN
    CMP CON,1                  ; 如果还能下落则继续下落
    JNE KS                            
    CALL BEGIN                        
    JMP LOOP1                        
    
KA:
    CALL LEFT                  ; 调用向左移动
    JMP LOOP1
    
KW:
    CALL ROTATE                ; 调用换向
    JMP LOOP1
    
KD:
    CALL RIGHT                 ; 调用向右移动
    JMP LOOP1
    
TIME:
    MOV TIM,0H
    CALL DOWN                  ; 自然下落
    CMP CON,0                  ;
    JE LOOP1
    CALL BEGIN
    JMP LOOP1
    
EXIT:                                         
    MOV AX,0003H               ; 设置显示模式（80*25*16色）
    INT 10H
    MOV AX,@data
    MOV DS,AX
    MOV DX,OFFSET ENDMSG            
    MOV AH,09H                 ; 显示字符串
    INT 21H                            
    MOV DX,OFF1C                    
    MOV AX,SEGMENT1C                
    MOV DS,AX
    MOV AL,1CH
    MOV AH,25H                        
    INT 21H
    MOV AX,4C00H                    
    INT 21H                    ; 返回dos

; 初始化方块数据过程
INIT_PAD_DATA PROC NEAR
    PUSH SI
    PUSH DI
    PUSH CX
    PUSH AX
    PUSH BX
    
    MOV DI, OFFSET PAD
    
    ; 方块1 - I型
    ; Rotation 0 (Horizontal)
    MOV AL, 00001111b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    ; Rotation 1 (Vertical)
    MOV AL, 00100000b
    STOSB
    MOV AL, 00100000b
    STOSB
    MOV AL, 00100000b
    STOSB
    MOV AL, 00100000b
    STOSB
    
    ; Rotation 2 (Horizontal)
    MOV AL, 00001111b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    ; Rotation 3 (Vertical)
    MOV AL, 00100000b
    STOSB
    MOV AL, 00100000b
    STOSB
    MOV AL, 00100000b
    STOSB
    MOV AL, 00100000b
    STOSB
    
    ; 方块2 - O型
    MOV AL, 00000011b
    STOSB
    MOV AL, 00000011b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    ; 其他三个方向（O型四个方向都一样）
    MOV CX, 3*4
    REP STOSB
    
    ; 方块3 - T型
    MOV AL, 00000111b
    STOSB
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000011b
    STOSB
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000111b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000110b
    STOSB
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    ; 方块4 - L型
    MOV AL, 00000111b
    STOSB
    MOV AL, 00000001b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000011b
    STOSB
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000100b
    STOSB
    MOV AL, 00000111b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000110b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    ; 方块5 - J型
    MOV AL, 00000111b
    STOSB
    MOV AL, 00000100b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000011b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000001b
    STOSB
    MOV AL, 00000111b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000110b
    STOSB
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    ; 方块6 - S型
    MOV AL, 00000110b
    STOSB
    MOV AL, 00000011b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000110b
    STOSB
    MOV AL, 00000100b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000110b
    STOSB
    MOV AL, 00000011b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000110b
    STOSB
    MOV AL, 00000100b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    ; 方块7 - Z型
    MOV AL, 00000011b
    STOSB
    MOV AL, 00000110b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000100b
    STOSB
    MOV AL, 00000110b
    STOSB
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000011b
    STOSB
    MOV AL, 00000110b
    STOSB
    MOV AL, 00000000b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    MOV AL, 00000100b
    STOSB
    MOV AL, 00000110b
    STOSB
    MOV AL, 00000010b
    STOSB
    MOV AL, 00000000b
    STOSB
    
    POP BX
    POP AX
    POP CX
    POP DI
    POP SI
    RET
INIT_PAD_DATA ENDP

INT1C PROC
    PUSH AX
    PUSH DS
    MOV AX, @data
    MOV DS, AX
    INC TIM
    POP DS
    POP AX
    IRET
INT1C ENDP

DELAY PROC NEAR                ; 等待
    PUSH CX
    MOV CX,00FFH
LOOP20:
    LOOP LOOP20
    POP CX
    RET
DELAY ENDP

ROTATE PROC NEAR
    MOV AL, Y                  ; 同步当前行号到TY，确保CHECK检测位置正确
    MOV TY, AL
    MOV SI,OFFSET PAD          ; 取方块地址
    MOV AL,NOW                 ; 取方块类型
    MOV AH,0H                        
    MOV CL,16                  ; 左移4位（4字节/方块）
    MUL CL
    ADD SI,AX                  ; 把类型号给si
    MOV AL,DIRE                ; 取方向
    INC AL
    AND AL,03H
    MOV AH,0H                        
    MOV CL,4                   ; 左移2位（4字节/方向）
    MUL CL
    ADD SI,AX                  ; 把方向给si
    MOV DI,OFFSET P2           ; 将P2的地址给DI
    MOV CX,04H                        
    CLD
LOOP12:
    PUSH CX
    LODSB                      ; 将SI的内容加载到AL（字节）
    MOV AH,0                   ; 清空AH
    MOV CL,SHIFT_CNT           ; 获取当前移位计数
    SHL AX,CL                  ; 左移AX
    STOSW                      ; 把AX中的内容复制到di所指内存 (Word)
    POP CX
    LOOP LOOP12
    CALL CHECK
    CMP AL,0H
    JNE SKIP10
    MOV BX,0000H                        
    CALL DISPPAD               ; 清空原来的方块
    CALL COPY21
    INC DIRE
    AND DIRE,3H
    MOV BH,00H
    MOV BL,NCOLOR    
    CALL DISPPAD               ; 画新的方块
SKIP10:
    RET
ROTATE ENDP

RIGHT PROC NEAR
    CALL COPY12
    MOV SI,OFFSET P2
    MOV CX,04H
LOOP7:
    MOV AX,[SI]
    SHR AX,1
    MOV [SI],AX
    ADD SI,2
    LOOP LOOP7
    CALL CHECK
    CMP AL,0H
    JNE SKIP6
    MOV BX,0000H
    CALL DISPPAD
    CALL COPY21
    DEC SHIFT_CNT
    MOV BH,00H
    MOV BL,NCOLOR
    CALL DISPPAD
SKIP6:
    RET
RIGHT ENDP

LEFT PROC NEAR
    CALL COPY12
    MOV SI,OFFSET P2
    MOV CX,04H
LOOP10:
    MOV AX,[SI]
    SHL AX,1
    MOV [SI],AX
    ADD SI,2
    LOOP LOOP10
    CALL CHECK
    CMP AL,0H
    JNE SKIP8
    MOV BX,0000H
    CALL DISPPAD
    CALL COPY21
    INC SHIFT_CNT
    MOV BH,00H
    MOV BL,NCOLOR
    CALL DISPPAD
SKIP8:
    RET
LEFT ENDP

DOWN PROC NEAR
    CALL COPY12
    INC TY
    CALL CHECK
    CMP AL,0H
    JNE SKIP5
    MOV BX,0000H
    CALL DISPPAD
    CALL COPY21
    MOV BH,00H
    MOV BL,NCOLOR
    CALL DISPPAD
    MOV CON,00H
    RET
SKIP5:
    CALL PUT
    MOV CON,01H
    RET
DOWN ENDP

PUT PROC NEAR                  ; 消除整行
    MOV BH,0H
    MOV BL,0h
    CALL DISPPAD               ; 清除原有方块
    MOV BH,0H
    MOV BL,NCOLOR              ; 设置颜色
    CALL DISPPAD               ; 显示新方块
    MOV DV,01H                        
    MOV AH,0H
    MOV AL,Y
    ADD AL,Y
    MOV SI,OFFSET BOARD
    ADD SI,AX
    MOV DI,00H
    MOV CX,04H
    CLD                        ; si自增
LOOP15:
    LODSW                      ; 将si所指内容加载到ax
    MOV BX,P1[DI]              ; 获取P1字数据
    OR AX,BX                   ; 合并                   
    MOV [SI-2],AX
    INC DI
    INC DI
    LOOP LOOP15                ; 将P1中的内容整合到游戏区
    MOV SI,OFFSET BOARD        ; 进入整行消除
    ADD SI,23*2                ; 从最后一行开始
    MOV DI,SI
    MOV CX,20                  ; 循环次数
    MOV BH,00H                 ; 0页
    MOV FLG,00H                ; 标志清零
    STD                        ; SI自减
LOOP13:
    LODSW                      ; 将si的内容加载到ax
    CMP AX,0FFFFH              ;
    JNE SKIP12                 ; 不是整行跳转
    MOV FLG,0FFH
    MOV AL,DV
    SAL AL,1
    MOV DV,AL                  ; 得分加
    JMP LOOP13
SKIP12:
    STOSW                      ; 将ax的内容写回di所指区域（即消除整行，非整行下落）
    CMP FLG,0H
    JE SKIP70                  ; 如果没有消除则跳转
    PUSH CX                            
    MOV DH,CL                        
    ADD DH,03H                 ;
    MOV DL,0AH                 ; 行列属性
    MOV BX,0000H               ; 颜色属性
    MOV BP,OFFSET PADMSG
    MOV CX,20
    PUSH AX
    MOV AX,1300H                    
    INT 10H                    ; 将bp所指内容在指定行列输出，循环20次（清空消除整行）
    POP AX
    MOV CL,03H                        
    SHL AX,CL                  ; 清除前导3个1
    MOV CX,0AH                 ; 游戏区10个格
    MOV DL,08H                 ; 列号
LOOP14:
    INC DL
    INC DL
    MOV BL,0H
    SHL AX,1
    JNC SKIP11                 ; 无进位跳转
    MOV BL,01011001b           ; 落定块以特定颜色显示
SKIP11:
    CALL DISPCELL
    LOOP LOOP14                ; 循环清除所有整行行
    POP CX                            
SKIP70:
    LOOP LOOP13
    MOV AL,DV
    SAR AL,1
    ADD SCORE[3],AL            ; 一个方块下落完成后总得分
    MOV CX,05H
    MOV SI,04H
LOOP16:
    CMP SCORE[SI],'9'          ; 得分转换
    JNG SKIP13
    INC SCORE[SI-1]
    SUB SCORE[SI],0AH
SKIP13:
    DEC SI
    LOOP LOOP16
    RET
PUT ENDP

DISPSCORE PROC NEAR            ; 显示分数
    MOV AX,@data                    
    MOV ES,AX                    
    MOV BP,OFFSET SCORE        ; 将Score的地址给BP    
    MOV CX,05H                 ; 字符串长度
    MOV DX,0635H               ; 起始位置
    MOV BH,0H                  ; 页码
    MOV AL,0H                  ; 逐个字符输出，光标返回起始位置
    MOV BL,00110100B           ; 字符属性
    MOV AH,13H
    INT 10H                    ; 输出
    RET
DISPSCORE ENDP

DISPNEXT PROC NEAR             ; 显示下一个方块
    MOV AX,@data
    MOV ES,AX
    MOV BP,OFFSET TMPMSG       ; 将TMPMSG的地址给BP
    MOV DI,BP                  ; 将TMPMSG的地址给DI
    MOV SI,OFFSET PAD          ; 将PAD的地址给SI
    MOV AL,NXT                 ; 将方块数传给AL
    MOV AH,0                    
    MOV BL,16                  ; 每个方块16字节（4方向×4行）
    MUL BL
    ADD SI,AX                  ; si指向当前方块数据
    CLD                        ; 从前往后读取
    MOV CX,04H                 ; 4行
LOOP8:
    PUSH CX                    ; 保存CX的值
    LODSB                      ; 从si中取一个字节到AL
    MOV AH,AL                  ; 复制到AH
    MOV CL,06H
    SHL AX,CL                  ; 左移6位清空前导0
    MOV CX,04H                 ; 最多一行4个1
LOOP9:
    MOV BL,20H                 ; 传BL空格的ASCII码
    SHL AX,1                   ; 逻辑左移一位，高位进CF位
    JNC SKIP2                  ; 如果CF不是1则跳转
    MOV BL,219                 ; 如果CF是1则将BL的值变为方块的ASCII
SKIP2:
    MOV [DI],BL                ; 将BL的值传给TMPMSG
    INC DI                     ; 自增
    MOV [DI],BL                    
    INC DI
    LOOP LOOP9                 ; 循环画出所有的是1的位置
    MOV DX,0C30H               ; 起始位置
    POP CX                     ; 还原cx的值
    SUB DH,CL                  ; 行号减
    PUSH CX                    ; 保存cx的值
    MOV CX,08H                 ; 字符串长度
    MOV BH,0H                  ; 页号
    PUSH SI                    ; 保存si的值
    MOV AH,0H                    
    MOV AL,NXT                 ; 置ax的值位NXT
    MOV SI,AX                  
    MOV BL,COLOR[SI]           ; 设置颜色属性
    POP SI
    MOV AX,1300H               ; 显示字符串
    INT 10H
    POP CX                     ; 还原cx的值
    MOV DI,BP                  ; 把BP的值给DI
    LOOP LOOP8                 ; 循环画出整个方块
    RET
DISPNEXT ENDP

COPY21 PROC NEAR
    CLD                        ; 从前往后处理字符串
    MOV SI,OFFSET P2
    MOV DI,OFFSET P1
    MOV CX,04                  ; 4字
    REP MOVSW                  ; 复制P2串到P1串
    MOV CL,TY
    MOV Y,CL
    RET
COPY21 ENDP

COPY12 PROC NEAR
    CLD
    MOV SI,OFFSET P1
    MOV DI,OFFSET P2
    MOV CX,04                  ; 4字
    REP MOVSW
    MOV CL,Y
    MOV TY,CL
    RET
COPY12 ENDP

BEGIN PROC NEAR
    MOV AL,NXT
    MOV NOW,AL
    CALL RANDOM                ; 构建随机方块
    CALL DISPSCORE             ; 显示分数
    CALL DISPNEXT              ; 构建下一个方块
    MOV DIRE,0                 ; 置初始方向为0
    MOV Y,4                    ; 设初值
    MOV TY,4                    
    MOV SHIFT_CNT, 6           ; 初始移位计数 (Center)
    MOV AH,0
    MOV AL,NOW                 ; 将ax设置为NOW
    MOV SI,AX                  ; 将AX的值传给SI
    MOV CL,COLOR[SI]           ; 将颜色属性值传给cl
    MOV NCOLOR,CL              ; 用NCOLOR保存颜色属性
    MOV DI,OFFSET P2           ; 将P2的地址给DI
    MOV SI,OFFSET PAD          ; 将PAD的地址给SI
    MOV BL,16                  
    MUL BL                     ; 左移4位（16字节/方块）
    ADD SI,AX                  ;
    MOV CX,04                  ; 4行
    CLD
INIT_P2_LOOP:
    LODSB                      ; Load Byte
    MOV AH, 0
    PUSH CX
    MOV CL, SHIFT_CNT
    SHL AX, CL                 ; Shift to position
    POP CX
    STOSW                      ; Store Word
    LOOP INIT_P2_LOOP

    CALL COPY21                    
    MOV BH,0H                  ; 0页
    MOV BL,NCOLOR              ; 颜色属性
    CALL DISPPAD
    CALL CHECK
    CMP AL,0
    JE SKIP1
    JMP GAME_OVER_SEQ
SKIP1:
    CALL DELAY
    MOV TIM,0H
    RET

GAME_OVER_SEQ:
    MOV DL,07H
    MOV AH,02H
    INT 21H                ; Beep
    
    MOV AX,@data
    MOV ES,AX
    MOV BP,OFFSET GAMEOVER_STR
    MOV CX,9
    MOV DX,0C23H           ; Row 12, Col 35
    MOV BH,0
    MOV BL,04H             ; Red
    MOV AL,0
    MOV AH,13H
    INT 10H
    
    MOV BP,OFFSET EXIT_STR
    MOV CX,17
    MOV DX,0E1FH           ; Row 14, Col 31
    MOV BL,0EH             ; Yellow
    MOV AH,13H
    INT 10H
    
WAIT_FOR_ESC:
    MOV AH,0
    INT 16H
    CMP AL,1BH
    JNE WAIT_FOR_ESC
    JMP EXIT

BEGIN ENDP

CHECK PROC NEAR                ; 返回AL=0或F 0为OK F为NO
    MOV AH,0H
    MOV AL,TY
    ADD AL,TY
    MOV SI,OFFSET BOARD        ; 把当前的游戏情况加载到SI
    ADD SI,AX                  ;
    MOV DI,00H
    MOV CX,04H
    CLD
LOOP6:
    LODSW                      ; 将SI中的内容加载到AX
    MOV BX,P2[DI]              ; 获取P2字
    AND AX,BX                  ;
    JNZ SKIP4
    INC DI
    INC DI
    LOOP LOOP6                 ; 循环判断
    MOV AL,00H
    RET
SKIP4:
    MOV AL,0FH
    RET
CHECK ENDP

DISPPAD PROC NEAR                     
    MOV SI,OFFSET P1           ; 将P1的地址给SI
    MOV CX,04H                 ; 循环次数
    MOV DL,08H
    MOV DH,Y
    ADD DH,04H                 ; 设置行列
    PUSH DX
    CLD                        ; 从前往后
LOOP2:
    LODSW                      ; 将si中的内容加载到AX (Word)
    PUSH CX
    MOV CL,3
    SHL AX,CL                  ; 跳过左墙3位
    POP CX
    POP DX
    PUSH DX
    SUB DH,CL                  ; 起始行改变
    PUSH CX                        
    MOV CX,0AH                 ; 循环次数（10位）
LOOP3:
    INC DL                        
    INC DL                     ; 列数加
    SHL AX,1                   ; 左移一位
    JNC SKIP3                  ; 没有进位则跳转
    CALL DISPCELL              ; 有进位则显示方块
SKIP3:
    LOOP LOOP3                    
    POP CX
    LOOP LOOP2                 ; 画出整个方块
    POP DX
    RET
DISPPAD ENDP

DISPCELL PROC NEAR             ; DH=ROW DL=COL BH=PAGE BL=COLOR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH SI                    ; 保存寄存器
    MOV BP,OFFSET PADMSG       ; 将PADMSG的地址传给BP
    MOV CX,02H                 ;
    MOV AX,1300H               ; 将BP所指地址的内容显示出来
    INT 10H                    ; 将原方块位置处的方块涂成背景色
    CMP BL,0H                  ;
    JE SKIP20                  ; 如果是清完原来的方块跳转
    MOV AH,0H                    
    MOV AL,DH                  ; 行号传AL
    MOV CL,16
    MUL CL                     ; 左移4位
    MOV SI,AX                  
    MOV AH,0H                    
    MOV AL,DL                  ; 列号传AL
    MOV CL,8                   ; 左移3位
    MUL CL
    MOV DI,AX                  ;
    MOV AX,0C00H               ; AH = 0CH，表示显示一点
    MOV DX,SI                  ; DX存Y坐标
    ADD DX,15                  
    MOV CX,16                  ; CX存X坐标
LOOP21:
    ADD CX,DI
    DEC CX
    INT 10H
    INC CX
    SUB CX,DI
    LOOP LOOP21                ; 循环显示一小行亮点（美化作用）
    MOV DX,SI
    MOV CX,15
    ADD DI,15
LOOP22:
    PUSH CX
    MOV CX,DI
    INT 10H
    INC DX
    POP CX
    LOOP LOOP22
    SUB DI,2
    DEC DX
    MOV CX,13
LOOP23:
    PUSH CX
    DEC DX
    MOV CX,DI
    INT 10H
    SUB CX,12
    MOV AL,07H
    INT 10H
    MOV AL,00H
    POP CX
    LOOP LOOP23
    MOV AX,0C07H
    MOV DX,SI
    ADD DX,1
    MOV CX,12
    SUB DI,12
LOOP24:
    ADD CX,DI
    INT 10H
    SUB CX,DI
    LOOP LOOP24                ; 上述的函数的作用在于输出一行行亮斑行，将被显示的方块包裹起来
SKIP20:
    POP SI
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX                     ; 还原寄存器的值
    RET
DISPCELL ENDP

CLS PROC NEAR                  ; 清屏函数
    MOV CX,0                   ; CH = 左上角行号，CL = 左上角列号
    MOV DH,24                  ; DH = 右下角行号
    MOV DL,79                  ; DL = 右下角列号
    MOV BH,0                   ; BH = 卷入行属性
    MOV AX,600H                ; 初始化屏幕,AL = 0全屏幕为空白
    INT 10H
    RET
CLS ENDP

RANDOM PROC NEAR
LOOP5:
    IN AX,40H                  ; 开始随机选择方块类型,al=时间随机值
    INC AL
    AND AL,07H                
    CMP AL,07H
    JE LOOP5                   ; 选择0-6之间的数字
    MOV NXT,AL                 ; 将AL的值传给NXT
    RET
RANDOM ENDP

INITGAME PROC NEAR
    CALL CLS                   ; 初始化屏幕
    MOV AX,@data
    MOV ES,AX
    MOV CX,15                  ; 左上角行 = 00h，左上角列 = 15h
    MOV BP,OFFSET SCOREMSG1    ; 将SCOREMSG1的地址传给BP，即输出串地址
    MOV DX,0529H               ; DH = 起始行，DL = 起始列
LOOP72:
    PUSH CX
    MOV CX,21                  ; 串长度
    MOV AL,0H                  ; 逐个字符读，光标返回起始位置
    MOV BH,0H                  ; BH = 页号
    MOV BL,01011010B           ; BL颜色属性为IRGB|IRGB，高4位是背景色，低4位是前景色
    MOV AH,13H                 ; 显示字符串
    INT 10H                    ; 调用
    ADD BP,21                  ; 下一个字符串
    INC DH                     ; 起始行号加
    POP CX
    LOOP LOOP72                    
    MOV BP,OFFSET PADMSG       ; 将PADMSG的地址传给BP
    MOV CX,24                    
    MOV DX,0308H                
    MOV BH,0H
    MOV AL,0H
    MOV BL,00110100B
    MOV AH,13H
    INT 10H                    ; 画游戏窗口上端
    MOV DX,1808H
    INT 10H                    ; 画游戏窗口下端
    MOV CX,20
    MOV DX,0308H               ; 画20个竖直排列的方块
LOOP4:
    MOV SI,CX
    MOV CX,02
    INC DH
    INT 10H
    MOV CX,SI
    LOOP LOOP4
    MOV CX,20
    MOV DX,031EH
LOOP11:
    MOV SI,CX
    MOV CX,02
    INC DH
    INT 10H
    MOV CX,SI
    LOOP LOOP11                    
    CLD                        ; 从前往后处理
    MOV DI,OFFSET BOARD        ; 将BOARD的地址给DI
    MOV CX,24                  ; 构建游戏区
    MOV AX,0E007H              ; 1110000000000111（0为游戏区）24行
    REP STOSW                  ; 将ax中的值拷贝到ES:DI指向的地址
    MOV DI,OFFSET SCORE        ; 构建分数
    MOV AL,'0'
    MOV CX,05H
    REP STOSB                  ; 将al中的值拷贝到ES:DI指向的地址
    CALL RANDOM                ; 调用随机函数
    MOV AL,NXT
    MOV NOW,AL
    RET
INITGAME ENDP

END START