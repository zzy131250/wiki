docker run --rm -v "$PWD:/usr/src/app" -ti wiki-deploy
git add -A && git commit -m "add content" && git push
