#!/bin/bash

git rev-parse HEAD > git_rev-parse.ver
cd dg || exit 1
git rev-parse HEAD > git_rev-parse.ver
cd ..
cd sbt-slicer || exit 1
git rev-parse HEAD > git_rev-parse.ver
cd ..
cd sbt-instrumentation || exit 1
git rev-parse HEAD > git_rev-parse.ver
cd ..

cd klee || exit 1
git rev-parse HEAD > git_rev-parse.ver
cd ..
