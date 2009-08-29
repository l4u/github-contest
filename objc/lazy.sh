#!/bin/sh

make clean
make
./main
git commit ../results.txt -m "test"
git push
