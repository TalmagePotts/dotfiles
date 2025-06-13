#!/bin/bash

# Task delegation script for Claude instances
# Usage: ./delegate-task.sh "task-name" "task description"

if [ $# -lt 2 ]; then
    echo "Usage: $0 \"task-name\" \"task description\""
    exit 1
fi

TASK_NAME="$1"
TASK_DESCRIPTION="$2"
TASK_DIR="${TASK_NAME}"

# Create task directory if it doesn't exist
mkdir -p "${TASK_DIR}"
cd "${TASK_DIR}"
git clone https://github.com/mikaelweiss/strive
cd strive
git checkout -b ${TASK_NAME}
git switch -c ${TASK_NAME}

# Initialize progress tracking
cd ..
echo "# Task: ${TASK_NAME}" > progress.md
echo "" >> progress.md
echo "**Description:** ${TASK_DESCRIPTION}" >> progress.md
echo "" >> progress.md
echo "**Status:** Started" >> progress.md
echo "" >> progress.md
echo "**Progress Log:**" >> progress.md
echo "- $(date): Task started" >> progress.md
cd strive

echo "Starting Claude instance for task: ${TASK_NAME}"
echo "Task directory: $(pwd)"

# Launch Claude with proper syntax
claude -p "You are a master iOS app developer working on the Strive project. 

Your current task: ${TASK_DESCRIPTION}

Working directory: $(pwd)

Follow these steps:
1. Update 'progress.md' throughout your work to track progress
2. Implement the requested feature/fix
3. Test your implementation if possible
4. Mark the task as complete in progress.md when finished
5. Push a pull request with the change

Important:
- Work within the current directory context
- Follow iOS development best practices
- Update progress.md regularly with your status

Begin working on: ${TASK_DESCRIPTION}" \
--allowedTools "Bash" "Read" "Write" "Edit" "MultiEdit" "Glob" "Grep" "LS" "Task" \
--disallowedTools "Bash(sudo*)" "Bash(rm*)" &

CLAUDE_PID=$!
echo "Claude instance started with PID: ${CLAUDE_PID}"
echo "${CLAUDE_PID}" > .claude_pid

echo "Task delegation complete. Claude is working on: ${TASK_DESCRIPTION}"
echo "Check progress in: ${TASK_DIR}/progress.md"
