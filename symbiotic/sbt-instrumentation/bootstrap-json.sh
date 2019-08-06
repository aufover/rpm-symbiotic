#!/bin/sh

# exit on any error
set -e

# make sure we're in the source directory
cd `dirname $`

# don't do redundant work
if [ ! -d jsoncpp ]; then
	# checkout jsoncpp directory
	true
fi

cd ../jsoncpp
if [ ! -d CMakeFiles ]; then
	cmake .
fi

make
python amalgamate.py

# copy the jsoncpp.cpp file into parent's src/ folder
cp -R dist/* ../sbt-instrumentation/src
rsync -r dist/json ../include/

echo "json files successfully copied"
