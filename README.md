# git-stage-interactive

A simple script to interactively walk through and review changes before staging them. 

This tool provides a lightweight, terminal-optimized alternative to `git add -i`. It allows you to walk through your unstaged changes file-by-file, view diffs, and decide exactly what enters your next commit.

## Why I created this
I found the built-in `git add -i` (interactive mode) to be cluttered and `git add -p` (patch mode) to be too fragmented for my needs. My goal was to create a tool that felt more "human" and focused.

When working on complex features, it’s easy to lose track of exactly what has been changed across a large amount of files. I wanted a workflow that would:

1. **Focus on Files, Not Hunks**: `git add -p` forces you to review code in small fragments (hunks), which can lose the broader context. I wanted to see the *entire* diff for a file at once to ensure the overall logic holds together before staging it.

2. **Remove Noise**: Don't show me files I've already staged; only show me what's left to do.

3. **Clear Intent**: Show me a full git diff for each modification so I can review my logic one last time before it's "locked in".

4. **Command Familiarity**: Use the actual Git terms I already know (`add` and `checkout`) instead of a proprietary menu system.

5. **POSIX Compliant & Dependency-Free:** Written in pure POSIX `sh`, this script runs on virtually any Unix-like system (Linux, macOS, WSL, BSD) without requiring Python, Perl, or compiled binaries.

6. **TTY-Awareness**: Handle input through `/dev/tty` so the script can be used safely within pipes or as a sub-command for other scripts.

This script acts as a final sanity check, ensuring that every line of code in the commit is there on purpose.

## Installation

First, clone the repository and make the script executable:

```sh
git clone https://github.com/Kofoten/git-stage-interactive.git
cd git-stage-interactive
chmod +x git-stage-interactive.sh
```

Now, choose one of the three methods below to enable the git si command.

### Option 1: Symbolic Link (Recommended)

This creates a link to the script in your system path. This is the best method because it treats git si as a native command, and updates apply automatically when you `git pull` this repository.

Create a symbolic link in `/usr/local/bin` (or any folder in your `$PATH`) pointing to the script:

```sh
sudo ln -s "$(pwd)/git-stage-interactive.sh" /usr/local/bin/git-si
```

### Option 2: Install to PATH (Standalone)

If you prefer to install the file as a standalone binary (so it works even if you delete the source repository), you can copy it to your system path. *Note: You will need to manually repeat this step to update the script in the future.*

Copy the script to `/usr/local/bin`:

```sh
sudo cp git-stage-interactive.sh /usr/local/bin/git-si
```

### Option 3: Git Alias

If you cannot use `sudo` or prefer not to modify system folders, use a Git alias.

Configure the alias (this also uses the current directory):
```sh
git config --global alias.si "!$(pwd)/git-stage-interactive.sh"
```

## Usage

Run the tool from the root of any Git repository:

```sh
git si
```

### Available Actions
|Key|Action|Description|
|---|---|---|
|a|add|Runs git add on the current file.|
|c|checkout|Runs git checkout -- to discard unstaged changes (requires confirmation).|
|s|skip|Leaves the file as-is and moves to the next change.|
|q|quit|Immediately ends the session and shows a final status.|

### Advanced Usage: Scripting & Automation
Because this script uses `/dev/tty` for user interaction, it can be safely called from within other shell scripts without breaking the parent script's input stream. It also uses standard exit codes:

* `exit 0`: The review session was completed naturally.
* `exit 1`: The review session was aborted (user hit q).
* `exit 42`: The working directory is not a git repository.

#### ⚠️ A Note on Automation
While this script is "script-friendly," it is **not automatable**. Because it pulls input directly from the terminal device (`/dev/tty`), you cannot pipe answers into it (e.g., `echo "a" | git si` will not work).

This is an intentional design choice to ensure that **checkout** and **add** actions are always confirmed by a human being and never executed by an accidental input stream.

#### Example: Chaining Commands
You can chain `git si` with other Git commands to create a "Review then Commit" workflow:

```sh
# Only run commit if the review finishes successfully
git si && git commit
```