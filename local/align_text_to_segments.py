#!/usr/bin/python

import sys, getopt

def main(argv):
   inputfile = ''
   outputfile = ''
   try:
      opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
   except getopt.GetoptError:
      print 'test.py -i <inputfile> -o <outputfile>'
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print 'test.py -i <inputfile> -o <outputfile>'
         sys.exit()
      elif opt in ("-i", "--ifile"):
         inputfile = arg
      elif opt in ("-o", "--ofile"):
         outputfile = arg
#   print 'Input file is "', inputfile
#   print 'Output file is "', outputfile
   
   with open(inputfile) as f:
      for line in f:
          words = line.split()
      	  #print len(words)
	  for i in range(1,len(words),3):
	      #print words[i]
	      if (i == 1):
		 temp = 0
		 #print words[0]," ",words[0] + "_" + 
	      else:
	         temp = temp + int(words[i-2])
	      
	      if (words[i] != "0"):
	          print words[0]," ",words[0]," ",0.01*temp, " ",(int(words[i+1]) + temp)*0.01
		  
            

if __name__ == "__main__":
   main(sys.argv[1:])
#   with open(inputfile) as f:
#	content = f.readlines()
#	print content
