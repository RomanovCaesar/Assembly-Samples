.MODEL SMALL
.STACK 100h

.DATA
    PROMPT_X DB '请输入第一个一位十六进制数 (0-9, A-F): $'
    PROMPT_Y DB 0Dh, 0Ah, '请输入第二个一位十六进制数 (0-9, A-F): $' ; 0Dh, 0Ah 是换行符
    PROMPT_OP DB 0Dh, 0Ah, '请输入操作符 (A, B, C, D): $'
    RESULT_MSG DB 0Dh, 0Ah, '结果 (十六进制): $'
    ERR_DIV_ZERO DB 0Dh, 0Ah, '错误：除数不能为零!$'
    ERR_INVALID_OP DB 0Dh, 0Ah, '错误：无效的操作符!$'

    VAR_X DB ?       ; 存储第一个十六进制数的值 (0-15)
    VAR_Y DB ?       ; 存储第二个十六进制数的值 (0-15)
    OPERATION DB ?   ; 存储操作符字符 ('A', 'B', 'C', 'D')

.CODE
MAIN PROC
    ; 初始化数据段寄存器 DS
    MOV AX, @DATA
    MOV DS, AX

    ; --- 获取第一个十六进制数 X ---
    LEA DX, PROMPT_X    ; 加载提示符地址到 DX
    MOV AH, 09h         ; DOS 功能号：显示字符串
    INT 21h             ; 调用 DOS 中断

    MOV AH, 01h         ; DOS 功能号：从键盘读取一个字符 (带回显)
    INT 21h             ; AL = 输入的 ASCII 字符
    CALL ASCII_TO_HEX   ; 将 AL 中的 ASCII 转换为十六进制数值
    MOV VAR_X, AL       ; 保存数值到 VAR_X

    ; --- 获取第二个十六进制数 Y ---
    LEA DX, PROMPT_Y
    MOV AH, 09h
    INT 21h

    MOV AH, 01h
    INT 21h
    CALL ASCII_TO_HEX
    MOV VAR_Y, AL

    ; --- 获取操作符 ---
    LEA DX, PROMPT_OP
    MOV AH, 09h
    INT 21h

    MOV AH, 01h
    INT 21h
    MOV OPERATION, AL   ; 保存操作符字符

    ; --- 显示结果提示信息 ---
    LEA DX, RESULT_MSG
    MOV AH, 09h
    INT 21h

    ; --- 根据操作符执行计算 ---
    MOV AL, VAR_X       ; 将 X 加载到 AL
    MOV BL, VAR_Y       ; 将 Y 加载到 BL
    MOV AH, 0           ; 清零 AH，为乘法/除法做准备，也方便结果处理

    CMP OPERATION, 'A'
    JE CALC_ADD
    CMP OPERATION, 'B'
    JE CALC_SUB_ABS
    CMP OPERATION, 'C'
    JE CALC_MUL
    CMP OPERATION, 'D'
    JE CALC_DIV

    ; 如果操作符无效
    LEA DX, ERR_INVALID_OP
    MOV AH, 09h
    INT 21h
    JMP EXIT

CALC_ADD:
    ADD AL, BL          ; AL = AL + BL (X + Y)
    ; 结果在 AL 中 (因为 X, Y <= F, X+Y <= 1E, 不会溢出到 AH)
    JMP DISPLAY_RESULT

CALC_SUB_ABS:
    CMP AL, BL          ; 比较 X 和 Y
    JNB SUB_DO          ; 如果 AL >= BL (X >= Y)，直接相减
    ; 如果 AL < BL (X < Y)，交换 AL 和 BL，然后相减
    XCHG AL, BL
SUB_DO:
    SUB AL, BL          ; AL = AL - BL (|X - Y|)
    ; 结果在 AL 中
    JMP DISPLAY_RESULT

CALC_MUL:
    ; 8位乘法： AX = AL * BL
    MUL BL              ; AX = X * Y (最大 F*F = E1h，结果在 AX 中)
    ; 结果在 AX 中，需要显示两位十六进制数
    CALL DISPLAY_HEX_AX ; 调用显示 AX 的函数
    JMP EXIT            ; 直接退出，因为显示函数已完成

CALC_DIV:
    CMP BL, 0           ; 检查除数 Y 是否为 0
    JE DIV_ZERO_ERROR   ; 如果是 0，跳转到错误处理

    ; 8位除法： AL = AX / BL, AH = AX % BL
    ; 注意：这里 AX 的高位 AH 必须为 0
    DIV BL              ; AL = X / Y (商), AH = X % Y (余数)
    ; 我们只需要商，它在 AL 中
    JMP DISPLAY_RESULT

DIV_ZERO_ERROR:
    LEA DX, ERR_DIV_ZERO
    MOV AH, 09h
    INT 21h
    JMP EXIT

DISPLAY_RESULT:
    ; 此时结果在 AL 中 (来自 ADD, SUB, DIV)
    ; 需要将 AL (一个字节，两位十六进制) 显示出来
    MOV AH, 0           ; 将结果扩展到 AX (高位为0)
    CALL DISPLAY_HEX_AX ; 调用通用的显示 AX 的函数
    JMP EXIT

