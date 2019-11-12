from setuptools import setup
import streamsx._streams._version
version = streamsx._streams._version.__version__
setup(
  name = 'streamsx',
  packages = ['streamsx', 'streamsx.spl', 'streamsx.topology', 'streamsx.scripts', 'streamsx._streams'],
  include_package_data=True,
  version = version,
  description = 'IBM Streams Python Support',
  long_description = open('DESC.txt').read(),
  author = 'IBM Streams @ github.com',
  author_email = 'debrunne@us.ibm.com',
  license='Apache License - Version 2.0',
  url = 'https://github.com/IBMStreams/pypi.streamsx',
  download_url = 'https://github.com/IBMStreams/pypi.streamsx/tarball/' + version,
  keywords = ['streams', 'ibmstreams', 'streaming', 'analytics', 'streaming-analytics'],
  classifiers = [
    'Development Status :: 5 - Production/Stable',
    'License :: OSI Approved :: Apache Software License',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.5',
    'Programming Language :: Python :: 3.6',
    'Programming Language :: Python :: 3.7',
  ],
  install_requires=['requests', 'future', 'dill>=0.2.8.2,<0.3.1'],
  entry_points = {
        'console_scripts': [
            'streamsx-runner=streamsx.scripts.runner:main',
            'streams-service=streamsx.scripts.service:main',
            'streamsx-service=streamsx.scripts.service:main',
            'streamsx-info=streamsx.scripts.info:main',
            'streamsx-streamtool=streamsx.scripts.streamtool:main',
            'streamsx-sc=streamsx.scripts.sc:main',
            'spl-python-extract=streamsx.scripts.extract:main'
        ],
  },
)
