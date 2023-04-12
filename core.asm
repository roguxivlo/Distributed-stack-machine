global core

; Funkcje dostarczone z zewnątrz:
extern get_value
extern put_value

section .text

; Makro do wypisywania, do debugowania.
%include "macro_print.asm"

; Argumenty funkcji core:
;
; uint64_t core(uint64_t n, char const *p)
;
; rdi = n (numer rdzenia)
; rsi = p (wskaźnik na zapis obliczenia)

core:
; Rozpoczynamy pętlę w której po kolei będziemy obsługiwać kolejne
; polecenia obliczenia.

.main_loop:
        movzx   edi, byte [rsi]         ; rejestr edi zawiera kolejny znak obliczenia.
                                        ; Przy okazji zerujemy starsze bity rejestru.
        test    dil, dil                ; Sprawdzenie, czy edi == '\0'
        jz      .return                 ; Skok wykona się gdy edi == '\0'
                                        ; w przeciwnym razie obsługujemy polecenie.

        ; Sprawdzenie, czy znak jest równy '+':
        cmp     dil, '+'                ; Porównanie ze znakiem '+'
        jz      .plus                   ; Skok do etykiety wykonującej dodawanie.

        ; Sprawdzenie, czy znak jest równy '*':
        cmp     dil, '*'                ; Porównanie ze znakiem '*'
        jz      .multiply               ; Skok do etykiety wykonującej mnożenie.

        ; Sprawdzenie, czy znak jest równy '-':
        cmp     dil, '-'                        ; Porównanie ze znakiem '-'
        jz      .negate                         ; Skok do etykiety wykonującej negację.

        ; Sprawdzenie, czy znak jest równy 'n':
        cmp     dil, 'n'                        ; Porównanie ze znakiem 'n'
        jz      .push_core_id                   ; Skok do etykiety wstawiającej n na stos.

        ; Sprawdzenie, czy znak jest równy 'B':
        cmp     dil, 'B'                        ; Porównanie ze znakiem 'B'
        jz      .jump_back                           ; Skok do etykiety wykonującej skok w obliczeniu.

        ; Sprawdzenie, czy znak jest równy 'C':
        cmp     dil, 'C'                ; Porównanie ze znakiem 'C'
        jz      .throw_away                   ; Skok do etykiety zrzucającej element ze stosu.

        ; Sprawdzenie, czy znak jest równy 'D':
        cmp     dil, 'D'                ; Porównanie ze znakiem 'D'
        jz      .duplicate                   ; Skok do etykiety duplikującej szczyt stosu.

        ; Sprawdzenie, czy znak jest równy 'E':
        cmp     dil, 'E'                ; Porównanie ze znakiem 'E'
        jz      .swap                   ; Skok do etykiety zamieniającej miejscami dwa szczytowe elementy stosu.

        ; Sprawdzenie, czy znak jest równy 'G':
        cmp     dil, 'G'                ; Porównanie ze znakiem 'G'
        jz      .get_value                   ; Skok do etykiety wołającej funkcję get_value.

        ; Sprawdzenie, czy znak jest równy 'P':
        cmp     dil, 'P'                ; Porównanie ze znakiem 'P'
        jz      .put_value                   ; Skok do etykiety wołającej funkcję put_value.

        ; Sprawdzenie, czy znak jest równy 'S':
        cmp     dil, 'S'                ; Porównanie ze znakiem 'S'
        jz      .sync                   ; Skok do etykiety synchronizującej.

; W przeciwnym wypadku mamy do czynienia z cyfrą:
.put_digit:
        mov cl, '0'
        sub     dil, cl                    ; Rejestr dil zawiera numeryczną wartość liczby.
        print   "digit = ", rdi         ; debug
        jmp .next_iter

.return:
        print "the end. ", rdi
        ret

.plus:
        print "+ ", rdi
        jmp .next_iter

.multiply:
        print "* ", rdi
        jmp .next_iter

.negate:
        print "- ", rdi
        jmp .next_iter

.push_core_id:
        print "push n ", rdi
        jmp .next_iter

.jump_back:
        print "B ", rdi
        jmp .next_iter

.throw_away:
        print "C ", rdi
        jmp .next_iter

.duplicate:
        print "D ", rdi
        jmp .next_iter

.swap:
        print "E ", rdi
        jmp .next_iter

.get_value:
        print "G ", rdi
        jmp .next_iter

.put_value:
        print "P ", rdi
        jmp .next_iter

.sync:
        print "S ", rdi
        jmp .next_iter

.next_iter:
        inc rsi
        jmp .main_loop