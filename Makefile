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


.PHONY: all clean cleanall

all: $(ROM)


$(ROM): $(OBJECTS)
	$(LINKER) $(LFLAGS) -o $@ $^
	$(FIXER) $(FFLAGS) $@

$(OBJECTS): $(OBJDIR)/%.o : %.asm | $(OBJDIR)
	$(ASM) $(CFLAGS) -o $@ $<

$(OBJDIR):
	@mkdir -p $(OBJDIR)


clean:
	@$(RM) $(BUILD) *.o *~

cleanall:
	@$(RM) $(EXEC) $(BUILD) *.o *~