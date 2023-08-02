#!/bin/bash

PYTHON_VERSION=“Python-3.8.0”

PYTHON_FILE_NAME=“python-$PYTHON_VERSION.tgz”

curl -o $PYTHON_FILE_NAME.tgz https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tgz

echo “Python  $PYTHON_VERSION downloaded and saved as $PYTHON_FILE_NAME