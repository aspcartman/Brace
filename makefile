all: clean
	/usr/local/bin/avra -o Brace.out Brace.asm
clean:
	rm -f *.cof *.hex *.obj *.tmp *.map *.aws *.bat *.lst
dude:
	avrdude -p m8 -c ftbb -P ft0 -U flash:w:./Brace.hex:a
