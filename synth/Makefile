SHELL:=bash
DESIGN:=mult
FREQ:=50

synth:
	@echo "DC Synthesis"
	@mkdir -p reports
	@mkdir -p mapped
	@mkdir -p unmapped
	export DESIGN=$(DESIGN); export FREQ=$(FREQ); dc_shell-xg-t -64bit -f scripts/synth.tcl | tee synth.out

clean:
	rm -rf  alib-52 WORK mapped unmapped reports analyzed synth.out
	rm -f default.svf
	rm -f command.log
	rm -f filenames*.log
	rm -f *.ptpx
