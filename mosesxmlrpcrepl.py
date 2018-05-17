#!/usr/bin/env python

import argparse
import logging
import re
import sys
import xmlrpclib
import tinysegmenter


class XmlRpcRepl(object):
    def __init__(self, url):
        self.url = url
        self.server = xmlrpclib.ServerProxy(url)

    def go(self):
        try:
            while True:
                print(self.evaluate(self.read()))
        except KeyboardInterrupt:
            print('Exiting')

    def read(self):
        return raw_input('Query: ').decode('utf-8')

    def evaluate(self, inpt):
        raise NotImplementedError


class MosesRepl(XmlRpcRepl):
    def __init__(self, *args, **kwargs):
        super(MosesRepl, self).__init__(*args, **kwargs)
        self.ts = tinysegmenter.TinySegmenter()

    def evaluate(self, inpt):
        cleaned = self.clean_input(inpt)
        logging.debug("Cleaned input: %s", cleaned)
        return self.do_query(cleaned)

    def clean_input(self, text):
        return ' '.join(self.ts.tokenize(text))

    def do_query(self, query):
        response = self.server.translate({'text': query})
        logging.debug("Raw response: %s", response)
        return self.clean_response(response['text'])

    def clean_response(self, text):
        return re.sub(ur'(?<=[\u3001-\u9fa0])\s+(?=[\u3001-\u9fa0])', '', text)


def main():
    parser = argparse.ArgumentParser(
        description='Interactively query a Moses server')
    parser.add_argument('--verbose', '-v', action='count', default=0)
    parser.add_argument('url', nargs='?')
    args = parser.parse_args()

    levels = [logging.WARNING, logging.INFO, logging.DEBUG]
    level = levels[min(len(levels) - 1, args.verbose)]
    logging.basicConfig(level=level)

    url = args.url or raw_input('URL: ')
    MosesRepl(url).go()


if __name__ == '__main__':
    main()
