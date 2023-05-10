#!/bin/bash
sudo yum update -y && sudo yum install -y ecs-init
sudo start ecs
echo ECS_CLUSTER=my-ecs-cluster >> /etc/ecs/ecs.config
echo ECS_CONTAINER_INSTANCE_TAGS={"tag_key": "tag_value"}