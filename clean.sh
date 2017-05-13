#!/bin/bash

echo
echo ">> deleting '.DS_Store' files..."
find . -name '.DS_Store' -delete

echo
echo ">> cleaning..."
make clean

echo
echo ">> deleting 'obj' folders..."
rm -rf obj
rm -rf Prefs/obj

echo
read -p "Remove packages? (y/n) " answer
while true
do
	case $answer in
		[yY]* ) echo ">> deleting 'packages' folders..."
				rm -rf packages
				rm -rf Prefs/packages				
				break;;
		* )		echo ">> skipping 'packages' folders"
				break;;
	esac
done

echo
read -p "Remove .theos? " answer
while true
do
	case $answer in
		[yY]* ) echo ">> deleting '.theos' folders..."
				rm -rf .theos
				rm -rf Prefs/.theos
				break;;
		* )		echo ">> skipping '.theos' folders"
				break;;
	esac
done

echo
echo "Done."
echo
