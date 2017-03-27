from setuptools import setup
setup(
  name = 'streamsx',
  packages = ['streamsx', 'streamsx.spl', 'streamsx.topology'],
  include_package_data=True,
  version = '1.6.0',
  description = 'IBM Streams Python Support',
  long_description = open('DESC.txt').read(),
  author = 'IBM Streams @ github.com',
  author_email = 'debrunne@us.ibm.com',
  url = 'https://github.com/IBMStreams/pypi.streamsx',
  download_url = 'https://github.com/IBMStreams/pypi.streamsx/tarball/1.6.0',
  keywords = ['streams', 'ibmstreams', 'streaming', 'analytics', 'streaming-analytics'],
  classifiers = [
    'Development Status :: 5 - Production/Stable',
    'License :: OSI Approved :: Apache Software License',
    'Programming Language :: Python :: 2',
    'Programming Language :: Python :: 2.7',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.5',
  ],
  install_requires=['requests', 'future', 'dill', 'enum34'],
)
