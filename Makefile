PORT ?= 8080
LABEL ?= myinstance
TAG ?= moses-smt:$(LABEL)-$(SOURCE_LANG)-$(TARGET_LANG)
PUSH_TAG ?= $(TAG)
REPL_ARGS =

work_dir = work/$(LABEL)-$(SOURCE_LANG)-$(TARGET_LANG)
work_run = docker run --rm -it -v $(PWD)/work:/home/moses/work \
	-e WORK_HOME=/home/moses/$(work_dir) \
	-e SOURCE_LANG=$(SOURCE_LANG) \
	-e TARGET_LANG=$(TARGET_LANG) \
	-e TEST_MODE=$(TEST_MODE) \
	amake/moses-smt:base

required = $(if $($1), ,$(error Required parameter missing: $1))
checklangs = $(and $(call required,SOURCE_LANG),$(call required,TARGET_LANG))

.PHONY: all
all: ## Default tasks: build
all: build

.PHONY: build
build: ## Build a trained instance
build: $(work_dir)/binary/moses.ini
	$(call checklangs)
	tar -cf - Dockerfile $(work_dir)/{lm,binary} | docker build -t $(TAG) \
		--build-arg work_dir=$(work_dir) -

.PHONY: train
train: ## Train Moses on the provided data
train: $(work_dir)/binary/moses.ini

langs := $(SOURCE_LANG) $(TARGET_LANG)
train_bifiles := $(addprefix $(work_dir)/corpus-train/bitext.tok.,$(langs))
tune_bifiles := $(addprefix $(work_dir)/corpus-tune/bitext.tok.,$(langs))

$(work_dir)/train/model/moses.ini: $(train_bifiles)
	$(call checklangs)
	$(work_run) /home/moses/work/bin/train.sh

$(work_dir)/tune/mert-work/moses.ini: $(tune_bifiles) $(work_dir)/train/model/moses.ini
	$(call checklangs)
	$(work_run) /home/moses/work/bin/tune.sh

$(work_dir)/binary/moses.ini: $(work_dir)/tune/mert-work/moses.ini
	$(call checklangs)
	$(work_run) /home/moses/work/bin/binarize.sh

.PHONY: shrink
shrink: ## Remove training inputs to save disk space
shrink: SHELL = /bin/bash -O extglob
shrink:
	$(call checklangs)
	rm -rf $(work_dir)/corpus-*/!(bitext.tok.*)
	rm -rf $(work_dir)/train/{!(model),model/!(moses.ini)}
	rm -rf $(work_dir)/tune/{!(mert-work),mert-work/!(moses.ini)}

.PHONY: corpus
corpus: ## Create corpus from TMX files in ./tmx-{train,tune}
corpus: $(train_bifiles) $(tune_bifiles)

$(train_bifiles): | .env/bin/tmx2corpus
	$(call checklangs)
	mkdir -p $(@D)
	cd $(@D); $(PWD)/.env/bin/tmx2corpus -v $(PWD)/tmx-train

$(tune_bifiles): | .env/bin/tmx2corpus
	$(call checklangs)
	mkdir -p $(@D)
	cd $(@D); $(PWD)/.env/bin/tmx2corpus -v $(PWD)/tmx-tune

.PHONY: run
run: ## Test translate "foo" in trained instance
run:
	$(call checklangs)
	docker run --rm $(TAG) /bin/sh -c 'echo foo |\
		$$MOSES_HOME/bin/moses -f $$WORK_HOME/binary/moses.ini'

.PHONY: server
server: ## Launch a trained instance
server:
	$(call checklangs)
	docker run --rm -p $(PORT):8080 $(TAG)

.PHONY: repl
repl: ## Open a REPL to query a trained instance (launch with `make server`)
repl: | .env
	.env/bin/python ./mosesxmlrpcrepl.py $(REPL_ARGS)

.PHONY: shell
shell: ## Open a shell on a trained instance
shell:
	$(call checklangs)
	docker run --rm -ti $(TAG) /bin/bash

deploy.zip: $(work_dir)/binary/moses.ini
	$(call checklangs)
	if [ -f $@ ]; then rm $@; fi
	sed -i '.orig' "s|@DEFAULT_WORK_DIR@|$(work_dir)|" Dockerfile
	cp Dockerrun.aws{.noimage,}.json
	zip -r $@ Dockerfile Dockerrun.aws.json $(work_dir)/{binary,lm} \
		-x '*/.DS_Store'
	mv Dockerfile{.orig,}
	mv Dockerrun.aws{,.noimage}.json

push_tag_safe = $(subst /,_,$(subst :,_,$(subst \:,:,$(PUSH_TAG))))

.PHONY: deploy-hub
deploy-hub: push deploy-$(push_tag_safe).zip

.PHONY: deploy-hub-zip
deploy-hub-zip: deploy-$(push_tag_safe).zip
deploy-$(push_tag_safe).zip:
	$(call checklangs)
	if [ -f $@ ]; then rm $@; fi
	sed -e "s|@NAME@|$(PUSH_TAG)|" Dockerrun.aws.image.json > Dockerrun.aws.json
	zip $@ Dockerrun.aws.json
	rm Dockerrun.aws.json

.PHONY: push
push: ## Push trained container to Docker Hub
push:
	$(call checklangs)
	docker tag $(TAG) $(PUSH_TAG)
	docker push $(PUSH_TAG)

.env:
	virtualenv .env
	.env/bin/pip install tinysegmenter

.PHONY: tmx2corpus
tmx2corpus: .env/bin/tmx2corpus

.env/bin/tmx2corpus: | .env
	.env/bin/pip install git+https://github.com/amake/tmx2corpus.git

.PHONY: eb
eb: .env/bin/eb

.env/bin/eb: | .env
	.env/bin/pip install awsebcli

.PHONY: base
base: ## Build the base Moses container
base:
	cd base; docker build -t moses-smt:base .

.PHONY: clean
clean: ## Remove generated files
clean:
	rm -rf $(work_dir) .env

.PHONY: help
help: ## Show this help text
	$(info usage: make [target])
	$(info )
	$(info Available targets:)
	@awk -F ':.*?## *' '/^[^\t].+?:.*?##/ \
         {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
