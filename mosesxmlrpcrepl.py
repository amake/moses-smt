#!/usr/bin/env python

import sys
import xmlrpclib


def repl(server):
    try:
        while True:
            query = raw_input('Query: ')
            response = server.translate({'text': query})
            print response['text']
    except KeyboardInterrupt:
        print('Exiting')


def main():
    server = xmlrpclib.ServerProxy(sys.argv[1])
    repl(server)


if __name__ == '__main__':
    main()
