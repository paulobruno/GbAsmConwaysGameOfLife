ASM		= rgbasm
LINKER	= rgblink
FIXER	= rgbfix

BUILD	= build
OBJDIR	= $(BUILD)/objs
NAME	= main
RM		= rm -rf

CFLAGS	= -E
LFLAGS	= -m $(NAME).map -n $(NAME).sym
FFLAGS	= -v -p 0


SOURCES = $(wildcard *.asm)
OBJECTS	= $(patsubst %.asm, $(OBJDIR)/%.o, $(SOURCES))


all: build game_fix

game_fix: game
	$(FIXER) $(FFLAGS) $(NAME).gb

game: $(OBJECTS)
	$(LINKER) $(LFLAGS) -o $(NAME).gb $^

$(OBJECTS): $(OBJDIR)/%.o : %.asm
	$(ASM) $(CFLAGS) -o $@ $<


build:
	mkdir -p $(OBJDIR)


.PHONY: clean cleanall

clean:
	$(RM) $(BUILD) *.o *~

cleanall:
	$(RM) $(EXEC) $(BUILD) *.o *~