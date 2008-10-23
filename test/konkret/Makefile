TARGET = libWidgetProvider.so

SOURCES = WidgetProvider.c GadgetProvider.c UpcallProvider.c

OBJECTS = $(SOURCES:.c=.o)

INCLUDES += -I/usr/include/cmpi

LIBRARIES += -lkonkret

FLAGS = -g -Wall -O2 -fPIC

all:
	echo $(OBJECTS)
	gcc $(FLAGS) -c $(INCLUDES) WidgetProvider.c
	gcc $(FLAGS) -c $(INCLUDES) GadgetProvider.c
	gcc $(FLAGS) -c $(INCLUDES) UpcallProvider.c
	gcc $(FLAGS) -shared -o $(TARGET) $(INCLUDES) $(OBJECTS) $(LIBRARIES)

clean:
	rm -rf $(TARGET)

gen:
	konkret -s KC_Upcall -s KC_Widget -s KC_Gadget -m Widget.mof KC_Widget=Widget KC_Gadget=Gadget KC_Upcall=Upcall

install:
	konkretreg $(TARGET) > Widget.reg
	su -c "make install-su"

install-su:
	cp $(TARGET) /usr/lib64
	cp Widget.mof /var/lib/sfcb/stage/mofs/root/cimv2
	cp Widget.mof /var/lib/sfcb/stage/mofs/root/interop
	cp Widget.reg /var/lib/sfcb/stage/regs
	sfcbrepos -f

reg:
	cp $(TARGET) $(PEGASUS_HOME)/lib
	cimmof Widget.mof
	cimmof -n root/PG_InterOp register.mof

