### Attention! Unreliable! Formatting depends on git version! ###

# win grep can't use 'grep -o'. Results need to be cut maually
#TAGS=($(git log --tags --simplify-by-decoration --format=%d | grep -E 'Sprint' | tr -d '(),' | cut -f3 --delimiter=' '))
# unix may use 'grep -o'. Will reduce output to matching string
TAGS=($(git log --tags --simplify-by-decoration --format=%d | grep -oE '[0-9\._]*Sprint\w+'))
FILENAME="changelog.txt"

echo "===== ZIB-Changelog =====" > ${FILENAME}

for ((i=0; i + 1 < ${#TAGS[*]}; i += 1))
do
        CURR_TAG=${TAGS[$i]}
        PREV_TAG=${TAGS[$i+1]}
        echo "" >> ${FILENAME}
        echo "--== $CURR_TAG ==--" >> ${FILENAME}
        git log --oneline ${PREV_TAG}..${CURR_TAG} | cut -b9- | sort | uniq -w8 | grep -E '^(ZIB-[0-9]{4,})' >> ${FILENAME}
done

# CURR_TAG="$(git describe --tags --abbrev=0)"
# PREV_TAG="$(git describe --tags --abbrev=0 ${CURR_TAG}~1)"
# echo "--== ${CURR_TAG} ==--" > ${FILENAME}
# git log --oneline ${PREV_TAG}..${CURR_TAG} | cut -b9- | sort | uniq -w8 | grep -Ev '^(ZIB-XXXX|Merge|Revert)' >> ${FILENAME}