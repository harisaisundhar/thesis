#! /usr/bin/python

################################################################################
# intra_layout.py
# this script fixes intra files for plotting

import argparse
import glob
import re

parser = argparse.ArgumentParser()
parser.add_argument("pathname")

args = parser.parse_args()

output_list = []

for j in range(0,11):
    with open("{}/layout_rr_{}".format(args.pathname, 10*j), "r") as inputfile:
        for i in range(0,10):
            output_list.append(open("{}/layout_rr_{}_{}".format(args.pathname, j*10, i), "w"))
            output_list[i].write("block round\n")

        inputlines = inputfile.readlines()
        for i in range(1,len(inputlines)):
            output_list[int(inputlines[i].split()[0])].write("{} {}\n".format(inputlines[i].split()[1], inputlines[i].split()[2]))
        for i in range(0,10):
            output_list[i].close()
        output_list = []
