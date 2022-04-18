#!/bin/bash

# 设置运行容器的名称
CONTAINER=${container_name}
PORT=${port}

# 使用docker build进行构建
# 使用--no-cache参数，保证每次不使用缓存
docker build --no-cache -t ${image_name}:${tag} .

# RUUNING变量去记录docker容器的运行状态
# 用于后面的判断
RUNNING=$(docker inspect --format="{{ .State.Running }}" $CONTAINER 2>/dev/null)

if [ ! -n $RUNNING ]; then
  echo "$CONTAINER does not exist."
  return 1
fi

# 这里是指容器已经创建，但是没有运行，可能是人工手动停止了。
# 或者是docker daemon重启后，容器停止了
if [ "$RUNNING" == "false" ]; then
  echo "$CONTAINER is not running."
  return 2
else
  echo "$CONTAINER is running"
  # 删除同名容器
  matchingStarted=$(docker ps --filter="name=$CONTAINER" -q | xargs)
  if [ -n $matchingStarted ]; then
    # 删除同名容器，先停止
    docker stop $matchingStarted
  fi

  matching=$(docker ps -a --filter="name=$CONTAINER" -q | xargs)
  if [ -n $matching ]; then
    # 删除同名容器，再删除
    docker rm $matching
  fi
fi

# 创建容器
# 注意这里的80端口，与自己的EXPOSE指定的端口要一致
docker run -itd --name $CONTAINER -p $PORT:80 ${image_name}:${tag}
