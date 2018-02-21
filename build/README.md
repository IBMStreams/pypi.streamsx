To create a release:

1. Modify `setup.py` to bump the version number as required (e.g. 0.4.0) (two places)
1. Modify `build.xml` to change the release URL for the topology toolkit
1. Execute `ant get_artifacts` to update the contents of the package
1. `git add build/build.xml setup.py`
1. Verify DESC.txt is correct including the documentation links.
1. Make any other changes required.
1. Ensure all modified files are "git added".
1. Commit all changes
1. add tag `git tag 0.4.0`
1. `git push`
1. `git push --tags`


See : http://peterdowns.com/posts/first-time-with-pypi.html

Upload to test PyPi

1. `python setup.py sdist bdist_wheel upload -r pypitest`

You can test by installing using

1. `pip install --upgrade -i https://testpypi.python.org/pypi streamsx`

Then upload to production Py Pi

1. `python setup.py sdist bdist_wheel upload -r pypi`
