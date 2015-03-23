#!/bin/bash

# stop script on error and print it
set -e
# inform me of undefined variables
set -u
# handle cascading failures well
set -o pipefail

script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

latex_folder=${1:-}
if [[ -z "$latex_folder" ]]
then
    echo "Usage $0 LATEXFOLDER."
    echo
    echo "Where LATEXFOLDER contains one or more tex files."
    exit 1
fi

function on_error {
    echo ERROR
    cat latex_output.log
    echo
    popd > /dev/null
    exit 1
}

# Change to absolute path
latex_folder=$(cd $latex_folder && pwd)  

mkdir -p $latex_folder/build
pushd $latex_folder/build > /dev/null
for tex_file in $latex_folder/*.tex
do
    printf "Processing $tex_file... "
    filename=$(basename "$tex_file")
	filename="${filename%.*}"
    COMPILE_FAILURE=0
	pdflatex -shell-escape $tex_file > latex_output.log <<< "q" || on_error
    
    # bibtex throws error code 2 if bibliography is not present in pdf
    # this is acceptable. 
    set +e
    	bibtex $filename.aux > latex_output.log 2>&1
        [[ $? == 0 || $? == 2 ]] || on_error
    set -e
	pdflatex -shell-escape $tex_file > latex_output.log <<< "q" || on_error
	pdflatex -shell-escape $tex_file > latex_output.log <<< "q" || on_error

    echo OK
    cp *.pdf ../
done
popd > /dev/null

