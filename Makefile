#-*- mode: makefile; -*-

PERL_MODULES = \
    lib/BLM/Startup/Captcha.pm

VERSION := $(shell perl -I lib -MBLM::Startup::Captcha -e 'print $$BLM::Startup::Captcha::VERSION;')

TARBALL = BLM-Startup-Captcha-$(VERSION).tar.gz

$(TARBALL): buildspec.yml $(PERL_MODULES) requires test-requires README.md
	make-cpan-dist.pl -b $<

README.md: lib/BLM/Startup/Captcha.pm
	pod2markdown $< > $@

clean:
	rm -f *.tar.gz
