#!/bin/bash
echo deleting old backup files...
rm -rf old/
echo backing up old files...
mkdir old
mv java web old
echo checking if file still works...

status_code=$(curl -L --write-out %{http_code} --silent --output /dev/null https://raw.githubusercontent.com/LAX1DUDE/eaglercraft/main/stable-download/stable-download.zip)

if [[ "$status_code" -ne 200 ]] ; then
  echo site is down! using backup files...
  cp old/java old/web ./
else
  echo site is still up! downloading...
  curl -L -o stable-download.zip https://raw.githubusercontent.com/LAX1DUDE/eaglercraft/main/stable-download/stable-download.zip
  echo extracting zip...
  unzip stable-download.zip
  echo deleting original zip file...
  rm -rf stable-download.zip
fi

echo verifying files...
if [ -d "java" -a -d "web" ]; then
    echo files exist! proceeding...
else
    echo files do not exist! using backup files...
    cp old/java old/web ./
fi

#todo: detect modified files
if [ -d "java/bukkit_command" -a -d "/java/bungee_command" ]; then
    echo restoring servers from backup so you dont lose data...
    rm -rf java/*
    cp old/java/* ./java/
fi

echo ensuring that bungeecord is hosting on port 8069...
sed -i 's/host: 0\.0\.0\.0:25565/host: 0.0.0.0:8069/' java/bungee_command/config.yml

echo starting bungeecord...
cd java/bungee_command
java -Xmx32M -Xms32M -jar bungee-dist.jar > /dev/null 2>&1 &
cd -

echo configuring local website...
sed -i 's/https:\/\/g\.eags\.us\/eaglercraft/https:\/\/gnome\.vercel\.app/' web/index.html
sed -i 's/alert/console.log/' web/index.html
echo setting default server...
sed -i 's/"CgAACQAHc2VydmVycwoAAAABCAACaXAAJHdzczovL2cuZWFncy51cy9lYWdsZXJjcmFmdC9jcmVhdGl2ZQgABG5hbWUAFGVhZ2xlcmNyYWZ0IGNyZWF0aXZlAQALaGlkZUFkZHJlc3MACAAKZm9yY2VkTU9URAAhdGhpcyBpcyBtZWFudCB0byBiZSBhIGRlbW8gc2VydmVyAAA="/btoa(atob("CgAACQAHc2VydmVycwoAAAABCAAKZm9yY2VkTU9URABtb3RkaGVyZQEAC2hpZGVBZGRyZXNzAQgAAmlwAGlwaGVyZQgABG5hbWUAbmFtZWhlcmUAAA==").replace("motdhere",String.fromCharCode("Your Minecraft Server".length)+"Your Minecraft Server").replace("namehere",String.fromCharCode("Minecraft Server".length)+"Minecraft Server").replace("iphere",String.fromCharCode(("ws"+location.protocol.slice(4)+"\/\/"+location.host+"\/server").length)+("ws"+location.protocol.slice(4)+"\/\/"+location.host+"\/server")))/' web/index.html

echo starting nginx...
mkdir /tmp/nginx
rm -rf nginx.conf
sed "s/eaglercraft-server/$REPL_SLUG/" nginx_template.conf > nginx.conf
nginx -c ~/$REPL_SLUG/nginx.conf -g 'daemon off; pid /tmp/nginx/nginx.pid;' -e /tmp/nginx/error.log > /dev/null 2>&1 &

echo starting bukkit...
cd java/bukkit_command
java -Xmx1024M -Xms1024M -jar craftbukkit-1.5.2-R1.0.jar
cd -

echo killing bungeecord and nginx...
pkill java
pkill nginx

echo done!