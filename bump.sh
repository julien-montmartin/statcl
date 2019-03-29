#!/bin/bash

. ./packages.sh

msg="Trigger Travis build for Statcl ${version}"

echo "${msg}"

cp curl_base.txt curl.txt
cp .travis_base.yml .travis.yml

ghDownload=https://github.com/julien-montmartin/staticl/releases/download

for target in ${buildSeq} ; do

	prettyTarget=$(prettyPrintTarget ${target})

	echo "url ${ghDownload}/${version}/statcl-${prettyTarget}.tar.gz" >> curl.txt

	echo "    - statcl/statcl-${prettyTarget}.tar.gz" >> .travis.yml

done

git add curl.txt .travis.yml
git commit --allow-empty -m "${msg}"
git tag -d ${version}
git tag ${version}

echo git push --tags -f origin HEAD:master
