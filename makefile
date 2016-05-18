PORT=8080
LABEL=trained
TAG=moses-$(LABEL)-$(SOURCE_LANG)-$(TARGET_LANG)
TEST_MODE=

.PHONY: run runExisting train langs moses clean

run: langs train
	docker run -p $(PORT):8080 $(TAG)

runExisting: langs
	docker run -p $(PORT):8080 $(TAG)

train: langs moses train-corpus tune-corpus
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

moses:
	docker build -t moses -f Dockerfile-base .

env:
	virtualenv env
	env/bin/pip install git+https://github.com/amake/tmx2corpus.git

train-corpus: env
	if [ ! -d train-corpus ]; then mkdir train-corpus; fi
	cd train-corpus; ../env/bin/tmx2corpus -v ../train-tmx

tune-corpus: env
	if [ ! -d tune-corpus ]; then mkdir tune-corpus; fi
	cd tune-corpus; ../env/bin/tmx2corpus -v ../tune-tmx

clean:
	rm -rf ./*-corpus env
