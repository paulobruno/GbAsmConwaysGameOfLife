ASM		= rgbasm
LINKER	= rgblink
FIXER	= rgbfix
RM		= rm -rf

BUILD	= build
OBJDIR	= $(BUILD)/objs

NAME	= main
ROM		= $(NAME).gb
MAP		= $(NAME).map
SYMBOL	= $(NAME).sym

CFLAGS	= -E
LFLAGS	= -m $(MAP) -n $(SYMBOL)
FFLAGS	= -v -p 0


SOURCES = $(wildcard *.asm)
OBJECTS	= $(patsubst %.asm, $(OBJDIR)/%.o, $(SOURCES))


all: build $(ROM)

$(ROM): $(OBJECTS)
	$(LINKER) $(LFLAGS) -o $@ $^
	$(FIXER) $(FFLAGS) $@

$(OBJECTS): $(OBJDIR)/%.o : %.asm
	$(ASM) $(CFLAGS) -o $@ $<

build:
	mkdir -p $(OBJDIR)


.PHONY: clean cleanall

clean:
	$(RM) $(BUILD) *.o *~

cleanall:
	$(RM) $(EXEC) $(BUILD) *.o *~