#!/bin/bash

#This file simply creates a readme file with release 
#info, and zips up the current contents of trunk.

echo ""
echo "*** Creating a release package for the sample implementation of CodeSharing. ***"
echo ""
CHANGES=`svn status trunk | grep [AMCDG]`
if [ -n "$CHANGES" ]; then
    echo "You have uncommitted changes in trunk."
    echo "You should probably commit them before making a package."
    echo "Press Control + C to exit this process and commit your changes."
    read
fi
rm -rf tmp
mkdir tmp
REVISION=`svnversion -n trunk | sed -r 's/^[0-9]+://'`
echo "Trunk revision is : ${REVISION}"
echo ""
echo "CodeSharing build from SVN revision $REVISION" >> tmp/README.txt
echo "Packaged on $(date)." >> tmp/README.txt
echo "" >> tmp/README.txt
cat trunk/instructions.txt >> tmp/README.txt
zip -rj tmp/codesharing.zip trunk/*
zip -rj tmp/codesharing.zip tmp/README.txt
cp tmp/codesharing.zip codesharing_rev_${REVISION}.zip
rm -rf tmp
echo ""
echo "*** Created codesharing_rev_$REVISION.zip file ***"
echo ""
