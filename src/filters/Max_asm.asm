extern Max_c
global Max_asm

;void Max_asm (uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
section .rodata
        ;  00     01   02    03     04   05    06    07   08     09    10    11    12    13    14    15
maskB: db 0x00, 0x80, 0x80, 0x80, 0x04, 0x80, 0x80, 0x80, 0x08, 0x80, 0x80, 0x80, 0x0C, 0x80, 0x80, 0x80

maskR: db 0x02, 0x80, 0x80, 0x80, 0x06, 0x80, 0x80, 0x80, 0x0A, 0x80, 0x80, 0x80, 0x0E, 0x80, 0x80, 0x80

maskG: db 0x01, 0x80, 0x80, 0x80, 0x05, 0x80, 0x80, 0x80, 0x09, 0x80, 0x80, 0x80, 0x0D, 0x80, 0x80, 0x80

padding: db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF

;maskMaxShufle: db 00111001

section .text
Max_asm:
;*src en rdi - *dst en rsi - width en rdx - height en rcx - src_row_size en r8 - dst_row_size en r9
push rbp
mov rbp, rsp
push r12
push r13
push r14
push r15
push rbx
sub rsp, 8

mov r10, 0                          ;Contador para las columnas
mov r11, 0                          ;Contador para las filas

sub rdx, 2
sub rcx, 4
;ciclo que mueve la matriz de 4x4
.ciclo_matriz:
    cmp r10, rdx
    jge .chequear_alto

    ;Cargamos el puntero al primer pixel(0,0) de la matriz 4x4 que vamos a mirar en esta iteracion
    lea r12, [rdi + r10*4]                      ;Desplazamiento sobre columna
    mov rax, r11
    push rdx
    mul r8
    pop rdx
    add r12, rax                                ;Desplazamiento sobre filas
    
    
    mov r14, 0                                  ;Contador de mi ciclo para hallar el max en la matriz del canal
    mov rbx, 0
    ;ciclo para buscar el maximo
    .ciclo_maximo:
    cmp r14, 4                                      
    je .tenemosElMax
    ;calculamos el offset para la fila de esta iteración
    push rdx
    mov rax, r14
    mul r8
    pop rdx      
             
    movdqu xmm0, [r12 + rax]        ; levantamos 4 pixeles de la primera fila
    movdqu xmm1, xmm0               ; guardamos los pixeles en xmm1 para filtralos
    movdqu xmm4, [maskB]
    pshufb xmm1, xmm4               ; filtramos el color azul
    pxor xmm2, xmm2                 ; limpiamos xmm2 
    paddd xmm2, xmm1                ; xmm2 los azules
    movdqu xmm1, xmm0               ; guardamos los pixeles en xmm1 para filtralos
    movdqu xmm4, [maskG]
    pshufb xmm1, xmm4               ; filtramos el color verde
    paddd xmm2, xmm1                ; acumulamos en xmm2 azul + verde
    movdqu xmm1, xmm0               ; guardamos los pixeles en xmm1 para filtralos
    movdqu xmm4, [maskR]
    pshufb xmm1, xmm4               ; filtramos el color rojo
    paddd xmm2, xmm1                ; acumulamos en xmm2 azul + verde + rojo

    movdqu xmm3, xmm2               ; guardamos acumulados

    ;Vamos a shuflear en xmm4 los datos en xmm3 para que quede la data corrida una dword a la derecha, y entonces
    ;comparamos xmm3 con xmm4. Si hacemos esto 3 veces nos queda en xmm3 4 veces repetido la suma maxima.
     
    pshufd xmm4, xmm3, 0b00111001
    pmaxud xmm3, xmm4    
    
    pshufd xmm4, xmm3, 0b00111001
    pmaxud xmm3, xmm4    

    pshufd xmm4, xmm3, 0b00111001
    pmaxud xmm3, xmm4
    ;en este punto tenemos en xmm3 repetido en cada dword el acumulado tal que es maximal
    movd r15d, xmm3
    cmp ebx, r15d
    jb .nuevoMaximo
    inc r14
    jmp .ciclo_maximo

    .nuevoMaximo:
    ;Generamos una mascara que indica el indice del byte con suma de componentes maxima
    inc r14
    mov ebx, r15d
    pcmpeqd xmm2, xmm3               

    pand xmm2, xmm0 ; tenemos el pixel que necesitamos 0xff

        
    ;Pasamos uno a uno cada pixel a registro normal y con sisd comparamos contra 0
    pextrd r13d, xmm2, 0x00

    cmp r13d, 0
    jne .ciclo_maximo

    pextrd r13d, xmm2, 0x01

    cmp r13d, 0
    jne .ciclo_maximo

    pextrd r13d, xmm2, 0x02

    cmp r13d, 0
    jne .ciclo_maximo

    pextrd r13d, xmm2, 0x03
    jmp .ciclo_maximo

    .tenemosElMax:
    ;en este punto tenemos por seguro que r13d contiene al pixel tal que su suma de componentes es maximal
    pinsrd xmm0, r13d, 0x00
    pinsrd xmm0, r13d, 0x01

    lea r12, [rsi + r10*4 + 4]
    push rdx
    mov rax, r11
    mul r9
    pop rdx
    add rax, r9
    lea r12, [r12 + rax]

    movdqu [r12], xmm0 
    
    lea r12, [r12 + r9]
    movdqu [r12], xmm0

add r10, 2
jmp .ciclo_matriz

.chequear_alto:
cmp r11, rcx
je .padding

mov r10, 0
add r11, 2
jmp .ciclo_matriz

.padding:
;Seteamos el padding
    mov r8, 0
    movdqu xmm0, [padding]
    add rdx, 2
    mov r13, rdx
    add rcx, 2
    .topbottom:
        cmp r8, r13
        jge .sides
        movdqu [rsi + r8*4], xmm0
        mov rax, rcx
        mul r9
        lea r12, [rsi + rax]
        ;add r12, r9
        lea r12, [r12 + r9]
        movdqu [r12 + r8*4], xmm0
        add r8, 4
        jmp .topbottom

    .sides:
        cmp rcx, 0
        jl .fin
        movd [rsi], xmm0
        lea r12, [rsi + r9 - 4]
        movd [r12], xmm0
        lea rsi, [rsi + r9]
        dec rcx
        jmp .sides

.fin:        
add rsp, 8
pop rbx
pop r15
pop r14
pop r13
pop r12
pop rbp
ret
