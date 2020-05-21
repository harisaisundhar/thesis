import argparse
import numpy
import math
import subprocess
import shlex
from scipy.stats import norm

balls_per_page = 16*1024/75

def pareto(a, x):
    return 1.0 - math.pow(1.0/x, a)

def min_value(dist_type):
    if dist_type == "uniform":
        return 0.0
    elif dist_type == "pareto":
        return 1.0
    elif dist_type == "normal":
        return float('-inf')
    else:
        print("invalid distribution type")
        sys.exit(1)

def max_value(dist_type):
    if dist_type == "uniform":
        return 1000000
    elif dist_type == "pareto":
        return float('inf')
    elif dist_type == "normal":
        return float('inf')
    else:
        print("invalid distribution type")
        sys.exit(1)

def cdf(dist_type, dist_param, value):
    if dist_type == "uniform":
        return value/1000000
    elif dist_type == "pareto":
        return pareto(dist_param, value)
    elif dist_type == "normal":
        return norm.cdf(value, scale=dist_param)
    else:
        print("invalid distribution type")
        sys.exit(1)

parser = argparse.ArgumentParser()
parser.add_argument('strategy')
parser.add_argument('dist_type')
parser.add_argument('dist_param', type=float)
parser.add_argument('data_dir')

args = parser.parse_args()

treefilename = "{}/tree_data.txt".format(args.data_dir)
outputfilename = "{}/output.txt".format(args.data_dir)
resultfilename = "innodb/{}_{}_{}.csv".format(args.strategy, args.dist_type, args.dist_param)

with open(treefilename, "r") as treefile:
    treelines = treefile.readlines()

with open(outputfilename, "r") as outputfile:
    outputlines = outputfile.readlines()

resultfile = open(resultfilename, "w")

resultfile.write("insertions,bins,balls,alpha,perc,observed,lower bound,upper bound\n")

k = 0

for line in treelines:
    minkeys = line.split()
    key = min_value(args.dist_type)
    newkey = float(minkeys[1])
    binweights = [cdf(args.dist_type, args.dist_param, newkey) - cdf(args.dist_type, args.dist_param, key)]
    i = 2
    while i < len(minkeys):
        key = newkey
        newkey = float(minkeys[i])
        binweights.append(cdf(args.dist_type, args.dist_param, newkey) - cdf(args.dist_type, args.dist_param, key))
        i = i + 1
    
    binweights.append(cdf(args.dist_type, args.dist_param, max_value(args.dist_type)) - cdf(args.dist_type, args.dist_param, newkey))

    insertions = float(outputlines[k].split(',')[1])/1000000.0
    bins = len(minkeys)
    balls = int(outputlines[k].split(',')[4]) / pow(2,14) * balls_per_page #16*1024*1024*.50 / pow(2,14) * balls_per_page
    alpha = max(binweights) * float(bins)
    perc = numpy.percentile(binweights,95) * float(bins)
    observed = 0
    if k != 0 and int(outputlines[k].split(',')[2]) - int(outputlines[k-1].split(',')[2]) != 0:
        observed = (float(outputlines[k].split(',')[3]) - float(outputlines[k-1].split(',')[3]))/(float(outputlines[k].split(',')[2]) - float(outputlines[k-1].split(',')[2]))
    pnorm = pow(sum(map(math.sqrt,binweights)),2)
    lowerbound = float(balls)/pnorm
    upperbound = alpha*(2*balls/bins + 1)

    resultfile.write("{},{},{},{},{},{},{},{}\n".format(insertions, bins, balls, alpha, perc, observed, lowerbound, upperbound))


    k = k + 1

treefile.close()
outputfile.close()
resultfile.close()
