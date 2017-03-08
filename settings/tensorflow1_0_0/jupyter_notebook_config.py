import os
from IPython.lib import passwd

c = get_config()

if 'PASSWORD' in os.environ:
  c.NotebookApp.password = passwd(os.environ['PASSWORD'])
  del os.environ['PASSWORD']

#c.NotebookApp.password = u''
c.NotebookApp.ip = '*'
c.NotebookApp.open_browser = False
c.NotebookApp.notebook_dir = u'/home/DOCKERUSER/Workspace'
c.NotebookApp.keyfile = u'/home/DOCKERUSER/.jupyter/mycert.key'
c.NotebookApp.certfile = u'/home/DOCKERUSER/.jupyter/mycert.pem'
