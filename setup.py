from setuptools import setup
setup(
  name = 'streamsx',
  packages = ['streamsx'],
  version = '0.3.0',
  description = 'IBM Streams Python Support',
  author = 'IBM Streams @ github.com',
  author_email = 'debrunne@us.ibm.com',
  url = 'https://github.com/IBMStreams/pypi.streamsx',
  download_url = 'https://github.com/IBMStreams/pypi.streamsx/tarball/0.3.0',
  keywords = ['streams', 'ibmstreams', 'streaming'],
  classifiers = [
    'Development Status :: 3 - Alpha',
    'License :: OSI Approved :: Apache Software License',
    'Programming Language :: Python :: 2',
    'Programming Language :: Python :: 2.7',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.5',
  ],
  install_requires=['requests'],
)
