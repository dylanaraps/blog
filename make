#!/bin/sh -e
#
# The MIT License (MIT)
#
# Copyright (c) 2021 Dylan Araps
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

txt2html() {
    # Transform plain-text input into HTML and insert it into the template.
    # Right now this only does some URL transformations.

    # Convert all plain-text links to HTML links (<a href="X">X</a>).
    sed -E "s|([^\"\'\>=])(http[s]?://[^[:space:]\)]*)|\1<a href=\2>\2</a>|g" |
    sed -E "s|^(http[s]?://[^[:space:]\)]*)|<a href=\1>\1</a>|g" |

    # Convert #/words to absolute HTML links.
    # Convert @/words to relative HTML links.
    # Convert $/words to GitHub URLs.
    sed -E "s|(#/)([^ \)]*)|\1<a href=/\2>\2</a>|g" |
    sed -E "s|(@/)([^ \)]*)|\1<a href=${pp##.}/\2>\2</a>|g" |
    sed -E "s|(\\$/)([^ \)]*)|\1<a href=$repo_url/\2>\2</a>|g" |
    sed -E "s|(%/)([^ \)]*)|\1<a href=$repo_url/dylanaraps/\2>\2</a>|g" |

    # Convert [0] into HTML links.
    sed -E "s|^( *)\[([0-9\.]*)\]|\1<span id=\2>[\2]</span>|g" |
    sed -E "s|([^\"#])\[([0-9\.]*)\]|\1<a href=#\2>[\2]</a>|g" |

    # Insert the page into the template.
    sed -E '/%%CONTENT%%/r /dev/stdin' template.html |
    sed -E '/%%CONTENT%%/d' |

    # Insert the page path into the source URL.
    sed -E "s	%%TITLE%%	$title	"
}

page() {
    pp=${page%/*} title=${page##*/} title=${title%%.txt}

    mkdir -p "docs/$pp"

    # If the title is index.txt, set it to the parent directory name.
    # Example: /wiki/index.txt (index) -> (wiki).
    case $title in index) title=${pp##*/} ;; esac
    case $title in .)     title=home ;; esac

    # GENERATION STEP.
    case $page in
        *.txt)
            txt2html < "site/$page" > "docs/${page%%.txt}.html"
        ;;

        # Copy over any non-txt files.
        *)
            cp -f "site/$page" "docs/$page"
        ;;
    esac

    # POST-GENERATION STEP.
    case $page in
        # Hardlink all .txt files to the docs/ directory.
        *.txt) ln -f "site/$page" "docs/$page" ;;
    esac
}

main() {
    repo_url=https://github.com

    rm -rf docs
    mkdir -p docs

    (cd site && find . -type f) | while read -r page; do
        printf '%s\n' "CC $page"
        page "$page"
    done
}

main "$@"
