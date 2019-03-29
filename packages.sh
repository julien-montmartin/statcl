version=8.6.8

tclTarget=tcl${version}
tkTarget=tk${version}
tclLibTarget=tcllib_1_18
tkLibTarget=tklib-0.6
tkConTarget=tkcon-2.7.1

# Liste les paquets dans le bon ordre (tcl, puis tk, puis le reste)
buildSeq=${tclTarget}\ ${tkTarget}\ ${tclLibTarget}\ ${tkLibTarget}\ ${tkConTarget}


# Affiche un nom normalisé, target-1.2.3, pour la variable xxxTarget dans ${1}

prettyPrintTarget() {

	echo ${1} | sed -r -e 's:-|_:.:g' -e 's:([a-zA-Z]*)[^0-9]?([0-9.]*):\1-\2:'
}
