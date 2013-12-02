#!/bin/bash

# This script extracts the changelog from the HTML version of the manual

orig=`pwd`

newdir="../Aquamacs\ Help"

cd ../Aquamacs\ Help
chgfile=$(/usr/bin/grep -m1 -l changelog-top *.html)

cp ${chgfile} ${chgfile}.bak 

(cat ${chgfile}.bak | perl -e 'my $x=join("",<STDIN>); $x=~s!(<H2>.*?)(<a name="changelog-top"></a>)!\2\1!s; print($x);' > ${chgfile} ) 

rm "${chgfile}.bak" 

(cat ${chgfile} | perl -e 'my $x=join("",<STDIN>); $x=~s|^.*(<a name="changelog-top"></a>)(.*?)<!--Navigation Panel-->.*</HTML>|\2|s; print($x);' > ${orig}/changelog.html ) 

cd ${orig}
