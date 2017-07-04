#!/bin/bash

xquerydoc -f markdown
cp xqdoc/xqdoc_ml-date-ranges_date-ranges.xqy.md API.md
sed -i '' 's/&lt;/</g' API.md
sed -i '' 's/&gt;/</g' API.md # yes really, apparently a bug in xquerydoc..
sed -i '' '/<!-- START IGNORE -->/,/<!-- END IGNORE -->/d' API.md
echo "Update TOC section of API.md manually!"
