docker run -v "$PWD:/usr/src/app" -it wiki-deploy
docker ps -a | awk 'NR==2{print $1}' | xargs docker rm
git add -A && git commit -m "add content" && git push