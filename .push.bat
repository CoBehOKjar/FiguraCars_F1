@echo off
setlocal
git add -A

set /p commit_message="Enter comment: "
git commit -m "%commit_message%"

git push origin dev

pause
endlocal