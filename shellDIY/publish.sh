read -p "Please keyin your new commit message:" mrshihNewCommitMessage
rake deploy
git add .
git commit -m "${mrshihNewCommitMessage}"
git push origin source
