#!/bin/sh

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    printf "Error: Not a git repository.\n"
    exit 42
fi

status_output=$(git status --porcelain=v1)

while IFS= read -r line; do
    if [ -z "$line" ]; then
        continue
    fi

    file="${line#???}"
    status="${line% $file}"

    case "$file" in 
        *" -> "*)
            file="${file##* -> }"
            ;;
    esac

    file="${file#\"}"
    file="${file%\"}"

    if [ "${status#?}" = " " ]; then
        continue
    fi

    case "$status" in
        *U*|AA|DD)
            printf "!!! CONFLICT (%s): %s (Skipping)\n" "$status" "$file"
            continue
            ;;
        "??")
            printf "NEW FILE: %s\n" "$file"
            ;;
        ?D)
            printf "DELETED: %s\n" "$file"
            ;;
        *)
            printf "REVIEWING: %s (Status: %s)\n" "$file" "$status"
            git diff "$file"
            ;;
    esac

    while true; do
        printf "Action for %s? ([a]dd / [c]heckout (restore) / [s]kip / [q]uit): " "$file"
        read -r action < /dev/tty
        case "$action" in
            [Aa]*) 
                git add "$file"
                printf "Staged.\n"
                break
                ;;
            [Cc]*)
                if [ "$status" = "??" ]; then
                    printf "Cannot 'checkout' an untracked file. Use 'rm' manually if needed.\n"
                else
                    printf "WARNING: Permanently discard changes via 'git checkout -- %s'? (y/n): " "$file"
                    read -r confirm < /dev/tty
                    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                        git checkout -- "$file"
                        printf "Executed: git checkout -- %s\n" "$file"
                        break
                    else
                        printf "Command cancelled.\n"
                    fi
                fi
                ;;
            [Ss]*) 
                printf "Skipped.\n"
                break
                ;;
            [Qq]*)
                printf "Aborting review.\n"
                exit 1
                ;;
            *) 
                printf "Please enter 'a' to add, 'c' to checkout (restore), 's' to skip, or 'q' to quit.\n"
                ;;
        esac
    done
done <<EOF
$status_output
EOF

printf "Review session complete.\n"
printf "----------------------------\n"
printf "Current Status:\n"
git status
exit 0
