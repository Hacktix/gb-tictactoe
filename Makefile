NAME = TICTACTOE
PADVAL = 0

RGBASM = rgbasm
RGBLINK = rgblink
RGBFIX = rgbfix

RM_F = rm -f

ASFLAGS = -h
LDFLAGS = -t -w -n tictactoe.sym
FIXFLAGS = -v -p $(PADVAL) -t $(NAME) -c

tictactoe.gb: tictactoe.o
	$(RGBLINK) $(LDFLAGS) -o $@ $^
	$(RGBFIX) $(FIXFLAGS) $@

tictactoe.o: src/main.asm
	$(RGBASM) $(ASFLAGS) -o $@ $<

.PHONY: clean
clean:
	$(RM_F) tictactoe.o tictactoe.gb