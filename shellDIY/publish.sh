#這個shell因為git add的關係，必須cd到shellDIY資料夾，才可以RUN
read -p "Please keyin your new commit message:" mrshihNewCommitMessage
rake generate
rake deploy
git add ../
git commit -m "${mrshihNewCommitMessage}"
git push origin source
