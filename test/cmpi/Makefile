TARGET = libThingProvider.so

SOURCES = ThingProvider.c

OBJECTS = $(SOURCES:.c=.o)

INCLUDES += -I/usr/include/cmpi

#LIBRARIES += -lkonkret

FLAGS = -g -Wall -O2 -fPIC

all:
	echo $(OBJECTS)
	gcc $(FLAGS) -c $(INCLUDES) ThingProvider.c
	gcc $(FLAGS) -shared -o $(TARGET) $(INCLUDES) $(OBJECTS) $(LIBRARIES)

clean:
	rm -rf $(TARGET)

install:
	su -c "make install-su"

install-su:
	cp $(TARGET) /usr/lib64
	cp Thing.mof /var/lib/sfcb/stage/mofs/root/cimv2
	cp Thing.mof /var/lib/sfcb/stage/mofs/root/interop
	cp Thing.reg /var/lib/sfcb/stage/regs
	sfcbrepos -f
