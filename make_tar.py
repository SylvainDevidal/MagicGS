#!python

import os
import re
import platform

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
os.makedirs(dir_name, exist_ok = True)

if platform.system() == 'Windows':
	os.system("xcopy /D *.nut " + dir_name);
	os.system("xcopy /D readme.txt " + dir_name);
	os.system("xcopy /D license.txt " + dir_name);
	os.system("xcopy /D changelog.txt " + dir_name);
	os.system("xcopy /D /E /S lang " + dir_name);
	os.system("tar -cf " + tar_name + " " + dir_name);
	os.system("rd /S /Q " + dir_name);
# POSIX
else:
	os.system("cp -u *.nut " + dir_name);
	os.system("cp -u readme.txt " + dir_name);
	os.system("cp -u license.txt " + dir_name);
	os.system("cp -u changelog.txt " + dir_name);
	os.system("cp -ur lang " + dir_name);
	os.system("tar -cf " + tar_name + " " + dir_name);
	os.system("rm -r " + dir_name)
