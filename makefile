PORT=8080
LABEL=trained
TAG=moses-smt:$(LABEL)-$(SOURCE_LANG)-$(TARGET_LANG)
HELLO_WORLD=/bin/sh -c 'echo foo |\
		$$MOSES_HOME/bin/moses -f $$WORK_HOME/binary/moses.ini'
TEST_MODE=

required=$(if $($1),,$(error Required parameter missing: $1))
checklangs=$(and $(call required,SOURCE_LANG),$(call required,TARGET_LANG))

.PHONY: run server shell train clean

train: train-corpus tune-corpus
	$(call checklangs)
	docker build -t $(TAG) \
		--build-arg source=$(SOURCE_LANG) \
		--build-arg target=$(TARGET_LANG) \
		--build-arg test=$(TEST_MODE) .

run:
	$(call checklangs)
	docker run $(TAG) $(HELLO_WORLD)

server:
	$(call checklangs)
	docker run -p $(PORT):8080 $(TAG)

shell:
	$(call checklangs)
	docker run -ti $(TAG) /bin/bash

deploy.zip: train-corpus tune-corpus
	$(call checklangs)
	if [ -f deploy.zip ]; then rm deploy.zip; fi
	sed -e "s/@DEFAULT_SRC_LANG@/$(SOURCE_LANG)/" \
		-e "s/@DEFAULT_TRG_LANG@/$(TARGET_LANG)/" Dockerfile > Dockerfile-deploy
	mv Dockerfile{,-tmp}
	mv Dockerfile{-deploy,}
	zip -r deploy Dockerfile Dockerrun.aws.json setup-bin *-corpus/bitext.tok.*\
		-x \*/.DS_Store
	rm Dockerfile
	mv Dockerfile{-tmp,}

env:
	LC_ALL=C virtualenv env

env/bin/tmx2corpus: env
	env/bin/pip install git+https://github.com/amake/tmx2corpus.git

env/bin/eb: env
	env/bin/pip install awsebcli

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
