PORT=8080

.PHONY: run train langs moses clean

run: langs train
	docker run -p $(PORT):8080 moses-trained-$(SOURCE_LANG)-$(TARGET_LANG)

train: langs moses train-corpus tune-corpus
	docker build -t moses-trained-$(SOURCE_LANG)-$(TARGET_LANG) \
		--build-arg source=$(SOURCE_LANG) \
		--build-arg target=$(TARGET_LANG) .

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
