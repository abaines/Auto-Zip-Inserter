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
import zipfile

# GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS 

# control.lua file
# used to determine root folder to watch
controlLuaFolder = "./saves/workingSquares/control.lua"

# zip to insert changes into
zipToInsertInto = r"C:\Users\baines\AppData\Roaming\Factorio\saves\workingSquares.zip"

# how frequently to scan folders and files (in seconds)
scanDelay = 1.1

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





history = lastModifiedDictionary(rootFolderToMonitor)



def fileAdded(zipf,filename):
   print("added",filename)

def fileDeleted(zipf,filename):
   print("deleted",filename)

def fileModified(zipf,filename):
   print("modified",filename)




def checkAnyTypeOfChange(old,new,allkeys):
   oldkeys = old.keys()
   newkeys = new.keys()

   for key in allkeys:
      # check for new files
      if key not in oldkeys:
         return True
         
      # check for deleted files
      if key not in newkeys:
         return True

      # check for modified files
      if key in newkeys and key in oldkeys:
         oldModifiedDate = old[key]
         newModifiedDate = new[key]
         if oldModifiedDate != newModifiedDate:
            return True
   
   return False


def compareLastModDicts(old,new):
   oldkeys = old.keys()
   newkeys = new.keys()

   allkeys = list(set().union(oldkeys, newkeys))

   if not checkAnyTypeOfChange(old,new,allkeys):
      return

   print("one or more changes detected")

   with zipfile.ZipFile(zipToInsertInto,'a') as zipf:
      # zip open
      
      for key in allkeys:
         # check for new files
         if key not in oldkeys:
            fileAdded(zipf,key)
            
         # check for deleted files
         if key not in newkeys:
            fileDeleted(zipf,key)

         # check for modified files
         if key in newkeys and key in oldkeys:
            oldModifiedDate = old[key]
            newModifiedDate = new[key]
            if oldModifiedDate != newModifiedDate:
               fileModified(zipf,key)

   



def scan():
   global history
   print('.', end='', flush=True)
   
   newLMD = lastModifiedDictionary(rootFolderToMonitor)
   compareLastModDicts(history,newLMD)

   # update history with new last modified dictionary
   history = newLMD


def scanThreader():
   scan()   
   t = threading.Timer(scanDelay, scanThreader)
   t.start()

def startScanThreader():
   t = threading.Timer(scanDelay, scanThreader)
   t.start()

startScanThreader()
