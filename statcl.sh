#!/bin/sh


# Prérequis pour la compilation des sources
#sudo apt install gcc make libx11-dev libxft-dev

# Paquets qui constituent statcl
. ./packages.sh

# Répertoire de ce script (les nombreux cd peuvent y revenir facilement)
root=$(readlink -f .)

# Répertoire qui contient les archives téléchargées
sources="${root}"/src

# Répertoire dans lequel on compile les sources téléchargées
build="${root}"/build

# Répertoire dans lequel on installe le résultat des compilations
tree="${root}"/tree

# Répertoire dans lequel on place les logs (sorties des compils, etc.)
log="${root}"/log

# Répertoire dans lequel on place les archives prêtes à être distribuées
release="${root}"/statcl

# Nb de compil parrallèles pour make
proc=4


# Produit la liste des "SHA path/to/file" des fichiers présents dans ${1}

getShaCmd() {

	find "${1}" -type f -print0 | xargs -0 shasum | sed "s: ${1}/::" | sort -k2
}


# Retire la version et extrait le nom de la target passée dans ${1}

getTargetName() {

	echo ${1} | sed -r 's:[-._0-9]::g'
}


make_tcl() {

	cd "${sources}"

	if [ ! -f ${tclTarget}-src.tar.gz ] ; then

		wget https://prdownloads.sourceforge.net/tcl/${tclTarget}-src.tar.gz
	fi

	cd "${build}"

	tar -xzf "${sources}"/${tclTarget}-src.tar.gz

	cd ./${tclTarget}/unix

	./configure --prefix="${tree}" --enable-shared=no

	make -j ${proc}

	make install

	# TODO : Pourquoi certaines pages sont-elles dans share/man ?
	rsync -avh "${tree}"/share/man "${tree}"/man
	rm -Rf "${tree}"/share/man

	getShaCmd "${tree}" > "${build}"/${tclTarget}.sha 2>&1

	cd "${root}"
}


make_tk() {

	cd "${sources}"

	if [ ! -f ${tkTarget}-src.tar.gz ] ; then

		wget https://prdownloads.sourceforge.net/tcl/${tkTarget}-src.tar.gz
	fi

	cd "${build}"

	tar -xzf "${sources}"/${tkTarget}-src.tar.gz

	cd ./${tkTarget}/unix

	./configure --prefix="${tree}" --enable-shared=no \
				--with-tcl="${tree}"/lib

	make -j ${proc}

	make install

	make html HTML_DIR="${tree}"/share/html

	getShaCmd "${tree}" > "${build}"/${tkTarget}.sha 2>&1

	cd "${root}"
}


make_tcllib() {

	cd "${sources}"

	if [ ! -f ${tclLibTarget}.tar.gz ] ; then

		wget https://github.com/tcltk/tcllib/archive/${tclLibTarget}.tar.gz
	fi

	cd "${build}"

	tar -xzf "${sources}"/${tclLibTarget}.tar.gz

	cd ./tcllib-${tclLibTarget}

	"${tree}"/bin/tclsh* ./installer.tcl -no-wait -html

	getShaCmd "${tree}" > "${build}"/${tclLibTarget}.sha 2>&1

	cd "${root}"
}


make_tklib() {

	cd "${sources}"

	if [ ! -f ${tkLibTarget}.tar.gz ] ; then

		wget https://core.tcl.tk/tklib/tarball/${tkLibTarget}.tar.gz
	fi

	cd "${build}"

	tar -xzf "${sources}"/${tkLibTarget}.tar.gz

	cd ./${tkLibTarget}

	"${tree}"/bin/wish* ./installer.tcl -no-wait -no-gui -html

	getShaCmd "${tree}" > "${build}"/${tkLibTarget}.sha 2>&1

	cd "${root}"
}


