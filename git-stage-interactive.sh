#!/bin/sh

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not a git repository."
    exit 42
fi

git status --porcelain=v1 | while IFS= read -r line; do
    status=$(echo "$line" | cut -c 1-2)
    file=$(echo "$line" | cut -c 4-)

    case "$file" in 
        *" -> "*)
            file="${file##* -> }"
            ;;
    esac

    worktree_status=$(echo "$status" | cut -c 2)
    if [ "$worktree_status" = " " ]; then
        continue
    fi

    case "$status" in
        *U*|AA|DD)
            echo "!!! CONFLICT ($status): $file (Skipping)"
            continue
            ;;
        "??")
            echo "NEW FILE: $file"
            ;;
        ?D)
            echo "DELETED: $file"
            ;;
        *)
            echo "REVIEWING: $file (Status: $status)"
            git diff "$file"
            ;;
    esac

    while true; do
        printf "Action for %s? ([a]dd / [c]heckout (restore) / [s]kip / [q]uit): " "$file"
        read -r action < /dev/tty
        case "$action" in
            [Aa]*) 
                git add "$file"
                echo "Staged."
                break
                ;;
            [Cc]*)
                if [ "$status" = "??" ]; then
                    echo "Cannot 'checkout' an untracked file. Use 'rm' manually if needed."
                else
                    printf "WARNING: Permanently discard changes via 'git checkout -- %s'? (y/n): " "$file"
                    read -r confirm < /dev/tty
                    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                        git checkout -- "$file"
                        echo "Executed: git checkout -- $file"
                        break
                    else
                        echo "Command cancelled."
                    fi
                fi
                ;;
            [Ss]*) 
                echo "Skipped."
                break
                ;;
            [Qq]*)
                echo "Aborting review."
                exit 1
                ;;
            *) 
                echo "Please enter 'a' to add, 'c' to checkout (restore), 's' to skip, or 'q' to quit."
                ;;
        esac
    done
done

echo "----------------------------"
echo "Review session complete. Current Status:"
git status
exit 0