#!/bin/bash

maximumNumberOfPages=0

count=0

read -p "Name of pdf? " name

echo "Fetch pdfs from git ..."

for f in $(git log --pretty=format:"%H"); do

	numberOfPages=

	git show ${f}:$name > milestone_v${count}.pdf
	
	if [ $? -ne 0 ]; then
		continue
	fi

	numberOfPages=$(pdfinfo milestone_v${count}.pdf 2>/dev/null | grep "Pages" | awk '{print $2}')

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

echo "There is a maximum of $maximumNumberOfPages to display. Please enter a tile setup)"

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

echo "Setup for final page: ${tx}x${ty} tiles. Extract and merge slides..."

count=0

while [ $count -lt $numberOfSteps ]; do
	pdftocairo -jpeg milestone_v${count}.pdf
	montage milestone_v${count}-*jpg -tile ${tx}x${ty} step_v${count}.jpg
	
	rm milestone*.jpg
	((count++))
done

echo "Create animation..."

read -p "Time between timesteps? [integer] " dt

convert -delay $dt -loop 1 $(ls -1vr step_v*) steps.gif
rm step_v*

echo "Output was written to steps.gif!"