make_tkcon() {

	cd "${sources}"

	version=$(echo ${tkConTarget} | sed s:tkcon-:v:)

	if [ ! -f ${version}.tar.gz ] ; then

		wget https://github.com/wjoye/tkcon/archive/${version}.tar.gz
	fi

	cd "${build}"

	tar -xzf "${sources}"/${version}.tar.gz

	cd ./${tkConTarget}

	./configure --prefix="${tree}" --enable-shared=no \
				--with-tcl="${tree}"/lib \
				--with-tk="${tree}"/lib

	make -j ${proc}

	make install

	cp -R docs "${tree}"/share/tkcon

	getShaCmd "${tree}" > "${build}"/${tkConTarget}.sha 2>&1

	cd "${root}"
}


make_release() {

	cd "${tree}"

	tar -cf "${release}"/statcl-all.tar *
	gzip "${release}"/statcl-all.tar

	for target in ${buildSeq} ; do

		prettyTarget=$(prettyPrintTarget ${target})
		prettyArchive=statcl-${prettyTarget}.tar

		cat "${build}"/${target}.sha | while read -r s f ; do

			if [ -f "${f}" ] ; then

				sha=$(shasum "${f}" | cut -d' ' -f1)

				warn=""

				if [ ${s} != ${sha} ] ; then

					warn="MODIFIED"
				fi

				echo ${s} ${prettyTarget} "${f}" ${warn} \
					| tee -a "${release}"/statcl-files.txt

				tar -r -f "${release}"/${prettyArchive} -- "${f}"

				rm "${f}"
			fi
		done

		gzip "${release}"/"${prettyArchive}"

	done

	cd "${root}"
}


make_check() {

	cd "${release}"

	modified=$(grep "MODIFIED" statcl-files.txt | wc -l)

	if [ ${modified} -gt 0 ] ; then

		echo

		echo "${modified} file(s) where modified during build :"

		grep "MODIFIED" "${files}"

		echo
	else

		echo "No modified files"
	fi

	cd "${tree}"

	missed=$(find -type f | wc -l)

	if [ ${missed} -gt 0 ] ; then

		echo "${missed} file(s) remains in build folder :"

		find -type f

		echo
	else

		echo "No missed files"
	fi

	cd "${root}"
}


make_log() {

	cd "${log}"

	tar -cf "${release}"/statcl-logs.tar *.log
	gzip "${release}"/statcl-logs.tar

	cd "${root}"
}


make_info() {

	cd "${release}"

	date > "${build}"/statcl-info.txt 2>&1

	echo $(lsb_release -ds) $(uname -p) >> "${build}"/statcl-info.txt 2>&1

	for f in * ; do

		sha=$(shasum "${f}" | cut -d' ' -f1)
		size=$(ls -sh "${f}" | cut -d' ' -f1)

		echo "${sha} ${size} ${f}" >> "${build}"/statcl-info.txt 2>&1
	done

	mv "${build}"/statcl-info.txt .

	cd "${root}"
}


make_demo() {

	cd "${sources}"

	if [ ! -f appimagetool-x86_64.AppImage ] ; then

		wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
		chmod a+x appimagetool-x86_64.AppImage
	fi

	cd "${root}"

	cp -R WishDemo.AppDir "${build}"

	cd "${build}"/WishDemo.AppDir

	cp "${release}"/statcl-all.tar.gz .
	gunzip statcl-all.tar.gz
	tar -xf statcl-all.tar
	rm -f statcl-all.tar

	cd "${build}"

	"${sources}"/appimagetool-x86_64.AppImage WishDemo.AppDir
	cp WishDemo-x86_64.AppImage "${release}"

	cd "${root}"
}


rm -Rf "${build}" "${log}" "${release}" "${tree}"
mkdir "${build}" "${log}" "${release}" "${tree}"
mkdir -p "${sources}"

# Echaine toutes les étapes pour produire la distrib
for todo in ${buildSeq} release check log info demo ; do

	name=$(getTargetName ${todo})

	make_${name} 2>&1 | tee "${log}"/${todo}.log
done

echo "============================================================"
cat "${log}"/check.log
cat "${release}"/statcl-info.txt
