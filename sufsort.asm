%include "asm_io.inc"
extern printf

SECTION .data
msg_on_argc_error           db  "arguements count error", 0
msg_on_length_error         db  "length error", 0
msg_on_composition_error    db  "composition error", 0
msg_on_param_error          db  "param error", 0
y                           db  0, 1, 2, 3, 4 ,5, 6, 7, 8, 9, 10, 11, 12, 13, 14 ,15, 16, 17, 18, 19, 20, 21, 22, 23, 24 ,25, 26, 27, 28, 29
msg_on_print                db  "sorted suffixes:", 0


SECTION .bss
X:      resb 31 ; length of input string <= 30, last byte is used to save 0(C string end)
N:      resd 1
Z:      resd 1
i:      resd 1
j:      resd 1
retval: resd 1

SECTION .text
    global asm_main
    extern strlen
    global sufcmp

;subroutine
    sufcmp:
        push ebp
        mov ebp, esp
        pusha

        ; check parameters, 0 <= i < N
        mov eax, dword [i]
        cmp eax, dword 0 
        jl sufcmp_param_error
        cmp dword [N], eax
        jle sufcmp_param_error
        ; check parameters, 0 <= j < N
        mov eax, dword [j]
        cmp eax, dword 0 
        jl sufcmp_param_error
        cmp dword [N], eax
        jle sufcmp_param_error
        
        ; debug print
        ;mov eax, dword [Z]
        ;add eax, dword [i]
        ;call print_string
        ;mov eax, dword '-'
        ;call print_char
        ;mov eax, dword [Z]
        ;add eax, dword [j]
        ;call print_string

        mov ebx, dword [Z]
        mov ecx, dword 0
        sufcmp_loop_start:
            push ecx
            add ecx, dword [i]
            mov al, byte [ebx+ecx]  ; al = Z[i+ecx]
            pop ecx
            push ecx
            add ecx, dword [j]
            mov ah, byte [ebx+ecx]  ; ah = Z[j+ecx]
            pop ecx
            add ecx, 1
            ; check string end
            cmp ah, byte 0
            je sufcmp_ret_bigger  
            cmp al, byte 0
            je sufcmp_ret_smaller    
            ; compare Z[i+ecx] with Z[j+ecx]
            cmp al, ah
            ja sufcmp_ret_bigger    ; if Z[i+ecx] > Z[j+ecx]
            jl sufcmp_ret_smaller   ; else if Z[i+ecx] < Z[j+ecx]
            jmp sufcmp_loop_start   ; else continue

        sufcmp_ret_bigger:
            mov dword [retval], 1
            jmp sufcmp_end
        sufcmp_ret_smaller:   
            mov dword [retval], -1
            jmp sufcmp_end

        jmp sufcmp_end
        sufcmp_param_error:
            mov eax, msg_on_param_error
            call print_string
            call print_nl

        sufcmp_end:
        popa
        pop ebp
        ret



