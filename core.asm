global core

; Funkcje dostarczone z zewnątrz:
extern get_value
extern put_value

section .data
; Tablica, w której wątek wykonujący S umieści numer wątku z którym
; ma się zsynchronizować. Inicjowana wartością N
; ponieważ żaden wątek nie ma takiego id:
align 8
adr: times N dq N

section .bss
; Tablica, w której wątki zsynchronizowane 
; ze sobą umieszczają wartości do wymiany.
; Tablica jest nieinicjowana.
align 8
val resq N

section .text

; Makro do wypisywania, do debugowania.
%include "macro_print.asm"

; Argumenty funkcji core:
;
; uint64_t core(uint64_t n, char const *p)
;
; rdi = n (numer rdzenia)
; rsi = p (wskaźnik na zapis obliczenia)

align 16
core:
; Zapisujemy rsp w rbx, aby na koniec obliczenia zresetować stos:
; Rejestru rbx nie może zmodyfikować funkcja zewnętrzna, zatem
; nie trzeba się martwić wywołaniami put_value, get_value
        print   "initial stack: ", rsp
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
        print   "digit = ", rdx         ; debug
        print   "before: ", rsp
        push    rdx                     ; wstawiamy liczbę na stos.
        jmp     .next_iter

.return:
        pop     rax                     ; ładujemy szczyt stosu jako wynik
        print   "the end. current stack after pop: ", rsp
        mov     rsp, rbx                ; resetujemy stos do stanu sprzed wywołania funkcji.
        print   "stack restored: ", rsp
        pop     rbx                     ; odzyskujemy pierwotną wartość rbx
        ret

.plus:
        pop     rax                     ; zdejmij pierwszą liczbę ze stosu
        print   "+ ", rax
        add     [rsp], rax              ; dodaj ją do wierzchołka stosu
        jmp     .next_iter

.multiply:
        pop     rax                     ; zdejmij pierwszą liczbę ze stosu
        print   "* ", rax
        mul     qword [rsp]             ; pomnóż ją przez wierzchołek stosu
        add     rsp, 8                  ; zdejmij ze stosu drugą liczbę
        push    rax                     ; wstaw wynik na stos
        jmp     .next_iter

.negate:
        pop     rax                     ; zdejmij liczbę ze stosu
        print   "- ", rax               ; debugowanie
        neg     rax                     ; zmień znak liczby
        push    rax                     ; wstaw liczbę na stos
        jmp     .next_iter

.push_core_id:
        print   "push n ", rdx
        push    rdi                     ; wstaw id rdzenia na stos
        jmp     .next_iter

.jump_back:
        print "B ", rdx
        pop     rax                     ; zdejmij wartość ze stosu
        cmp     qword [rsp], 0                ; Sprawdź, czy na wierzchołku stosu jest 0.
        jz      .next_iter              ; jeśli tak to nic nie rób
                                        ; (przejdź do następnego polecenia).

        ; Jeśli w wierzchołku jest coś niezerowego, przesunięcie po obliczeniu
        ; realizujemy przez dodanie wartości w rax od wskaźnika (rsi). Po dodaniu
        ; i tak nastąpi inkrementacja rsi.
        add     rsi, rax
        print   "jump by: ", rax
        jmp     .next_iter

.throw_away:
        print "C ", rdx
        add     rsp, 8                  ; zdejmij ze stosu liczbę i porzuć ją.
        jmp     .next_iter

.duplicate:
        print "D ", rdx
        push    qword [rsp]                   ; wstaw na stos kopię szczytowego elementu
        jmp     .next_iter

.swap:
        print "E ", rdx
        mov     rax, [rsp + 8]          ; zapisujemy na boku wartość drugiego elementu na stosie
        mov     rcx, [rsp]              ; zapisujemy na boku wartość szczytu stosu.
        mov     [rsp + 8], rcx        ; drugi element przyjmuje wartość szczytu stosu.
        mov     [rsp], rax              ; szczyt stosu dostaje wartość drugiego elementu.
        ; Wymiana jest kompletna.
        jmp     .next_iter

