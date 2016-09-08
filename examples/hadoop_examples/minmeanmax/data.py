#!/usr/bin/env python
"""
Generates data for linear regression example.

Usage: data.py --npts=Npts
"""
import sys
import getopt
import random

class Usage(Exception):
    def __init__(self, msg):
        self.msg = msg

def main(argv=None):
    n = 1000000
    if argv is None:
        argv = sys.argv
    try:
        try:
            opts, args = getopt.getopt(argv[1:], "hn:", ["help","npts="])
        except getopt.error, msg:
            raise Usage(msg)
        for o, a in opts:
            if o in ("-h","--help"):
                print "Usage: data.py --npts=Npts"
                return 2
            if o in ("-n","--npts"):
                n = int(a)
            else:
                raise Usage()

        for i in range(n):
            print random.normalvariate(0,0.5)

    except Usage, err:
        print >>sys.stderr, err.msg
        print >>sys.stderr, "for help use --help"
        return 2

if __name__ == "__main__":
    sys.exit(main())
