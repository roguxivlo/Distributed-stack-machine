global core

; Funkcje dostarczone z zewnątrz:
extern get_value
extern put_value

section .text

; Makro do wypisywania, do debugowania.
;%include "macro_print.asm"

; Argumenty funkcji core:
;
; uint64_t core(uint64_t n, char const *p)
;
; rdi = n (numer rdzenia)
; rsi = p (wskaźnik na zapis obliczenia)

core:
; Zapisujemy rsp w rbx, aby na koniec obliczenia zresetować stos:
        ;print   "initial stack: ", rsp
        push    rbx
        mov     rbx, rsp

; Rozpoczynamy pętlę w której po kolei będziemy obsługiwać kolejne
; polecenia obliczenia.

.main_loop:
        movzx   edx, byte [rsi]         ; rejestr edx zawiera kolejny znak obliczenia.
                                        ; Przy okazji zerujemy starsze bity rejestru.
        test    dl, dl                ; Sprawdzenie, czy edx == '\0'
        jz      .return                 ; Skok wykona się gdy edx == '\0'
                                        ; w przeciwnym razie obsługujemy polecenie.

        ; Sprawdzenie, czy znak jest równy '+':
        cmp     dl, '+'                ; Porównanie ze znakiem '+'
        jz      .plus                   ; Skok do etykiety wykonującej dodawanie.

        ; Sprawdzenie, czy znak jest równy '*':
        cmp     dl, '*'                ; Porównanie ze znakiem '*'
        jz      .multiply               ; Skok do etykiety wykonującej mnożenie.

        ; Sprawdzenie, czy znak jest równy '-':
        cmp     dl, '-'                        ; Porównanie ze znakiem '-'
        jz      .negate                         ; Skok do etykiety wykonującej negację.

        ; Sprawdzenie, czy znak jest równy 'n':
        cmp     dl, 'n'                        ; Porównanie ze znakiem 'n'
        jz      .push_core_id                   ; Skok do etykiety wstawiającej n na stos.

        ; Sprawdzenie, czy znak jest równy 'B':
        cmp     dl, 'B'                        ; Porównanie ze znakiem 'B'
        jz      .jump_back                           ; Skok do etykiety wykonującej skok w obliczeniu.

        ; Sprawdzenie, czy znak jest równy 'C':
        cmp     dl, 'C'                ; Porównanie ze znakiem 'C'
        jz      .throw_away                   ; Skok do etykiety zrzucającej element ze stosu.

        ; Sprawdzenie, czy znak jest równy 'D':
        cmp     dl, 'D'                ; Porównanie ze znakiem 'D'
        jz      .duplicate                   ; Skok do etykiety duplikującej szczyt stosu.

        ; Sprawdzenie, czy znak jest równy 'E':
        cmp     dl, 'E'                ; Porównanie ze znakiem 'E'
        jz      .swap                   ; Skok do etykiety zamieniającej miejscami dwa szczytowe elementy stosu.

        ; Sprawdzenie, czy znak jest równy 'G':
        cmp     dl, 'G'                ; Porównanie ze znakiem 'G'
        jz      .get_value                   ; Skok do etykiety wołającej funkcję get_value.

        ; Sprawdzenie, czy znak jest równy 'P':
        cmp     dl, 'P'                ; Porównanie ze znakiem 'P'
        jz      .put_value                   ; Skok do etykiety wołającej funkcję put_value.

        ; Sprawdzenie, czy znak jest równy 'S':
        cmp     dl, 'S'                ; Porównanie ze znakiem 'S'
        jz      .sync                   ; Skok do etykiety synchronizującej.

; W przeciwnym wypadku mamy do czynienia z cyfrą:
.put_digit:
        mov cl, '0'
        sub     dl, cl                    ; Rejestr dl zawiera numeryczną wartość liczby.
        ;print   "digit = ", rdx         ; debug
        ;print   "before: ", rsp
        push    rdx                     ; wstawiamy liczbę na stos.
        jmp     .next_iter

.return:
        pop     rax                     ; ładujemy szczyt stosu jako wynik
        ;print   "the end. current stack after pop: ", rsp
        mov     rsp, rbx                ; resetujemy stos do stanu sprzed wywołania funkcji.
        ;print   "stack restored: ", rsp
        pop     rbx
        ret

.plus:
        pop     rax                     ; zdejmij pierwszą liczbę ze stosu
        ;print   "+ ", rax
        add     [rsp], rax              ; dodaj ją do wierzchołka stosu
        jmp     .next_iter

.multiply:
        pop     rax                     ; zdejmij pierwszą liczbę ze stosu
        ;print   "* ", rax
        mul     qword [rsp]             ; pomnóż ją przez wierzchołek stosu
        add     rsp, 8                  ; zdejmij ze stosu drugą liczbę
        push    rax                     ; wstaw wynik na stos
        jmp     .next_iter

.negate:
        pop     rax                     ; zdejmij liczbę ze stosu
        ;print   "- ", rax               ; debugowanie
        neg     rax                     ; zmień znak liczby
        push    rax                     ; wstaw liczbę na stos
        jmp     .next_iter

.push_core_id:
        ;print   "push n ", rdx
        push    rdi                     ; wstaw id rdzenia na stos
        jmp     .next_iter

.jump_back:
        ;print "B ", rdx
        jmp     .next_iter

.throw_away:
        ;print "C ", rdx
        add     rsp, 8                  ; zdejmij ze stosu liczbę
        jmp     .next_iter

.duplicate:
        ;print "D ", rdx
        push    qword [rsp]                   ; wstaw na stos kopię szczytowego elementu
        jmp     .next_iter

.swap:
        ;print "E ", rdx
        jmp     .next_iter

.get_value:
        ;print "G ", rdx
        jmp     .next_iter

.put_value:
        ;print "P ", rdx
        jmp     .next_iter

.sync:
        ;print "S ", rdx
        jmp     .next_iter

.next_iter:
        inc rsi
        jmp     .main_loop