all: runtime.o runtime_multithread.o

CC = gcc
CC_FLAGS = -Wall
ASM = nasm
ASM_FLAGS = -f elf64
CC_MULTITHREAD = -D MULTITHREAD -pthread
# Find all directories libpthread-related files exist within, and construct a
# string of "-L libdir -L libdir ...". The list may contain duplicates, but
# ld doesn't appear to mind. This was originally written with
# `locate libpthread | xargs dirname | uniq | <perl script>` but Travis CI
# doesn't have `locate` and appears to choke on the `xargs dirname`
LD_LIBS = $(shell find / -name 'libpthread.*' -print 2> /dev/null | perl -MFile::Basename -e 'print join " ", map {$$t = $$_; chomp $$t; (undef, $$t, undef) = fileparse $$t; "-L $$t"} <STDIN>')
LD_MULTITHREAD = $(LD_LIBS) -lpthread

runtime.o: callFunc.o scheduler.o realloc_stack.o
	ld -r callFunc.o scheduler.o realloc_stack.o -o runtime.o

runtime_multithread.o: callFunc_multithread.o scheduler_multithread.o tls.o \
					   realloc_stack_multithread.o
	ld $(LD_MULTITHREAD) -r callFunc_multithread.o scheduler_multithread.o \
	    tls.o realloc_stack_multithread.o -o runtime_multithread.o

callFunc.o: callFunc.asm
	$(ASM) $(ASM_FLAGS) callFunc.asm

callFunc_multithread.o: callFunc_multithread.asm
	$(ASM) $(ASM_FLAGS) callFunc_multithread.asm

realloc_stack.o: scheduler.c scheduler.h realloc_stack.c realloc_stack.h \
				 stack_realloc.asm
	$(ASM) $(ASM_FLAGS) stack_realloc.asm
	$(CC) $(CC_FLAGS) -c realloc_stack.c -o realloc_stack_c.o
	ld -r stack_realloc.o realloc_stack_c.o -o realloc_stack.o

realloc_stack_multithread.o: scheduler.c scheduler.h realloc_stack.c \
							 realloc_stack.h stack_realloc.asm
	$(ASM) $(ASM_FLAGS) stack_realloc.asm
	$(CC) $(CC_FLAGS) $(CC_MULTITHREAD) -c realloc_stack.c -o realloc_stack_c.o
	ld $(LD_MULTITHREAD) -r stack_realloc.o realloc_stack_c.o -o \
	    realloc_stack_multithread.o

scheduler.o: scheduler.c scheduler.h
	$(CC) $(CC_FLAGS) -c scheduler.c

scheduler_multithread.o: scheduler.c scheduler.h
	$(CC) $(CC_FLAGS) $(CC_MULTITHREAD) -c scheduler.c \
	    -o scheduler_multithread.o

tls.o: tls.asm
	as tls.asm -o tls.o

# Provided so that the invocation used to produce tls.asm is recorded
tls.asm: tls.c tls.h
	$(CC) $(CC_FLAGS) -O3 -pthread -S -c tls.c -masm=intel -o tls.asm

.PHONY: clean
clean:
	rm -f *.o

.PHONY: realclean
realclean:
