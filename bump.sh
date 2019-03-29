#!/bin/bash

. ./packages.sh

msg="Trigger Travis build for Statcl ${version}"

echo "${msg}"

cp curl_base.txt curl.txt
cp .travis_base.yml .travis.yml

ghDownload=https://github.com/julien-montmartin/statcl/releases/download

for target in ${buildSeq} ; do

	prettyTarget=$(prettyPrintTarget ${target})

	echo "url ${ghDownload}/${version}/statcl-${prettyTarget}.tar.gz" >> curl.txt
	echo "output statcl-${prettyTarget}.tar.gz" >> curl.txt

	echo "    - statcl/statcl-${prettyTarget}.tar.gz" >> .travis.yml

done

git add bump.sh curl.txt .travis.yml
