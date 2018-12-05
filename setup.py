from setuptools import setup
setup(
  name = 'streamsx',
  packages = ['streamsx', 'streamsx.spl', 'streamsx.topology', 'streamsx.scripts', 'streamsx._streams'],
  include_package_data=True,
  version = '1.11.7b2',
  description = 'IBM Streams Python Support',
  long_description = open('DESC.txt').read(),
  author = 'IBM Streams @ github.com',
  author_email = 'debrunne@us.ibm.com',
  license='Apache License - Version 2.0',
  url = 'https://github.com/IBMStreams/pypi.streamsx',
  download_url = 'https://github.com/IBMStreams/pypi.streamsx/tarball/1.11.7b2',
  keywords = ['streams', 'ibmstreams', 'streaming', 'analytics', 'streaming-analytics'],
  classifiers = [
    'Development Status :: 3 - Alpha',
    'License :: OSI Approved :: Apache Software License',
    'Programming Language :: Python :: 2',
    'Programming Language :: Python :: 2.7',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.5',
    'Programming Language :: Python :: 3.6',
  ],
  install_requires=['requests', 'future', 'dill', 'enum34'],
  entry_points = {
        'console_scripts': [
            'streamsx-runner=streamsx.scripts.runner:main',
            'streams-service=streamsx.scripts.service:main',
            'streamsx-info=streamsx.scripts.info:main',
            'spl-python-extract=streamsx.scripts.extract:main'
        ],
  },
)
