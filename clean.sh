#!/bin/bash
make clean

echo "removing .DS_Store files"
find . -name '.DS_Store' -delete

echo "removing /obj"
rm -rf obj
rm -rf Prefs/obj

echo "removing /packages"
rm -rf packages
rm -rf Prefs/packages

echo "removing /.theos"
rm -rf .theos
rm -rf Prefs/.theos

echo "done."
