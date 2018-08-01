#!/usr/bin/env python

import argparse
import logging
import re
import sys
import tinysegmenter

try:
    import xmlrpclib
except ModuleNotFoundError:
    import xmlrpc.client as xmlrpclib

try:
    from HTMLParser import HTMLParser
    unescape = HTMLParser().unescape
except ModuleNotFoundError:
    import html
    unescape = html.unescape

try:
    input = raw_input
except NameError:
    pass

cjk_spaces = re.compile(
    br'(?<=[\u3001-\u9fa0])\s+(?=[\u3001-\u9fa0])'.decode('raw_unicode_escape'))


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
        try:
            return raw_input('Query: ').decode('utf-8')
        except NameError:
            return input('Query: ')

    def evaluate(self, inpt):
        raise NotImplementedError


class MosesRepl(XmlRpcRepl):
    def __init__(self, *args, **kwargs):
        super(MosesRepl, self).__init__(*args, **kwargs)
        self.ts = tinysegmenter.TinySegmenter()

    def evaluate(self, inpt):
        query = inpt
        if not self.raw:
            query = query.encode('utf-8').decode('unicode_escape')
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
            response_text = unescape(response_text)
            if self.clean:
                logging.debug("Raw response: %s", response_text)
                response_text = self.clean_response(response_text)
        return response_text

    def clean_response(self, text):
        return cjk_spaces.sub('', text)


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

    url = args.url or input('URL: ')
    MosesRepl(url, raw=args.raw, clean=args.clean).go()


if __name__ == '__main__':
    main()
