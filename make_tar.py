#!python

import os
import re

# ----------------------------------
# Definitions:
# ----------------------------------

# Game Script name
gs_name = "MagicGS"
gs_pack_name = gs_name.replace(" ", "-")

# ----------------------------------


# Script:
version = -1
for line in open("version.nut"):

	r = re.search('SELF_VERSION\s+<-\s+([0-9]+)', line)
	if(r != None):
		version = r.group(1)

if(version == -1):
	print("Couldn't find " + gs_name + " version in info.nut!")
	exit(-1)

dir_name = gs_pack_name + "-v" + version
tar_name = dir_name + ".tar"
os.system("mkdir " + dir_name);
os.system("xcopy /C /Y *.nut " + dir_name);
os.system("xcopy /C /Y readme.txt " + dir_name);
os.system("xcopy /C /Y license.txt " + dir_name);
os.system("xcopy /C /Y changelog.txt " + dir_name);
os.system("xcopy /E /C /Y lang " + dir_name);
os.system("tar -cf " + tar_name + " " + dir_name);
os.system("rd /S /Q " + dir_name);
