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
import sys
import traceback

# GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS # GLOBALS 

SOURCE_FILE = "C:/Users/baines/AppData/Roaming/Factorio/saves/Paige2022Aug27-0017modstart/kizrak-ant-trails-pavement.lua"

DESTINATION_FILE = "C:/Users/baines/Documents/Python/Auto-Zip-Inserter/saves/kizrak's-ant-trails-pavement/kizrak-ant-trails-pavement.lua"

# how frequently to scan folders and files (in seconds)
scanDelay = 1.1

# GLOBALS ^ GLOBALS ^ GLOBALS ^ GLOBALS ^ GLOBALS ^ GLOBALS ^ GLOBALS ^ GLOBALS 




if not os.path.isfile(SOURCE_FILE):
	raise Exception("Not File: " + SOURCE_FILE)

if not os.path.isfile(DESTINATION_FILE):
	raise Exception("Not File: " + DESTINATION_FILE)


print(SOURCE_FILE,"▶",DESTINATION_FILE)

def lastModified(path):
	return os.path.getmtime(path)

def hashSha1(readFile):
	return hashlib.sha1(readFile).hexdigest()

def epoch():
   return time.time()


last_stamp = -1

def scan():
    global last_stamp

    stamp = lastModified(SOURCE_FILE)
    
    if last_stamp == stamp:
        print("👟"*8,stamp, "no change")

    else:
        # who doesn't love it when their computer beeps at them?
        winsound.Beep(120,60)

        last_stamp = stamp
        print("🏃"*8,stamp, "change")

        shutil.copy(SOURCE_FILE,DESTINATION_FILE)

        # Really!
        winsound.Beep(320,60)

   
def scanThreader():

   try:
      scan()
   except:
      exc_type, exc_value, exc_traceback = sys.exc_info()
      lines = traceback.format_exception(exc_type, exc_value, exc_traceback)
      print (''.join('!! ' + line for line in lines) ) # Log it or whatever here
     
   t = threading.Timer(scanDelay, scanThreader)
   t.start()

def startScanThreader():
   t = threading.Timer(scanDelay, scanThreader)
   t.start()

startScanThreader()





print("🔚 "*8, "End of file")

