
import re
import zipfile
import os
import ntpath
from zipfile import ZipFile
import json
import requests
import shutil

addon_name = 'Icecreamer'
project_id = 352495

toc_file_handle = open(addon_name + '.toc', 'r')
toc_file_contents = toc_file_handle.read()
regex = re.compile(r'##\s+Version:\s+([.\d]+)', re.M|re.I)
result = re.findall(regex, toc_file_contents)
version = result[0]
zip_file_name = addon_name + '-v' + version + '.zip'

path = os.getcwd()

files = []
# r=root, d=directories, f = files
for r, d, f in os.walk(path):
    for file in f:
        if '.lua' in file or '.toc' in file:
            files.append(os.path.join(r, file))

if os.path.isfile(zip_file_name):
    os.remove(zip_file_name)

if os.path.isdir(addon_name):
    shutil.rmtree(addon_name)

zip_file = ZipFile(zip_file_name, 'w', zipfile.ZIP_DEFLATED)
for f in files:
    file_name = f.replace(path + '/', '')
    print(f, file_name)
    zip_file.write(f, addon_name + '/' + file_name)
zip_file.close()
#exit()

release_data = {
#    'fileID': 2832719,
    'changelog': 
"""
* Added /ict chat command that opens trade frame on targeted player and puts ice cream in the first slot
* Fixed some bugs
""",
    'changelogType': 'markdown',
    'releaseType': 'release',
    'gameVersions': [7350]
}

headers = {
    'X-Api-Token': 'ce273303-fba3-4a64-b910-e537898e4f13',
}

data = {
    'metadata': json.dumps(release_data),
}
files = {
    'file': open(zip_file_name, 'rb')
}

r = requests.post('https://wow.curseforge.com/api/projects/' + project_id + '/upload-file', headers=headers, data=data, files=files)
#r = requests.post('https://wow.curseforge.com/api/projects/352495/update-file', headers=headers, data=data, files=files)

print(r.content)