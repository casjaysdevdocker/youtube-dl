## 👋 Welcome to youtube-dl 🚀  

youtube-dl README  
  
  
## Run container

```shell
dockermgr update youtube-dl
```

### via command line

```shell
docker pull casjaysdevdocker/youtube-dl:latest && \
docker run -d \
--restart always \
--name casjaysdevdocker-youtube-dl \
--hostname casjaysdev-youtube-dl \
-e TZ=${TIMEZONE:-America/New_York} \
-v $HOME/Videos/ytdl:/data/video:z \
-v $HOME/Music/ytdl:/data/audio:z \
-v $HOME/.local/share/srv/docker/youtube-dl/files/config:/config:z \
-p 80:80 \
casjaysdevdocker/youtube-dl:latest
```

### via docker-compose

```yaml
version: "2"
services:
  youtube-dl:
    image: casjaysdevdocker/youtube-dl
    container_name: youtube-dl
    environment:
      - TZ=America/New_York
      - HOSTNAME=casjaysdev-youtube-dl
    volumes:
      - $HOME/Videos/ytdl:/data/video:z
      - $HOME/Music/ytdl:/data/audio:z
      - $HOME/.local/share/srv/docker/youtube-dl/files/config:/config:z
    ports:
      - 80:80
    restart: always
```

## Authors  

🤖 casjay: [Github](https://github.com/casjay) [Docker](https://hub.docker.com/r/casjay) 🤖  
⛵ CasjaysDevDocker: [Github](https://github.com/casjaysdevdocker) [Docker](https://hub.docker.com/r/casjaysdevdocker) ⛵  
