#!/usr/bin/env python

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
        return self.do_query(self.clean_input(inpt))

    def clean_input(self, text):
        return ' '.join(self.ts.tokenize(text))

    def do_query(self, query):
        response = self.server.translate({'text': query})
        return self.clean_response(response['text'])

    def clean_response(self, text):
        return re.sub(ur'(?<=[\u3001-\u9fa0])\s+(?=[\u3001-\u9fa0])', '', text)


def main():
    url = sys.argv[1] if len(sys.argv) > 1 else raw_input('URL: ')
    MosesRepl(url).go()


if __name__ == '__main__':
    main()
