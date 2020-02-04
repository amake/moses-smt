PORT ?= 8080
LABEL ?= myinstance
TAG ?= moses-smt:$(LABEL)-$(SOURCE_LANG)-$(TARGET_LANG)
PUSH_TAG ?= $(TAG)
REPL_ARGS =

root_dir = $(shell pwd)
work_dir = work/$(LABEL)-$(SOURCE_LANG)-$(TARGET_LANG)
work_run = docker run --rm -it -v $(root_dir)/work:/home/moses/work \
	-e WORK_HOME=/home/moses/$(work_dir) \
	-e SOURCE_LANG=$(SOURCE_LANG) \
	-e TARGET_LANG=$(TARGET_LANG) \
	-e TEST_MODE=$(TEST_MODE) \
	amake/moses-smt:base

required = $(if $($1), ,$(error Required parameter missing: $1))
checklangs = $(and $(call required,SOURCE_LANG),$(call required,TARGET_LANG))


.PHONY: all build train run server shell base corpus tmx2corpus eb clean deploy-hub \
	deploy-hub-zip push repl

all: build

build: $(work_dir)/binary/moses.ini
	$(call checklangs)
	tar -cf - Dockerfile $(work_dir)/{lm,binary} | docker build -t $(TAG) \
		--build-arg work_dir=$(work_dir) -

train: $(work_dir)/binary/moses.ini

$(work_dir)/train/model/moses.ini: $(work_dir)/corpus-train/bitext.tok.*
	$(call checklangs)
	$(work_run) /home/moses/work/bin/train.sh

$(work_dir)/tune/mert-work/moses.ini: $(work_dir)/corpus-tune/bitext.tok.* \
		$(work_dir)/train/model/moses.ini
	$(call checklangs)
	$(work_run) /home/moses/work/bin/tune.sh

$(work_dir)/binary/moses.ini: $(work_dir)/tune/mert-work/moses.ini
	$(call checklangs)
	$(work_run) /home/moses/work/bin/binarize.sh

shrink: SHELL = /bin/bash -O extglob
shrink:
	$(call checklangs)
	rm -rf $(work_dir)/corpus-*/!(bitext.tok.*)
	rm -rf $(work_dir)/train/{!(model),model/!(moses.ini)}
	rm -rf $(work_dir)/tune/{!(mert-work),mert-work/!(moses.ini)}

corpus: corpus-train/bitext.tok.* corpus-tune/bitext.tok.*

$(work_dir)/corpus-%/bitext.tok.*: corpus-%/bitext.tok.*
	$(call checklangs)
	mkdir -p $(work_dir)/corpus-$*
	cp corpus-$*/bitext.tok.* $(work_dir)/corpus-$*/

corpus-%/bitext.tok.*: | .env/bin/tmx2corpus
	$(call checklangs)
	mkdir -p corpus-$*
	cd corpus-$*; .env/bin/tmx2corpus -v $(root_dir)/tmx-$*

run:
	$(call checklangs)
	docker run --rm $(TAG) /bin/sh -c 'echo foo |\
		$$MOSES_HOME/bin/moses -f $$WORK_HOME/binary/moses.ini'

server:
	$(call checklangs)
	docker run --rm -p $(PORT):8080 $(TAG)

repl: | .env
	.env/bin/python ./mosesxmlrpcrepl.py $(REPL_ARGS)

shell:
	$(call checklangs)
	docker run --rm -ti $(TAG) /bin/bash

deploy.zip: $(work_dir)/binary/moses.ini
	$(call checklangs)
	if [ -f $@ ]; then rm $@; fi
	mv Dockerfile{,.orig}
	sed -e "s|@DEFAULT_WORK_DIR@|$(work_dir)|" Dockerfile.orig > Dockerfile
	cp Dockerrun.aws{.noimage,}.json
	zip -r $@ Dockerfile Dockerrun.aws.json $(work_dir)/{binary,lm} \
		-x \*/.DS_Store
	mv Dockerfile{.orig,}
	mv Dockerrun.aws{,.noimage}.json

push_tag_safe = $(subst /,_,$(subst :,_,$(subst \:,:,$(PUSH_TAG))))

deploy-hub: push deploy-$(push_tag_safe).zip

deploy-hub-zip: deploy-$(push_tag_safe).zip
deploy-$(push_tag_safe).zip:
	$(call checklangs)
	if [ -f $@ ]; then rm $@; fi
	sed -e "s|@NAME@|$(PUSH_TAG)|" Dockerrun.aws.image.json > Dockerrun.aws.json
	zip $@ Dockerrun.aws.json
	rm Dockerrun.aws.json

push:
	$(call checklangs)
	docker tag $(TAG) $(PUSH_TAG)
	docker push $(PUSH_TAG)

.env:
	virtualenv .env
	.env/bin/pip install tinysegmenter

tmx2corpus: .env/bin/tmx2corpus

.env/bin/tmx2corpus: | .env
	.env/bin/pip install git+https://github.com/amake/tmx2corpus.git

eb: .env/bin/eb

.env/bin/eb: | .env
	.env/bin/pip install awsebcli

base:
	cd base; docker build -t moses-smt:base .

clean:
	rm -rf $(work_dir) .env
