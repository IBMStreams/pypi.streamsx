from distutils.core import setup
setup(
  name = 'streamsx',
  packages = ['streamsx'],
  version = '0.2.1',
  description = 'IBM Streams Python Support',
  author = 'IBM Streams @ github.com',
  author_email = 'debrunne@us.ibm.com',
  url = 'https://github.com/IBMStreams/pypi.streamsx',
  download_url = 'https://github.com/IBMStreams/pypi.streamsx/tarball/0.2.1',
  keywords = ['streams', 'ibmstreams'],
  classifiers = [
    'Development Status :: 3 - Alpha',
    'License :: OSI Approved :: Apache Software License',
    'Programming Language :: Python'
    
  ],
  install_requires=['requests'],
)
