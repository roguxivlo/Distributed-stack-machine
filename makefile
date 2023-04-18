.PHONY: all clean

N=2

vpath %.asm ../rozwiazania

all: core_example_test

core.o: core.asm
	nasm -DN=$(N) -f elf64 -w+all -w+error -o $@ $<

core_example.o: example.c
	gcc -c -Wall -Wextra -std=c17 -O2 -o $@ $<

core_example_test: core.o core_example.o
	gcc -z noexecstack -lpthread -o $@ $^

clean:
	rm -rf *_test *.o

