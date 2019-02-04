from setuptools import setup
import streamsx._streams._version
setup(
  name = 'streamsx',
  packages = ['streamsx', 'streamsx.spl', 'streamsx.topology', 'streamsx.scripts', 'streamsx._streams'],
  include_package_data=True,
  version = streamsx._streams._version.__version__,
  description = 'IBM Streams Python Support',
  long_description = open('DESC.txt').read(),
  author = 'IBM Streams @ github.com',
  author_email = 'debrunne@us.ibm.com',
  license='Apache License - Version 2.0',
  url = 'https://github.com/IBMStreams/pypi.streamsx',
  download_url = 'https://github.com/IBMStreams/pypi.streamsx/tarball/' + streamsx._streams._version.__version__,
  keywords = ['streams', 'ibmstreams', 'streaming', 'analytics', 'streaming-analytics'],
  classifiers = [
    'Development Status :: 5 - Production/Stable',
    'License :: OSI Approved :: Apache Software License',
    'Programming Language :: Python :: 2',
    'Programming Language :: Python :: 2.7',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.5',
    'Programming Language :: Python :: 3.6',
  ],
  install_requires=['requests', 'future', 'dill', 'enum34;python_version=="2.7"'],
  entry_points = {
        'console_scripts': [
            'streamsx-runner=streamsx.scripts.runner:main',
            'streams-service=streamsx.scripts.service:main',
            'streamsx-info=streamsx.scripts.info:main',
            'spl-python-extract=streamsx.scripts.extract:main'
        ],
  },
)
