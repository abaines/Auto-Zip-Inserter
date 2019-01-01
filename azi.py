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
import datetime
import tempfile

# GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS 

# control.lua file
# used to determine root folder to watch
# factorio related code
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



# factorio related code
# internal global
zipControlLua = None
SLASH_CONTROL_LUA = "/control.lua"
with zipfile.ZipFile(zipToInsertInto,'r') as zipf:
   for info in zipf.infolist():
            filename = info.filename
            if filename.endswith(SLASH_CONTROL_LUA):
               print('filename      :',filename)
               if zipControlLua is None:
                  zipControlLua = filename
               elif len(filename)<len(zipControlLua):
                  zipControlLua = filename
print('zipControlLua :',zipControlLua)
# internal global
zipBaseFolder = zipControlLua[:-1*len(SLASH_CONTROL_LUA)]
print('zipBaseFolder :',zipBaseFolder)








history = lastModifiedDictionary(rootFolderToMonitor)

LEN_ROOT_FOLDER_NAME = 1+len(rootFolderToMonitor)

def fileAdded(zipf,filename):
   print("added",filename)

def fileDeleted(zipf,filename):
   print("deleted",filename)

def fileModified(zipf,filename):
   print("modified   :",filename)
   fileInsideZip = zipBaseFolder+'/'+filename[LEN_ROOT_FOLDER_NAME:]
   print("inside zip :",fileInsideZip)


   zipf.write(filename, fileInsideZip)





def checkAnyTypeOfChange(old,new,allkeys):
   oldkeys = old.keys()
   newkeys = new.keys()

   retlist = []

   for key in allkeys:
      # check for new files
      if key not in oldkeys:
         retlist.append(key[LEN_ROOT_FOLDER_NAME:])
         
      # check for deleted files
      if key not in newkeys:
         retlist.append(key[LEN_ROOT_FOLDER_NAME:])

      # check for modified files
      if key in newkeys and key in oldkeys:
         oldModifiedDate = old[key]
         newModifiedDate = new[key]
         if oldModifiedDate != newModifiedDate:
            retlist.append(key[LEN_ROOT_FOLDER_NAME:])
   
   return retlist



def remakeZipWithoutFilenames(zipname, filenames):
   # https://stackoverflow.com/a/25739108/1676197

   # generate a temp file
   tmpfd, tmpname = tempfile.mkstemp(dir=os.path.dirname(zipname))
   os.close(tmpfd)

   print(tmpfd, tmpname)

   # create a temp copy of the archive without filename            
   with zipfile.ZipFile(zipname, 'r') as zin:
      with zipfile.ZipFile(tmpname, 'w') as zout:
         zout.comment = zin.comment # preserve the comment
         for item in zin.infolist():
            itemfilename = item.filename
            if itemfilename not in filenames:
               zout.writestr(item, zin.read(itemfilename))
            else:
               print("skipping:",itemfilename)

   # replace with the temp archive
   os.remove(zipname)
   os.rename(tmpname, zipname)


def compareLastModDicts(old,new):
   oldkeys = old.keys()
   newkeys = new.keys()

   allkeys = list(set().union(oldkeys, newkeys))

   catoc = checkAnyTypeOfChange(old,new,allkeys)

   if len(catoc) is 0:
      return

   for idx, item in enumerate(catoc):
      catoc[idx] = zipBaseFolder+'/'+catoc[idx]

   print("one or more changes detected",catoc)

   remakeZipWithoutFilenames(zipToInsertInto,catoc)

   with zipfile.ZipFile(zipToInsertInto,'a', compression=ZipFile.ZIP_DEFLATED) as zipf:
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
