#include <assert.h>
#include <inttypes.h>
#include <pthread.h>
#include <stddef.h>
#include <stdio.h>

// Ustalamy liczbę rdzeni.
#define N 1

// To jest deklaracja funkcji, którą trzeba zaimplementować.
uint64_t core(uint64_t n, char const *p);

// Tę funkcję woła rdzeń.
uint64_t get_value(uint64_t n) {
  assert(n < N);
  return n + 1;
}

// Tę funkcję woła rdzeń.
void put_value(uint64_t n, uint64_t v) {
  assert(n < N);
  assert(v == n + 4);
}

// To jest struktura służąca do przekazania do wątku parametrów wywołania
// rdzenia i zapisania wyniku obliczenia.
typedef struct {
  uint64_t n, result;
  char const *p;
} core_call_t;

// Wszystkie rdzenie powinny wystartować równocześnie.
static volatile int wait = 0;

// Ta funkcja uruchamia obliczenie na jednym rdzeniu.
static void *core_thread(void *params) {
  core_call_t *cp = (core_call_t *)params;

  // Wszystkie rdzenie powinny wystartować równocześnie.
  while (wait == 0)
    ;

  printf("n = %" PRIu64 ", result = %" PRIu64 "\n", cp->n, cp->result);

  cp->result = core(cp->n, cp->p);
  // print n and result:
  printf("n = %" PRIu64 ", result = %" PRIu64 "\n", cp->n, cp->result);

  return NULL;
}

// Definicje różnych testowych obliczeń:
const char* digits_only = "01DC";

int main() {
  static pthread_t tid[N];
  static core_call_t params[N];
  static const char *computation[N];
  if (N == 2) {
    computation[0] = "01234n+P56789E-+D+*G*1n-+S2ED+E1-+75+-BC";
    computation[1] = "01234n+P56789E-+D+*G*1n-+S2ED+E1-+75+-BC";
  }
  if (N == 1) {
    computation[0] = digits_only;
  }
  static const uint64_t result[2] = {112, 56};

  for (size_t n = 0; n < N; ++n) {
    params[n].n = n;
    // print n:
    printf("n = %" PRIu64 "\n", params[n].n);
    params[n].result = 0;
    params[n].p = computation[n];
  }

  for (size_t n = 0; n < N; ++n)
    assert(0 ==
           pthread_create(&tid[n], NULL, &core_thread, (void *)&params[n]));

  wait = 1;  // Wystartuj rdzenie.

  for (size_t n = 0; n < N; ++n) assert(0 == pthread_join(tid[n], NULL));

  // print results:
  for (int i = 0; i < N; i++) {
    printf("result[%d] = %" PRIu64 "\n", i, params[i].result);
  }

  // for (size_t n = 0; n < N; ++n) assert(params[n].result == result[n]);
}
