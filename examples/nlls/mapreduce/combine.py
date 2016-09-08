#!/usr/bin/env python
import sys

fdfda = fdfdb = 0
dfda2 = dfdb2 = dfdadb = 0

for line in sys.stdin:
    line = line.strip()
    key, pfdfda, pfdfdb, pdfda2, pdfdadb, pdfdb2 = line.split('\t')

    fdfda = fdfda + float(pfdfda)
    fdfdb = fdfdb + float(pfdfdb)
    dfda2 = dfda2 + float(pdfda2)
    dfdadb= dfdadb+ float(pdfdadb)
    dfdb2 = dfdb2 + float(pdfdb2)

key = "1" 
print '%s\t%f\t%f\t%f\t%f\t%f' % (key, fdfda, fdfdb, dfda2, dfdadb, dfdb2)
