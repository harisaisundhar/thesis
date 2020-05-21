#1 /usr/bin/python

################################################################################
# git_wc_generator.py
# this script combines the warm cache csvs for each filesystem into a single csv

import argparse
import glob
import re

parser = argparse.ArgumentParser()
parser.add_argument("pathname")

args = parser.parse_args()

ram_pattern = re.compile("(768mb|1024mb|1280mb|1536mb|2048mb)")

wc_list = glob.glob("{}_hdd*".format(args.pathname))
fs_size = ["placeholder"]

results = []
results.append(["pulls"])
with open("ext4_hdd_gc_off_2048mb_warm_cacheresults.csv", "r") as ext4_file:
    ext4_lines = ext4_file.readlines()
    for i in range(1,len(ext4_lines)):
        results.append(["{}".format((i-1)*100)])
        fs_size.append(float(ext4_lines[i].split()[1]))

for wc_path in wc_list:
    with open(wc_path, "r") as wc_file:
        print(wc_path)
        ram_size = ram_pattern.search(wc_path).group(0)
        results[0].append("{}_time".format(ram_size))
        results[0].append("{}_layout".format(ram_size))
        wc_lines = wc_file.readlines()
        for i in range(1,len(wc_lines)):
            time = "{}".format(float(wc_lines[i].split()[2])*1024*1024/fs_size[i])
            layout = wc_lines[i].split()[3]
            results[i].append(time)
            results[i].append(layout)

with open("../camera_ready_git/git_{}_hdd_20gb_gc_offresults.csv".format(args.pathname)) as cold_file:
        results[0].append("cold_time")
        results[0].append("cold_layout")
        results[0].append("cold_clean_time")
        results[0].append("cold_clean_layout")
        cold_lines = cold_file.readlines()
        for i in range(1,len(cold_lines)):
            time = "{}".format(float(cold_lines[i].split()[2])*1024*1024/fs_size[i])
            clean_time = "{}".format(float(cold_lines[i].split()[4])*1024*1024/fs_size[i])
            layout = cold_lines[i].split()[3]
            clean_layout = cold_lines[i].split()[5]
            results[i].append(time)
            results[i].append(layout)
            results[i].append(clean_time)
            results[i].append(clean_layout)

with open("../camera_ready_git/git_{}_hdd_20gb_gc_offresults.csv".format("betrfs")) as betrfs_file:
        results[0].append("betrfs_time")
        results[0].append("betrfs_layout")
        betrfs_lines = betrfs_file.readlines()
        for i in range(1,len(betrfs_lines)):
            time = "{}".format(float(betrfs_lines[i].split()[2])*1024*1024/fs_size[i])
            layout = betrfs_lines[i].split()[3]
            results[i].append(time)
            results[i].append(layout)

with open("{}_warm_cache.csv".format(args.pathname), "w") as result_csv:
    result_csv.writelines("{}\n".format(' '.join(i)) for i in results)
