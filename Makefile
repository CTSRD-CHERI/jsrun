
OBJECTS=duktape.o jsrun.o modules.o worker.o env.o

all: jsrun

LLVM_CONFIG ?= llvm-config
#CFLAGS+=-O1
#CFLAGS+=-O3 -DNDEBUG
#CXXFLAGS+=-O0 -g
#CFLAGS+=-Werror
CFLAGS+=-DDUK_OPT_UNDERSCORE_SETJMP=1
CFLAGS+=-DDUK_OPT_FORCE_ALIGN=32
CFLAGS+=-DDUK_OPT_DEBUG=3
#CFLAGS+=-DDUK_OPT_DDDPRINT=1 -DDUK_OPT_DDPRINT=1 -DDUK_OPT_DPRINT=1

CC=~/sdk/bin/clang
CFLAGS+=-msoft-float -mabi=sandbox -cheri-linker
CFLAGS+=-DDUK_USE_PACKED_TVAL=1
CFLAGS+=-I/usr/include/edit
LDFLAGS+=-mabi=sandbox -cheri-linker 
LDFLAGS+=-ledit -lc -lmalloc_simple

ffigen: ffigen.cc
	${CXX} ${CXXFLAGS} -o ffigen ffigen.cc -I `${LLVM_CONFIG} --includedir` -L `${LLVM_CONFIG} --libdir` -lclang -std=c++11

jsrun: $(OBJECTS)
	${CC} -o jsrun $(OBJECTS) $(LDFLAGS) -lm  -ltermcap

jsrun.dump: jsrun
	~/sdk/bin/llvm-objdump -disassemble -r -triple=cheri-unknown-freebsd jsrun > jsrun.dump

jsrun.gdump: jsrun
	~/sdk/bin/objdump -dr jsrun > jsrun.gdump

duktape.preprocessed.c: duktape.c
	${CC} -o duktape.preprocessed.c -E $(CFLAGS) duktape.c

duktape.ll: duktape.c
	${CC} -o duktape.ll -S -emit-llvm $(CFLAGS) duktape.c

duktape.s: duktape.c
	${CC} -o duktape.s -S $(CFLAGS) duktape.c

clean:
	rm -f jsrun ffigen $(OBJECTS)
