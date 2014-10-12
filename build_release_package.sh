#!/bin/bash

#This file simply creates a readme file with release 
#info, and zips up the current contents of trunk.

echo ""
echo "*** Creating a release package for the sample implementation of CodeSharing. ***"
echo ""
rm -rf tmp
mkdir tmp
REVISION=`svnversion trunk | sed 's/^[0-9]*://p'`
echo "Trunk revision is : $REVISION"
echo ""
echo "CodeSharing build from SVN revision $REVISION" >> tmp/README.txt
echo "Packaged on $(date)." >> tmp/README.txt
zip -rj tmp/codesharing.zip trunk/*
zip -rj tmp/codesharing.zip tmp/README.txt
cp tmp/codesharing.zip codesharing_rev_${REVISION}.zip
rm -rf tmp
echo ""
echo "*** Created codesharing_rev_$REVISION.zip file ***"
