#!/usr/bin/env python

import argparse
import logging
import re
import sys
import xmlrpclib
import tinysegmenter
from HTMLParser import HTMLParser

html_parser = HTMLParser()


class XmlRpcRepl(object):
    def __init__(self, url, raw=False, clean=True):
        self.url = url
        self.raw = raw
        self.clean = clean
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
        query = inpt
        if not self.raw:
            query = query.decode('string_escape')
            if self.clean:
                query = self.clean_input(inpt)
                logging.debug("Cleaned input: %s", query)
        return self.do_query(query)

    def clean_input(self, text):
        return ' '.join(self.ts.tokenize(text))

    def do_query(self, query):
        response = self.server.translate({'text': query})
        response_text = response['text']
        if not self.raw:
            response_text = html_parser.unescape(response_text)
            if self.clean:
                logging.debug("Raw response: %s", response_text)
                response_text = self.clean_response(response_text)
        return response_text

    def clean_response(self, text):
        return re.sub(ur'(?<=[\u3001-\u9fa0])\s+(?=[\u3001-\u9fa0])', '', text)


def main():
    parser = argparse.ArgumentParser(
        description='Interactively query a Moses server')
    parser.add_argument('--verbose', '-v', action='count', default=0)
    parser.add_argument('--raw', action='store_true')
    parser.add_argument('--no-clean', action='store_false', dest='clean')
    parser.add_argument('url', nargs='?')
    args = parser.parse_args()

    levels = [logging.WARNING, logging.INFO, logging.DEBUG]
    level = levels[min(len(levels) - 1, args.verbose)]
    logging.basicConfig(level=level)

    url = args.url or raw_input('URL: ')
    MosesRepl(url, raw=args.raw, clean=args.clean).go()


if __name__ == '__main__':
    main()
