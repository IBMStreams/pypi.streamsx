# pypi.streamsx
This is a step in allowing natural use of Streams for a Python developer.

A project that will be registered with PyPi to allow 'pip install' of Python packages that support Python developers interacting with IBM Streams. 'pip install' is the standard mechanism for Python developers to download code.
(See http://peterdowns.com/posts/first-time-with-pypi.html)

Project would initially support:

    Python Application API (from streamsx.topology)
    Python Rest API (from streamsx.utility)

Project would maintain copies of the files from other IBMStreams projects (or their releases), the master versions would remain in the source projects.

A single PyPi package for IBM Streams Python code is used rather than multiple to simplify setup for Python developers.
