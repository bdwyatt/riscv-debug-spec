CC=$(RISCV)/bin/riscv64-unknown-elf-gcc

DRAFT=riscv-debug-draft
RELEASE=riscv-debug-release
NOTES=riscv-debug-workgroup-notes

REGISTERS_TEX = jtag_registers.tex
REGISTERS_TEX += core_registers.tex
REGISTERS_TEX += hwbp_registers.tex
REGISTERS_TEX += dm_registers.tex
REGISTERS_TEX += sample_registers.tex
REGISTERS_TEX += abstract_commands.tex
REGISTERS_TEX += sw_registers.tex
REGISTERS_TEX += serial.tex

REGISTERS_CHISEL += dm_registers.scala
REGISTERS_CHISEL += abstract_commands.scala

INCLUDES_TEX = introduction.tex
INCLUDES_TEX += preface.tex
INCLUDES_TEX += preamble.tex
INCLUDES_TEX += overview.tex
INCLUDES_TEX += debug_module.tex
INCLUDES_TEX += core_debug.tex
INCLUDES_TEX += trigger.tex
INCLUDES_TEX += dtm.tex
INCLUDES_TEX += jtagdtm.tex
INCLUDES_TEX += implementations.tex
INCLUDES_TEX += debugger_implementation.tex
INCLUDES_TEX += riscv-debug-spec.tex
INCLUDES_TEX += future.tex

FIGURES = fig/*

all:	release $(NOTES).pdf debug_defines.h

draft:	$(DRAFT).pdf

release:	$(RELEASE).pdf

%.pdf: %.tex $(REGISTERS_TEX) $(FIGURES) $(INCLUDES_TEX) vc.tex changelog.tex
	pdflatex -shell-escape $< && makeindex $(basename $<) && pdflatex -shell-escape $<

publish:	$(DRAFT).pdf
	cp $< $(DRAFT)-`git rev-parse --abbrev-ref HEAD`.`git rev-parse --short HEAD`.pdf

vc.tex: .git/logs/HEAD
	# https://thorehusfeldt.net/2011/05/13/including-git-revision-identifiers-in-latex/
	echo "%%% This file is generated by Makefile." > vc.tex
	echo "%%% Do not edit this file!\n%%%" >> vc.tex
	git log -1 --format="format:\
	    \\gdef\\GITHash{%H}\
	    \\gdef\\GITAbrHash{%h}\
	    \\gdef\\GITAuthorDate{%ad}\
	    \\gdef\\GITAuthorName{%an}" >> vc.tex

changelog.tex: .git/logs/HEAD Makefile
	echo "%%% This file is generated by Makefile." > changelog.tex
	echo "%%% Do not edit this file!\n%%%" >> changelog.tex
	git log --no-merges --date=short --pretty="format:vhEntry{%h}{%ad}{%an}{%s}" | \
	    sed -e "s,\\\\,{\\\\textbackslash},g" -e "s,[_#^],\\\\&,g" -e s/^/\\\\/ >> changelog.tex

debug_defines.h:	$(REGISTERS_TEX:.tex=.h)
	cat $^ > $@

%.eps: %.dot
	dot -Teps $< -o $@

%.tex %.h: xml/%.xml registers.py
	./registers.py --custom --definitions $@.inc --cheader $(basename $@).h $< > $@


%.scala: xml/%.xml registers.py
	./registers.py --chisel $(basename $@).scala $< > /dev/null

%.o:	%.S
	$(CC) -c $<

chisel: $(REGISTERS_CHISEL)

clean:
	rm -f $(DRAFT).pdf *.aux $(DRAFT).toc $(DRAFT).log $(REGISTERS_TEX) \
	    $(REGISTERS_TEX:=.inc) *.o *_no128.S *.h $(DRAFT).lof $(DRAFT).lot $(DRAFT).out \
	    $(DRAFT).hst $(DRAFT).pyg debug_defines.h *.scala \
	    $(NOTES).pdf $(NOTES).toc $(NOTES).log $(NOTES).hst $(NOTES).pyg
