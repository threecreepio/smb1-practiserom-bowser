AS = ca65
CC = cc65
LD = ld65
IPS = flips

.PHONY: clean
build: practiserom.zip

%.o: %.asm
	$(AS) --create-dep "$@.dep" --listing "$@.lst" -g --debug-info $< -o $@

practiserom.zip: patch.ips
	zip $@ patch.ips README.md

patch.ips: main.nes
	$(IPS) --create --ips "original.nes" "main.nes" "patch.ips"

main.nes: layout-mmc1 title/boot-mmc1.o smb.o
	$(LD)  --dbgfile "$@.dbg" -C $^ -o $@

clean:
	rm -f ./main*.nes ./*.nes.dbg ./*.o.lst ./*.o ./*.dep ./*/*.o ./*/*.dep *.ips *.zip

include $(wildcard ./*.dep ./*/*.dep)