;main
    asm_main:
        ; at this points, argc is on stack at address esp+4
        ; address of 1st argument is on stack at address esp+8
        enter 0,0     ; push ebp and move ebp, esp
        pusha         ; push all registers

        ; at this points, argc is on stack at address ebp+8 (old ebp is on stack at address ebp+4)
        ; address of 1st argument = name of the program is at address ebp+12
        ; address of 2nd argument = address of 1st argument + 4 => ebp+16

        ; check argc == 2, if not,  print error and exit
        mov eax, dword [ebp+8]   ; eax holds count of arguements
        cmp eax, dword 2             ; cmp eax to 2
        je check_argc_end        ; if equal, jump to check_argc_end
            mov eax, msg_on_argc_error
            call print_string        ; if not equal, print error message
            call print_nl
            jmp sufsort_exit         ; if not equal, jump to sufsort_exit
        check_argc_end:

        ;[[argc][address]]

        ;address:[arg1][arg2]

        ;arg1:string...

        ;arg2:string...

        ; check length of 2nd parameter, if > 30, print error and exit
        ; and check content of input string, if not in "0" "1" "2", print error and exit
                                    ; ebp store the address of arg pointers
        mov ebx, dword [ebp+12]     ; ebx store the address of 1st arg
        add ebx, 4                  ; ebx store the address of 2nd arg
        mov ebx, dword [ebx]        ; ebx store the address of 2nd char in intput string
        mov ecx, dword 0
        my_strlen:
            mov eax, 0
            mov al, byte [ebx+ecx]     ;ebx[ecx]
            add ecx, 1
            ; if ebx[ecx] == 0: strlen end
            cmp eax, dword 0
            je my_strlen_end
            ; if ebx[ecx] != 0 and ecx == 31: length error
            cmp ecx, dword 31
            je check_strlen_fail
            ; check content in "0" "1" "2"
                cmp eax, dword '0'
                je content_char_pass
                cmp eax, dword '1'
                je content_char_pass
                cmp eax, dword '2'
                je content_char_pass
                mov eax, msg_on_composition_error
                call print_string        ; if not equal, print error message
                call print_nl
                jmp sufsort_exit         ; if not equal, jump to sufsort_exit
            content_char_pass:
            jmp my_strlen
        my_strlen_end:
        sub ecx, 1
        cmp ecx, 30
        jbe check_strlen_end
        check_strlen_fail:
            mov eax, msg_on_length_error
            call print_string        ; if not equal, print error message
            call print_nl
            jmp sufsort_exit         ; if not equal, jump to sufsort_exit
        check_strlen_end:
        mov dword [N], ecx            ; N <- length of input string

        ; copy input string to X
        mov ebx, dword [ebp+12]     ; ebx store the address of 1st arg
        add ebx, 4                  ; ebx store the address of 2nd arg
        mov ebx, dword [ebx]        ; ebx store the address of 2nd char in intput string
        mov ecx, dword 0            ; ecx: loop counter
        mov eax, dword 0            ; eax: temp
        copy_start:
            mov al, byte [ebx+ecx]  ; al = ebx[ecx] (ebx[ecx] === [ebx+ecx])
            mov byte [X+ecx], al    ; X[ecx] = al
            add ecx, 1              ; ecx++
            cmp ecx, dword [N]        ; if cl != N
            jne copy_start              ; goto copy_start
        mov byte [X+ecx], byte 0    ; X[N] = 0, C string end with 0

        ; print out input string
        mov eax, X
        call print_string
        call print_nl

        ; bubble sort
        mov eax, dword 0
        mov ebx, y
        mov dword [Z], X
        mov dword [i], 0
        mov dword [j], 0

        ; for i in range(N,0,-1): (i is dl)
        mov dl, byte [N]
        bubble_sort_start:
        cmp dl, byte 0
        je bubble_sort_end
            ; for j in range(1,i): (j is dh)
            mov dh, byte 1
            bubble_sort_inner_start:
            cmp dh, dl
            je bubble_sort_inner_end

                ; debug print
                ;mov eax, 0
                ;mov al, dl
                ;call print_int
                ;mov eax, dword ' '
                ;call print_char
                ;mov al, dh
                ;call print_int
                ;mov eax, dword ','
                ;call print_char

                ; ii = y[j-1]
                mov ecx, 0
                mov cl, dh
                sub cl, 1
                mov eax, 0
                mov al, byte [ebx+ecx]  ; eax = y[dh-1]
                ;call print_int
                mov dword [i], eax      ; ii = eax
                ;mov eax, dword '-'
                ;call print_char

                ; jj = y[j]
                mov eax, 0
                mov ecx, 0
                mov cl, dh
                mov al, byte [ebx+ecx]   ; eax = y[dh]
                ;call print_int
                mov dword [j], eax      ; jj = eax
                ;mov eax, dword '>'
                ;call print_char

                ; k = sufcmp(Z,y[j-1],y[j]) (k is [retval])
                call sufcmp
                cmp dword [retval], 1
                jne noswap

                    ; swap y[j-1] with y[j], using stack
                    mov eax, 0
                    mov ecx, 0
                    mov cl, dh
                    mov al, byte [ebx+ecx]
                    push eax
                    sub cl, 1
                    mov al, byte [ebx+ecx]
                    push eax
                    add cl, 1
                    pop eax
                    mov byte [ebx+ecx], al
                    sub cl, 1
                    pop eax
                    mov byte [ebx+ecx], al

                noswap:

                ;call print_nl

            ; end for loop
            add dh, 1
            jmp bubble_sort_inner_start
            bubble_sort_inner_end:

        ; end for loop
        sub dl, 1
        jmp bubble_sort_start
        bubble_sort_end:

        ; print("sorted suffixes:")
        mov eax, msg_on_print
        call print_string
        call print_nl

        ; for ecx in range(N):
        mov ebx, y
        mov ecx, 0
        output_start:
        cmp ecx, dword [N]
        je output_end
            
            ; print(Z[y[i]:N])
            mov eax, 0
            mov al, byte [ebx+ecx]  ; eax = y[i]
            add eax, X              ; eax += X
            call print_string
            call print_nl

        add ecx, 1
        jmp output_start
        output_end:

        ;READ CHAR ENDING 
        call read_char 

        sufsort_exit:
        popa
        leave
        ret