; --- 子程序：将 AX 中的值以十六进制显示 ---
DISPLAY_HEX_AX PROC
    ; 输入: AX = 要显示的16位数值
    ; 输出: 在屏幕上打印 AX 的十六进制表示 (最多4位)
    ; 描述: 先显示高字节 AH，再显示低字节 AL。
    ;       对于此题，因为最大结果是 E1h，最多显示两位，
    ;       但写一个通用的显示 AX 的函数更好。

    PUSH AX             ; 保存 AX
    PUSH CX             ; 保存 CX
    PUSH DX             ; 保存 DX

    ; 显示高字节 (AH)
    MOV AL, AH          ; 将高字节移到 AL
    CALL DISPLAY_HEX_BYTE ; 调用显示字节的函数

    ; 显示低字节 (AL from original AX)
    POP DX              ; 恢复 DX (虽然没用到，但为了对称)
    POP CX              ; 恢复 CX
    POP AX              ; 恢复原始 AX
    ; AL 现在包含原始 AX 的低字节
    CALL DISPLAY_HEX_BYTE ; 调用显示字节的函数

    POP DX              ; 恢复 DX
    POP CX              ; 恢复 CX
    POP AX              ; 恢复 AX
    RET
DISPLAY_HEX_AX ENDP

; --- 子程序：将 AL 中的值以两位十六进制显示 ---
DISPLAY_HEX_BYTE PROC
    ; 输入: AL = 要显示的8位数值 (00h - FFh)
    ; 输出: 在屏幕上打印 AL 的两位十六进制表示
    PUSH AX             ; 保存 AX
    PUSH CX             ; 保存 CX
    PUSH DX             ; 保存 DX

    ; 1. 显示高四位 (Nibble)
    MOV AH, AL          ; 复制 AL 到 AH
    MOV CL, 4           ; 设置右移位数
    SHR AH, CL          ; AH 右移4位，得到高四位
    MOV AL, AH          ; 将高四位移回 AL 准备转换
    CALL HEX_TO_ASCII_CHAR ; 转换并显示高位字符

    ; 2. 显示低四位 (Nibble)
    POP DX              ; 恢复 DX
    POP CX              ; 恢复 CX
    POP AX              ; 恢复原始 AL 值
    AND AL, 0Fh         ; 清除高四位，只保留低四位
    CALL HEX_TO_ASCII_CHAR ; 转换并显示低位字符

    POP DX              ; 恢复 DX
    POP CX              ; 恢复 CX
    POP AX              ; 恢复 AX
    RET
DISPLAY_HEX_BYTE ENDP


; --- 子程序：将 AL 中的十六进制数值 (0-F) 转换为 ASCII 字符并显示 ---
HEX_TO_ASCII_CHAR PROC
    ; Input: AL = 十六进制数值 (0-15)
    ; Output: 显示对应的 ASCII 字符 ('0'-'9', 'A'-'F')
    ; Modifies: DL, AH
    CMP AL, 9           ; 与 9 比较
    JBE DIGIT           ; <= 9, 是数字 '0'-'9'
    ; > 9, 是字母 'A'-'F'
    ADD AL, 'A' - 10    ; 加上 'A' 的 ASCII 码再减去 10
    JMP DISPLAY_CHAR
DIGIT:
    ADD AL, '0'         ; 加上 '0' 的 ASCII 码
DISPLAY_CHAR:
    MOV DL, AL          ; 要显示的字符放入 DL
    MOV AH, 02h         ; DOS 功能号：显示字符
    INT 21h
    RET
HEX_TO_ASCII_CHAR ENDP

; --- 子程序：将 ASCII 字符 ('0'-'9', 'A'-'F') 转换为十六进制数值 (0-F) ---
ASCII_TO_HEX PROC
    ; Input: AL = ASCII 字符 ('0'-'9', 'A'-'F', 'a'-'f')
    ; Output: AL = 对应的十六进制数值 (0-15)
    ; Modifies: None (other than AL)
    CMP AL, '9'         ; 和 '9' 比较
    JBE IS_DIGIT        ; 如果 <= '9', 是数字
    ; 可能是 'A'-'F' 或 'a'-'f'
    CMP AL, 'F'         ; 和 'F' 比较
    JBE IS_UPPER_HEX    ; 如果 <= 'F', 是大写十六进制
    CMP AL, 'f'         ; 和 'f' 比较
    JBE IS_LOWER_HEX    ; 如果 <= 'f', 是小写十六进制
    ; 无效输入 (可以添加错误处理，这里简化假设输入有效)
    JMP CONVERT_EXIT

IS_DIGIT:
    SUB AL, '0'         ; ASCII '0'...'9' 减去 '0' 得到数值 0...9
    JMP CONVERT_EXIT

IS_UPPER_HEX:
    SUB AL, 'A' - 10    ; ASCII 'A'...'F' 减去 'A' 再加 10 得到数值 10...15
    JMP CONVERT_EXIT

IS_LOWER_HEX:
    SUB AL, 'a' - 10    ; ASCII 'a'...'f' 减去 'a' 再加 10 得到数值 10...15
    ; JMP CONVERT_EXIT ; Fall through is okay here

CONVERT_EXIT:
    RET
ASCII_TO_HEX ENDP

EXIT:
    ; 结束程序
    MOV AH, 4Ch         ; DOS 功能号：终止程序
    INT 21h

MAIN ENDP
END MAIN
