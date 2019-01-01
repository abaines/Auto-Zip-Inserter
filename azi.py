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



# folder to monitor for changes
rootOfFolderToWatch = ""

# extensions to monitor and insert
extensionsList = [".lua"]

# zip to insert changes into
zipToInsertInto = ""





def lastModified(path):
	return os.path.getmtime(path)

def hashSha1(readFile):
	return hashlib.sha1(readFile).hexdigest()




