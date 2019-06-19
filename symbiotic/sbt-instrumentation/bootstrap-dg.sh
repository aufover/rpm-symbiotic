#!/bin/sh

# exit on any error
set -e

# make sure we're in the source directory
cd `dirname $`

# don't do redundant work
if [ ! -d dg ]; then
	# checkout dg directory
	true
fi

cd dg
if [ ! -d CMakeFiles ]; then
	cmake .
fi

make install

echo "dg library successfully installed"