.get_value:
        ; Przed wywołaniem zewnętrznej funkcji, musimy upewnić się
        ; że nie stracimy wartości zapisanych w rejestrach, które
        ; funkcja może zmodyfikować. Zapamiętamy wartości tych
        ; rejestrów na stosie. Musimy zadbać o rejestry:
        ; rdi (wartość n)
        ; rsi (wskaźnik na obecny znak obliczenia)
        ; W rejestrze rdi powinno pozostać n, jako argument get_value,
        ; ale nie mamy gwarancji że po powrocie z funkcji tam zostanie.
        ; Zapisujemy więc te rejestry na stos:
        print   "G. stack before saving: ", rsp
        push    rdi
        push    rsi
        ; W rejestrze rdi jest już poprawny argument funkcji get_value.
        ; Zanim zawołamy get_value, należy upewnić się że
        ; wskaźnik stosu jest podzielny przez 16.
        ; Poniższe instrukcje realizują sprawdzenie. Jeśli rsp nie jest
        ; wielokrotnością 16, wykona się skok do etykiety
        ; .get_value_with_alignment, która zadba o wyrównanie stosu.
        mov     rax, rsp
        and     rax, 0x0000000F         ; badamy ostatnią cyfrę wskaźnika stosu.
        ; Jeśli ostatnia cyfra nie jest 0, to skaczemy do etykiety
        ; wyrównującej stos:
        jnz     .get_value_with_alignment
        print   "stack aligned before get_value: ", rsp
        call    get_value
        print   "stack after get_value: ", rsp
        ; Wynik funkcji znajduje się w rejestrze rax.
        ; Musimy go wstawić na stos obliczeń. Wpierw jednak należy
        ; odzyskać wartości rejestrów rsi i rdi (w tej kolejności):
        pop     rsi
        pop     rdi
        ; Wstawiamy wartość funkcji na stos:
        push rax
        jmp     .next_iter

; To jest etykieta, która wyrównuje rsp do wielokrotności 16
; przed rozkazem call.
.get_value_with_alignment:
        print   "Aligning stack which is now: ", rsp
        sub     rsp, 8
        print   "Stack is now aligned: ", rsp
        call    get_value
        add     rsp, 8
        pop     rsi
        pop     rdi
        push    rax
        jmp     .next_iter

.put_value:
        ; Przed wywołaniem zewnętrznej funkcji, musimy upewnić się
        ; że nie stracimy wartości zapisanych w rejestrach, które
        ; funkcja może zmodyfikować. Zapamiętamy wartości tych
        ; rejestrów na stosie. Musimy zadbać o rejestry:
        ; rdi (wartość n)
        ; rsi (wskaźnik na obecny znak obliczenia)
        ; W rejestrze rdi powinno pozostać n, jako argument put_value,
        ; ale nie mamy gwarancji że po powrocie z funkcji tam zostanie.
        ; Zanim zapiszemy rejestry na stos, musimy zdjąć z niego
        ; drugi argument funkcji put_value:
        pop     rax
        print "P. stack before saving: ", rsp
        ; Zapisujemy teraz rejestry na stos:
        push    rdi
        push    rsi
        ; W rejestrze rsi ma się znaleźć wartość zdjęta ze stosu:
        mov     rsi, rax
        ; Poniższe instrukcje realizują sprawdzenie. Jeśli rsp nie jest
        ; wielokrotnością 16, wykona się skok do etykiety
        ; .get_value_with_alignment, która zadba o wyrównanie stosu.
        mov     rax, rsp
        and     rax, 0x0000000F
        jnz     .put_value_with_alignment
        print   "stack aligned before put_value: ", rsp
        call    put_value
        print   "stack after put_value: ", rsp
        ; Teraz zdejmujemy ze stosu zapisane wcześniej rejestry:
        pop     rsi
        pop     rdi
        jmp     .next_iter

; To jest etykieta, która wyrównuje rsp do wielokrotności 16
; przed rozkazem call.
.put_value_with_alignment:
        print   "Aligning stack which is now: ", rsp
        sub     rsp, 8
        print   "Stack is now aligned: ", rsp
        call    put_value
        add     rsp, 8
        pop     rsi
        pop     rdi
        jmp     .next_iter

.sync:
        print "S ", rdx
        jmp     .next_iter

.next_iter:
        ; Przechodzimy do kolejnego znaku obliczenia.
        inc rsi
        jmp     .main_loop