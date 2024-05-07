cat $1 | awk 'NR % 3 == 2' | awk '{ sub(/^[ \t]+/, ""); print }' | awk '{ sub(/[ \t]+$/, ""); print }' 
