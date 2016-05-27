# Dock You a Moses

Want to play with the [Moses](http://www.statmt.org/moses/) Statistical Machine
Translation system, but...

- You don't have time to get a PhD in Setting Up Moses?

- You have TMX files (or structured bilingual text files easily convertible to
  TMX) and want to use them with Moses without doing all the munging yourself?

Well now you don't have to, because I stuffed Moses in a Docker container for
you.

# What is this?

- A full Moses + MGIZA installation in a Docker image: `amake/moses-smt:base` on
[Docker Hub](https://hub.docker.com/r/amake/moses-smt/)

- A [`make`](https://www.gnu.org/software/make/)-based set of commands for
  easily

  - Converting TMX files into Moses-ready corpus files: `make corpus`

  - Training and tuning Moses: `make train`

  - Building Docker images of trained Moses instances: `make build`

  - Deploying trained Moses instances to Docker Hub/Amazon Elastic Beanstalk:
    `make deploy-hub`

- Some peripheral tools:

  - A simple REPL for querying Moses over XML-RPC: `mosesxmlrpcrepl.py` or `make
    repl`

# Requirements

- GNU make

- Docker

- Python 2.7 with pip and virtualenv

- OS X? (not tested elsewhere)

- Some TMX files ([Okapi](http://okapi.opentag.com/) Rainbow is a good tool for
  converting structured bilingual files to TMX)

# Usage

First, if using `docker-machine` you probably want to increase your default
machine's RAM and CPU cores, for instance to 4 GB and max available cores.

1. Put most of your TMXs in `tmx-train`, and the rest in `tmx-tune`.

2. Run `make SOURCE_LANG=<src> TARGET_LANG=<trg> [LABEL=<lbl>]`.

  - `src` and `trg` (required) are the language codes (*not* language + country)
    for your source and target languages, e.g. `en` and `fr`.

  - `lbl` is an optional label for the resulting image; `myinstance` by default.

3. Wait forever.

4. When done, you will have a Docker image tagged `moses-smt:<lbl>-<src>-<trg>`.

  - Run `make server SOURCE_LANG=<src> TARGET_LANG=<trg> [PORT=<port>]` to start
    [`mosesserver`](http://www.statmt.org/moses/?n=Advanced.Moses#ntoc1) which
    you can query over XML-RPC.

  - Optionally specify a port; the default is `8080`.

## What then?

- Train a new image with swapped languages or with a new set of TMXs.

- Use a trained instance for translation in OmegaT with the [omegat-moses-mt
  plugin](https://github.com/amake/omegat-moses-mt):

  - Run `make server` to run the server locally; the `moses.server.url` value is
    then `http://$(docker-machine ip)/RPC2`

  - Run `make deploy-hub` and then upload the .zip that's produced as a new EB
    environment
