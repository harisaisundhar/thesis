#! /usr/bin/python

################################################################################
# mb_csv_generator.py
# this script combines multiple microbenchmark csvs into the master csv for the
# paper

import argparse
import glob
import re

intra_fs_size = 4096*100*10
inter_fs_size = 24308*1024 # size of tensorflow with all files 4kb
inter_rounds = 101

parser = argparse.ArgumentParser()
parser.add_argument("pathname")

args = parser.parse_args()

fs_pattern = re.compile("(ext4|xfs|btrfs|zfs|f2fs|betrfs)")

intra = []
intra.append(["round"])
for i in range(0,101):
    intra.append(["{}".format(i)])
inter = []
inter.append(["round"])
for i in range(0,inter_rounds+1):
    inter.append(["{}".format(i)])

mb_list = glob.glob("*_{}".format(args.pathname))

print "\n".join(mb_list)

for mb_dirname in mb_list:
    this_intra_path = glob.glob("{}/*_rr_results.csv".format(mb_dirname))[0]
    #this_inter_path = glob.glob("{}/*_rlt_results.csv".format(mb_dirname))[0]
    with open(this_intra_path, "r") as this_intra_file:
        this_intra = this_intra_file.readlines()
    #with open(this_inter_path, "r") as this_inter_file:
    #    this_inter = this_inter_file.readlines()
    fs_name = fs_pattern.match(this_intra_path).group(0)

    intra[0].append("{}_time".format(fs_name))
    #intra[0].append("{}_layout".format(fs_name))

    for i in range(1,len(this_intra)):
        time = "{}".format(float(this_intra[i].split()[1])*1024*1024*1024/intra_fs_size)
        #layout = this_intra[i].split()[3]
        intra[i].append(time)
        #intra[i].append(layout)

#    inter[0].append("{}_time".format(fs_name))
#    #inter[0].append("{}_layout".format(fs_name))
#
#    for i in range(1,len(this_inter)):
#        time = "{}".format(float(this_inter[i].split()[0])*1024*1024*1024/inter_fs_size)
#        #layout = this_inter[i].split()[1]
#        inter[i].append(time)
#        #inter[i].append(layout)

with open("intra_{}.csv".format(args.pathname), "w") as intra_csv:
    intra_csv.writelines("{}\n".format(' '.join(i)) for i in intra)

#with open("inter_{}.csv".format(args.pathname), "w") as inter_csv:
#    inter_csv.writelines("{}\n".format(' '.join(i)) for i in inter)


        
    

    
        
