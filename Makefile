
OBJECTS=duktape.o jsrun.o modules.o worker.o env.o

all: jsrun

LLVM_CONFIG ?= llvm-config
#CFLAGS+=-O1
#CFLAGS+=-O3 -DNDEBUG
#CFLAGS+=-O2
#CXXFLAGS+=-O0 -g
#CFLAGS+=-Werror
CFLAGS+=-DDUK_OPT_NO_ASSERTIONS=1
CFLAGS+=-DDUK_OPT_UNDERSCORE_SETJMP=1
CFLAGS+=-DDUK_OPT_DEBUG=3
#CFLAGS+=-DDUK_OPT_DDDPRINT=1 -DDUK_OPT_DDPRINT=1 -DDUK_OPT_DPRINT=1

CHERI_SDK?=~/sdk

VERSION?=x86

.if $(VERSION) == cheri128 || $(VERSION) == cheri256
CC=$(CHERI_SDK)/bin/cheri-unknown-freebsd-clang
CFLAGS+=-msoft-float
CFLAGS+=-mabi=sandbox
.if $(VERSION) == cheri128
CFLAGS+=-mllvm -cheri128
CFLAGS+=-DDUK_OPT_FORCE_ALIGN=16
.else
CFLAGS+=-DDUK_OPT_FORCE_ALIGN=32
.endif
#CFLAGS+=-mllvm -cheri-no-global-bounds
CFLAGS+=-DDUK_USE_PACKED_TVAL=1
CFLAGS+=--sysroot=$(CHERI_SDK)/sysroot
CFLAGS+=-I/usr/include/edit
CFLAGS+=-g
LDFLAGS+=-mabi=sandbox
LDFLAGS+=--sysroot=$(CHERI_SDK)/sysroot
LDFLAGS+=-static
LDFLAGS+=-ledit -lc
LDFLAGS+=-lpthread
LDFLAGS+=-B $(CHERI_SDK)/bin
LDFLAGS+=-Wl,--whole-archive -lstatcounters -Wl,--no-whole-archive
.elif $(VERSION) == mips
#CC=$(MIPS_SDK)/bin/mips64-unknown-freebsd-clang
CC=$(MIPS_SDK)/bin/cheri-unknown-freebsd-clang
CFLAGS+=-msoft-float
CFLAGS+=-DDUK_USE_PACKED_TVAL=1
CFLAGS+=--sysroot=$(MIPS_SDK)/sysroot
CFLAGS+=-I/usr/include/edit
CFLAGS+=-integrated-as
LDFLAGS+=--sysroot=$(MIPS_SDK)/sysroot
LDFLAGS+=-B $(MIPS_SDK)/bin
LDFLAGS+=-static
LDFLAGS+=-ledit -lc
LDFLAGS+=-lpthread
LDFLAGS+=-Wl,--whole-archive -lstatcounters -Wl,--no-whole-archive
.elif $(VERSION) == x86
CC=clang
LDFLAGS+=-ledit -lpthread
.endif

ffigen: ffigen.cc
	${CXX} ${CXXFLAGS} -o ffigen ffigen.cc -I `${LLVM_CONFIG} --includedir` -L `${LLVM_CONFIG} --libdir` -lclang -std=c++11

jsrun: $(OBJECTS)
	${CC} -o jsrun $(OBJECTS) $(LDFLAGS) -lm  -ltermcap

jsrun.dump: jsrun
	$(CHERI_SDK)/bin/llvm-objdump -disassemble -r -triple=cheri-unknown-freebsd jsrun > jsrun.dump

jsrun.gdump: jsrun
	$(CHERI_SDK)/bin/objdump -dr jsrun > jsrun.gdump

duktape.preprocessed.c: duktape.c
	${CC} -o duktape.preprocessed.c -E $(CFLAGS) duktape.c

duktape.ll: duktape.c
	${CC} -o duktape.ll -S -emit-llvm $(CFLAGS) duktape.c

duktape.s: duktape.c
	${CC} -o duktape.s -S $(CFLAGS) duktape.c

clean:
	rm -f jsrun ffigen $(OBJECTS)
