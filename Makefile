CLANG := clang
CFLAGS := -O2 -g -Wall
LDFLAGS := -lbpf -lelf

BPF_SRC := sockmap_accel.bpf.c
BPF_OBJ := $(BPF_SRC:.c=.o)
SKEL_HDR := $(BPF_SRC:.c=.skel.h)
USER_SRC := loader.c
USER_APP := loader

.PHONY: all clean

all: $(USER_APP)

$(BPF_OBJ): $(BPF_SRC)
	$(CLANG) $(CFLAGS) -target bpf -c $< -o $@

# Generate skel.h for userspace program
$(SKEL_HDR): $(BPF_OBJ)
	bpftool gen skeleton $< > $@

# Compile userspace program
$(USER_APP): $(USER_SRC) $(SKEL_HDR)
	$(CLANG) $(CFLAGS) $(USER_SRC) -o $@ $(LDFLAGS)

clean:
	rm -f $(BPF_OBJ) $(SKEL_HDR) $(USER_APP)
