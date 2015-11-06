#!/bin/bash

USAGE="Usage: $(basename "$0") <INPUT> <OUTPUT>"

main()
{
    if [[ $# -ne 2 ]]
    then
        echo "${USAGE}"
        exit 1
    fi
    infile="$1"
    outfile="$2"

    assert_file "${infile}"

    set -x
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/default \
        -dNOPAUSE -dQUIET -dBATCH -dDetectDuplicateImages \
        -dCompressFonts=true -r150 -sOutputFile=
    set +x
}

main "$@"
