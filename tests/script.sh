# Check syntax in php files.
find . -type "f" -iname "*.php" -exec php -l {} \;

# Run tests.
cd tests && phpunit --configuration phpunit.xml

# Enforce line ending consistency in php files.
crlf_file=$(find . -type "f" -iname "*.php" -exec grep --files-with-matches $'\r' {} \;)
if [[ ! -z "${crlf_file}" ]]; then
    echo "${crlf_file}" | perl -pe 's/(.*)/CRLF line terminators found in \1/'
    exit 1
fi

# Enforce indentation character consistency in php files.
tab_char=$(find . -type "f" -iname "*.php" -exec grep --line-number -H --perl-regexp "\t" {} \;)
if [[ ! -z "${tab_char}" ]]; then
    echo -e "${tab_char}" | perl -pe 's/^(.*)$/Tab character found in \1/'
    exit 1
fi

# Enforce indentation consistency in php files.
find_invalid_indentation() {
    filename="${1}"
    script=$(cat <<'EOF'
    $filename = $argv['1'];
    $lines = explode("\n", file_get_contents($filename));
    $line_number = 0;
    foreach ($lines as $line) {
        $line_number += 1;
        $leading_space_count = strspn($line, ' ');
        $remainder = $leading_space_count % 4;
        if (!($remainder === 0)) {
            // Allow doc comments.
            if (substr(ltrim($line), 0, 1) === '*') {
                continue;
            }
            $add_count = 4 - $remainder;
            $remove_count = $remainder;
            echo 'Invalid indentation found in ' . $filename . ':' . $line_number .
                ' (' . $leading_space_count . ':+' . $add_count . '/-' . $remove_count . ')' . "\n";
        }
    }
EOF
)
    php --run "${script}" "${filename}"
}
# Skip hhvm "Notice: File could not be loaded: ..."
if [[ "${TRAVIS_PHP_VERSION}" != "hhvm" ]]; then
    export -f "find_invalid_indentation"
    invalid_indentation=$(find . -type "f" -iname "*.php" -exec bash -c 'find_invalid_indentation "{}"' \;)
    if [[ ! -z "${invalid_indentation}" ]]; then
        echo "${invalid_indentation}"
        exit 1
    fi
fi

# Prohibit trailing whitespace in php files.
trailing_whitespace=$(find . -type "f" -iname "*.php" -exec egrep --line-number -H " +$" {} \;)
if [[ ! -z "${trailing_whitespace}" ]]; then
    echo -e "${trailing_whitespace}" | perl -pe 's/^(.*)$/Trailing whitespace found in \1/'
    exit 1
fi
