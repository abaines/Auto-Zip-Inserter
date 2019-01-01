# Alan Baines

import os.path
import os
import threading
import hashlib
import shutil
import winsound
import time
import glob
import re

# GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS 

# control.lua file
# used to determine root folder to watch
controlLuaFolder = "./saves/workingSquares/control.lua"

# zip to insert changes into
zipToInsertInto = r"C:\Users\baines\AppData\Roaming\Factorio\saves\workingSquares.zip"

# GLOBALS ^ GLOBALS ^ GLOBALS ^ GLOBALS ^ GLOBALS ^ GLOBALS ^ GLOBALS ^ GLOBALS 



# check that control is okay
controlLuaFolder = os.path.abspath(controlLuaFolder)

if not controlLuaFolder.endswith('control.lua'):
        raise Exception("Wrong file: " + controlLuaFolder)

if not os.path.isfile(controlLuaFolder):
	raise Exception("Not File: " + controlLuaFolder)

if not os.path.exists(controlLuaFolder):
        raise Exception("Could not find zip file: " + controlLuaFolder)


# check that zip is okay
zipToInsertInto = os.path.abspath(zipToInsertInto)

if not zipToInsertInto.endswith('.zip'):
        raise Exception("Wrong extension: " + zipToInsertInto)

if not os.path.isfile(zipToInsertInto):
	raise Exception("Not File: " + zipToInsertInto)

if not os.path.exists(zipToInsertInto):
        raise Exception("Could not find zip file: " + zipToInsertInto)

# internal global
rootFolderToMonitor = os.path.dirname(controlLuaFolder)

print(rootFolderToMonitor)
print(zipToInsertInto)


def lastModified(path):
	return os.path.getmtime(path)

def hashSha1(readFile):
	return hashlib.sha1(readFile).hexdigest()


def lastModifiedDictionary(rootFolder):
   rootFolder = os.path.abspath(rootFolder)
   retdict = {}

   for (dirpath, dirnames, filenames) in os.walk(rootFolder):
      for filename in filenames:
         fullname = os.path.join(dirpath,filename)
         
         if not os.path.exists(fullname):
            raise
         lastM = lastModified(fullname)
         retdict[fullname] = lastM
   
   return retdict

print()
lastModDict = lastModifiedDictionary(rootFolderToMonitor)
for key, value in lastModDict.items():
   if value<0:
      print(key)
   else:
      print(key,value)

