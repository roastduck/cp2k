#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, os
from os import path
from glob import glob

from subprocess import Popen, PIPE


#===============================================================================
def main():
	do_it = sys.argv[-1] == "doit!"

	n_submits = 0
	for d in glob("/mnt/ssd/rd/autotune/tune_*"):
		if(not path.isdir(d)):
			continue
		
		if(len(glob(d+"/*.log"))>0):
			print("%20s: Found log file(s)"%d)
			continue

		n_submits += 1
		if(do_it):
			print("%20s: Submitting"%d)
			assert(os.system("cd %s; bash *.job"%d)==0)
		else:
			print('%20s: Would submit, run with "doit!"'%d)

	print("Number of jobs submitted: %d"%n_submits)

#===============================================================================
if(len(sys.argv)==2 and sys.argv[-1]=="--selftest"):
    pass #TODO implement selftest
else:
    main()

#EOF
