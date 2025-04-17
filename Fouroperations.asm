org 100h

; 显示提示信息
print_string macro str
    lea dx, str
    mov ah, 09h
    int 21h
endm

; 读取一个十六进制数字字符，并转换为实际数值（0-15）
read_hex_digit macro reg
    mov ah, 01h
    int 21h
    ; 显示回显的字符
    mov dl, al
    mov ah, 02h
    int 21h

    ; 转换字符到数值
    cmp al, '0'
    jl invalid_input
    cmp al, '9'
    jle num_is_digit
    cmp al, 'A'
    jl invalid_input
    cmp al, 'F'
    jg invalid_input
    sub al, 'A' - 10
    jmp store_digit
num_is_digit:
    sub al, '0'
store_digit:
    mov reg, al
endm

; 显示AX中的值为十六进制（两位）
print_hex proc
    mov bx, ax
    mov cl, 4
    mov ch, 2
next_digit:
    rol bx, cl
    mov al, bl
    and al, 0Fh
    cmp al, 9
    jbe convert_num
    add al, 'A' - 10
    jmp show
convert_num:
    add al, '0'
show:
    mov dl, al
    mov ah, 02h
    int 21h
    dec ch
    jnz next_digit
    ret
print_hex endp

start:
    print_string prompt_x
    read_hex_digit bl ; X 存到 bl

    print_string prompt_y
    read_hex_digit bh ; Y 存到 bh

    print_string prompt_op
    mov ah, 01h
    int 21h
    mov cl, al ; 操作符保存到 cl
    mov dl, al ; 显示操作符
    mov ah, 02h
    int 21h

    ; 根据操作符执行运算
    cmp cl, 'A'
    je do_add
    cmp cl, 'B'
    je do_sub
    cmp cl, 'C'
    je do_mul
    cmp cl, 'D'
    je do_div
    jmp invalid_input

do_add:
    mov al, bl
    add al, bh
    xor ah, ah
    call print_hex
    jmp done

do_sub:
    mov al, bl
    sub al, bh
    jns skip_neg
    neg al
skip_neg:
    xor ah, ah
    call print_hex
    jmp done

do_mul:
    mov al, bl
    mul bh ; 无符号乘法，结果在 AX 中
    call print_hex
    jmp done

do_div:
    cmp bh, 0
    je div_by_zero
    mov al, bl
    xor ah, ah
    div bh
    xor ah, ah
    call print_hex
    jmp done

div_by_zero:
    print_string div_zero_msg
    jmp done

invalid_input:
    print_string invalid_msg
    jmp done

done:
    mov ah, 4ch
    int 21h

; 提示信息
prompt_x db 13,10, 'Enter first hex digit (0-F): $'
prompt_y db 13,10, 'Enter second hex digit (0-F): $'
prompt_op db 13,10, 'Enter operation (A-D): $'
invalid_msg db 13,10, 'Invalid input!', 13,10, '$'
div_zero_msg db 13,10, 'Divide by zero error!', 13,10, '$'

ret
