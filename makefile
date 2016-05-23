PORT=8080
LABEL=trained
TAG=moses-smt:$(LABEL)-$(SOURCE_LANG)-$(TARGET_LANG)
HELLO_WORLD=/bin/sh -c 'echo foo |\
		$$MOSES_HOME/bin/moses -f $$WORK_HOME/binary/moses.ini'
TEST_MODE=

.PHONY: run justRun server justServer shell justShell train langs clean

run: langs train
	docker run $(TAG) $(HELLO_WORLD)

justRun: langs
	docker run $(TAG) $(HELLO_WORLD)

server: langs train
	docker run -p $(PORT):8080 $(TAG)

justServer: langs
	docker run -p $(PORT):8080 $(TAG)

shell: langs train
	docker run -ti $(TAG) /bin/bash

justShell: langs
	docker run -ti $(TAG) /bin/bash

train: langs train-corpus tune-corpus
	docker build -t $(TAG) \
		--build-arg source=$(SOURCE_LANG) \
		--build-arg target=$(TARGET_LANG) \
		--build-arg test=$(TEST_MODE) .

langs:
ifndef SOURCE_LANG
	echo "You must provide the source language as SOURCE_LANG=<lang code>"
	exit 1
endif
ifndef TARGET_LANG
	echo "You must provide the source language as SOURCE_LANG=<lang code>"
	exit 1
endif
ifeq ($(SOURCE_LANG),$(TARGET_LANG))
	echo "The source and target languages can't be identical"
	exit 1
endif

env:
	LC_ALL=C virtualenv env

env/bin/tmx2corpus: env
	env/bin/pip install git+https://github.com/amake/tmx2corpus.git

train-corpus: env/bin/tmx2corpus
	if [ ! -d train-corpus ]; then mkdir train-corpus; fi
	cd train-corpus; ../env/bin/tmx2corpus -v ../train-tmx
	touch train-corpus

tune-corpus: env/bin/tmx2corpus
	if [ ! -d tune-corpus ]; then mkdir tune-corpus; fi
	cd tune-corpus; ../env/bin/tmx2corpus -v ../tune-tmx
	touch tune-corpus

clean:
	rm -rf ./*-corpus env
