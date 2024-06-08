#!/bin/zsh

Page(){
    echo -n "Enter the page name :"
    read page
    page=$(echo "$page" | awk '{ for(i=1;i<=NF;i++) { $i=toupper(substr($i,1,1)) tolower(substr($i,2)) } print }')
    mkdir "app/${page}"
    touch "app/${page}/page.tsx"
    cat > "app/${page}/page.tsx" <<EOF
import type { Metadata } from "next";

export const metadata: Metadata = {
    title: "$page"
};

export default function ${page}Page() {
    return <>
        <div>${page} page</div>
    </>
}
EOF
}

File(){
    page=$(echo "$2" | awk '{ for(i=1;i<=NF;i++) { $i=toupper(substr($i,1,1)) tolower(substr($i,2)) } print }')
    lw_page=$(echo "$2" | tr '[:upper:]' '[:lower:]')
    file="components/$1/${lw_page}.tsx"
    touch $file
    cat > $file <<EOF
export function ${page}Comp() {
    return <>
        <div>${page} Component</div>
    </>
}
EOF
echo "export { ${page}Comp } from './$lw_page';" >> "components/$1/index.ts"
echo "export { ${page}Comp } from './$1';" >> "components/index.ts"
}

Component(){
    
echo -n "Enter the type of the component ( content:0, utility:1 ): "
read number


# Check if the number is 1 or 2
if [ $number -eq 0 ]; then
    echo -n "Enter the Content component name : "
    read comp
    File "contents" $comp
elif [ $number -eq 1 ]; then
    echo -n "Enter the Utility component name : "
    read comp
    File "utility" $comp
else
    echo "Try again "
    Component
fi

}

Lang(){
    echo -n "Enter the Lang name :"
    read page
    lw_page=$(echo "$page" | tr '[:upper:]' '[:lower:]')
    touch "lang/${lw_page}.ts"
    cat > "lang/${lw_page}.ts" <<EOF
import { ${page} } from "next/font/google";
export const $lw_page = $page({ subsets: ["latin"]);
EOF
    echo "export { $lw_page } from './$lw_page';" >> "lang/index.ts"
}

#REVIEW - Function for help menu
HelpMenu() {
    echo "Usage: $0 [-h] [-p] [-c] [-l]"
    echo
    echo "Options:"
    echo "  -h     Display this help menu."
    echo "  -p     Create Page."
    echo "  -c     Create Component."
    echo "  -l     Create Lang."
}

#REVIEW - Main function
Main() {
    while getopts "hpcil" opt; do
        case ${opt} in
        h)
            HelpMenu
            exit 0
            ;;
        p)
            Page
            exit 0
            ;;
        c)
            Component
            ;;
        l)
            Lang
            ;;
        ?)
            HelpMenu
            exit 1
            ;;
        esac
    done
    
    if [ -z "$@" ]; then
        HelpMenu
    else
        exit 1
    fi
}

# Call the Main function
Main "$@"
