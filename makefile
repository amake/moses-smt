SOURCE_LANG=ja
TARGET_LANG=en
PORT=8080

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

corpus: train-corpus tune-corpus

train: moses corpus
	docker build -t moses-trained --build-arg source=$(SOURCE_LANG) \
		--build-arg target=$(TARGET_LANG) .

run: train
	docker run -p $(PORT):8080 moses-trained

clean:
	rm -rf ./*-corpus env
