#!/bin/bash

if [ ! -d build ]; then
  mkdir build
fi
sed '/(:-- START PRIVATE --:)/,/(:-- END PRIVATE --:)/d' date-ranges.xqy > build/date-ranges.xqy || exit
xquerydoc -x build -o build/xqdoc -f markdown || exit
cp build/xqdoc/xqdoc_build_date-ranges.xqy.md API.md || exit
sed -i '' 's/&lt;/</g' API.md || exit
sed -i '' 's/&gt;/</g' API.md || exit # yes really, apparently a bug in xquerydoc..

if [ -d build ]; then
  rm -rf build
fi
