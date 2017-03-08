#!/bin/bash
set -eu

# tensorflow 0.12.0 の乗った Docker image とコンテナを退避させて
# 1.0.0 の image とコンテナを立ち上げるスクリプト

WORKUSER=""     # Work user name
SSHUSER=""      # SSH user name
DOCKERUSER=""   # Docker user name
DOCKERPASS=""   # Docker user password
JLPORT=""       # jupyter lab port
TBPORT=""       # tensorboard port
SSLDOMAIN=""    # Global domain (SSL)
ORGANIZATION="" # Organization name (ex. OREORE.inc)
COUNTRY=""      # Country code (ex. JP)
IMAGE_ID=""     # ID of docker container on which tensorflow 0.12.0 got on

# コンテナの停止と名前変更
# http://qiita.com/miwato/items/c77c9d07f5babc050250
nvidia-docker stop $DOCKERUSER
nvidia-docker rename $DOCKERUSER $DOCKERUSER0.12.0

# 既存イメージのタグ変更
# http://taker.hatenablog.com/entry/2016/05/04/175021
nvidia-docker tag $IMAGE_ID $DOCKERUSER:0.12.0
nvidia-docker rmi $DOCKERUSER:latest

# 設定
sed -i -e "s/WORKUSER/$WORKUSER/g" \
-e "s/DOCKERUSER/$DOCKERUSER/g" \
-e "s/SSLDOMAIN/$SSLDOMAIN/g" \
-e "s/ORGANIZATION/$ORGANIZATION/g" \
-e "s/COUNTRY/$COUNTRY/g" \
./Dockerfile
sed -i -e "s/DOCKERUSER/$DOCKERUSER/g" ./jl
sed -i -e "s/DOCKERUSER/$DOCKERUSER/g" ./jupyter_notebook_config.py
sed -i -e "s/DOCKERUSER/$DOCKERUSER/g" ./tb

# 新しいイメージ作成
nvidia-docker build -t $DOCKERUSER:latest .

# 新しいコンテナ作成
nvidia-docker run \
-e PASSWORD='DOCKERPASS' \
-p $JLPORT:8888 \
-p $TBPORT:6006 \
-v /home/$SSHUSER/Workspace:/home/$DOCKERUSER/Workspace \
--name $DOCKERUSER \
-u $DOCKERUSER \
-d $DOCKERUSER:latest /usr/local/bin/jl

exit 0
