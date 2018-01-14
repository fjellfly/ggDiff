#!/bin/bash

maximumNumberOfPages=0

count=0

echo "Fetch pdfs from git ..."

for f in $(git log --pretty=format:"%H"); do

	git show ${f}:milestone.pdf > milestone_v${count}.pdf
	numberOfPages=$(pdfinfo milestone_v${count}.pdf | grep "Pages" | awk '{print $2}')
	echo "Commit #$count: $f, $numberOfPages pages."

	if [ $numberOfPages -gt $maximumNumberOfPages ]; then
		maximumNumberOfPages=$numberOfPages
	fi
	
	((count++))
done

numberOfSteps=$count

tx=10
ty=10

if [ $maximumNumberOfPages -le 20 ]; then 
	tx=5
	ty=4
elif [ $maximumNumberOfPages -le 25 ]; then
	tx=5
	ty=5
elif [ $maximumNumberOfPages -le 30 ]; then
	tx=6
	ty=5
elif [ $maximumNumberOfPages -le 36 ]; then
	tx=6
	ty=6
elif [ $maximumNumberOfPages -le 42 ]; then
	tx=7
	ty=6
fi

echo "Setup for final page: ${tx}x${ty} tiles. Extract and merge slides..."

count=0

while [ $count -lt $numberOfSteps ]; do
	pdftocairo -jpeg milestone_v${count}.pdf
	montage milestone_v${count}-*jpg -tile ${tx}x${ty} step_v${count}.jpg
	
	rm milestone*.jpg
	((count++))
done

echo "Create animation..."

convert -delay 50 -loop 1 $(ls -1vr step_v*) steps.gif
rm step_v*
