# Moses in Docker

Want to play with [Moses](http://www.statmt.org/moses/), the statistical machine
translation system, but...

- You don't have time to get a PhD in Setting Up Moses?

- You have TMX files (or structured bilingual text files easily convertible to
  TMX) and want to use them with Moses without doing all the munging yourself?

Well now you don't have to, because I stuffed Moses in a Docker container for
you.

# Requirements

- GNU make

- Docker

- OS X? (not tested elsewhere)

- Some TMX files ([Okapi](http://okapi.opentag.com/) Rainbow is a good tool for
  converting structured bilingual files to TMX)

# Usage

First, if using `docker-machine` you probably want to increase your default
machine's RAM and CPU cores, for instance to 4 GB and max available cores.

1. Put most of your TMXs in `train-tmx`, and the rest in `tune-tmx`.

2. Run `make SOURCE_LANG=<src> TARGET_LANG=<trg> [LABEL=<lbl>]`.

  - `src` and `trg` (required) are the language codes (*not* language + country)
    for your source and target languages, e.g. `en` and `fr`.

  - `lbl` is an optional label for the resulting image; `trained` by default.

3. Wait forever. The first time takes the longest as you will build and compile
the base `moses` image; this is reused across all trained images.

4. When done, you will have a Docker image tagged `moses-trained-<src>-<trg>`.

  - Run `make server SOURCE_LANG=<src> TARGET_LANG=<trg> [PORT=<port>]` to start
    [`mosesserver`](http://www.statmt.org/moses/?n=Advanced.Moses#ntoc1) which
    you can query over XML-RPC.

  - Optionally specify a port; the default is `8080`.

  - Use the `justRun` or `justServer` targets to make use of existing Docker
    images without going invoking training.

5. Train a new image with swapped languages or with a new set of TMXs.
