#!/bin/bash

#This file simply creates a readme file with release 
#info, and zips up the current contents of trunk.

echo ""
echo "*** Creating a release package for the sample implementation of CodeSharing. ***"
echo ""
CHANGES=
if [[ -n $(git diff --exit-code) ]]; then
    echo "You have uncommitted changes in the repo."
    echo "You should probably commit them before making a package."
    echo "Press Control + C to exit this process and commit your changes."
    read
fi
rm -rf tmp
mkdir tmp
HASH=`git log --pretty=format:'%h' -n 1`
echo "Git revision is : ${HASH}"
echo ""
echo "CodeSharing build from Git revision $HASH" >> tmp/README.txt
echo "Packaged on $(date)." >> tmp/README.txt
echo "" >> tmp/README.txt
cat code/instructions.txt >> tmp/README.txt
zip -rj tmp/codesharing.zip code/*
zip -rj tmp/codesharing.zip tmp/README.txt
cp tmp/codesharing.zip codesharing.zip
rm -rf tmp
echo ""
echo "*** Created codesharing.zip file ***"
echo ""
