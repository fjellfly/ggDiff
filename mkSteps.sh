#!/bin/bash

# Visualize the evolution of a pdf document stored inside a git repository
# over time. For every commit containing this pdf an overview-image is created.
# In the end all images are merged to a gif-animation.

maximumNumberOfPages=0
count=0

options=':i:x:y:d:o:'

while getopts $options option
do
	case $option in
		i ) inFile="$OPTARG";;
		x ) tx="$OPTARG";;
		y ) ty="$OPTARG";;
		d ) delay="$OPTARG";;
		o ) outFile="$OPTARG";;
	esac
done

while [[ $inFile = "" ]]; do
	read -p "Name of pdf? " file 
done

echo "Fetch $inFile from git ..."

workspace="/tmp/mkSteps"
mkdir $workspace

for f in $(git log --pretty=format:"%H"); do

	numberOfPages=0

	git show ${f}:$inFile > $workspace/v${count}.pdf

	# file was'nt sucessfully erxported. abort current commit.
	if [ $? -ne 0 ]; then
		continue
	fi

	numberOfPages=$(pdfinfo $workspace/v${count}.pdf 2>/dev/null | grep "Pages" | awk '{print $2}')

	if [ "$numberOfPages" -eq "$numberOfPages" ] 2>/dev/null; then
	
		echo "Commit #$count: $f, $numberOfPages pages."

		if [ $numberOfPages -gt $maximumNumberOfPages ]; then
			maximumNumberOfPages=$numberOfPages
		fi
	
		((count++))
	fi
done

numberOfSteps=$count

confirm=false

echo "There is a maximum of $maximumNumberOfPages to display."

if [[ "$tx" = "" || "$ty" = "" ]]; then
	echo "Please enter a tile setup"

	while [ $confirm != true ]; do

		answer="M"

		read -p "Number of pages in a row: " tx
		read -p "Number of pages in a column: " ty

		if [ $(($tx*$ty)) -lt $maximumNumberOfPages ]; then
			echo "The setup you have choosen doesn't support the maximum number of pages."
			while [[ $answer != "Y" && $answer != "N" ]]; do
				read -p "Continue? [Y/N] " answer
			done
			if [ $answer = "Y" ]; then
				confirm=true
			fi
		else
			confirm=true
		fi
	done
elif [[ $(($tx*$ty)) -lt "$maximumNumberOfPages" ]]; then
	echo "The provided parameters for tile setup doesn't fit the maximum number of pages."
	exit
fi

echo "Setup for final page: ${tx}x${ty} tiles. Extract and merge slides..."

count=0

while [ $count -lt $numberOfSteps ]; do

	echo "($(($count+1))/$numberOfSteps)"

	(cd $workspace && pdftocairo -jpeg v${count}.pdf)
	(cd $workspace && montage v${count}-*jpg -tile ${tx}x${ty} step_v${count}.jpg)

	rm $workspace/v*.jpg
	((count++))
done

echo "Create animation..."

while [ "$delay" = "" ]; do
	read -p "Time between timesteps? [integer] " delay
done

while [ "$outFile" = "" ]; do
	read -p "Name of output file? " outFile
done

(cd $workspace && convert -delay $delay -loop 1 $(ls -1vr step_v*) res.gif)
mv "$workspace/res.gif" "./$outFile"
rm -rf $workspace

echo "Output was written to $outFile!"
