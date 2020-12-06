#!/bin/bash
yum update -y
amazon-linux-extras install docker
# need to reboot because of some aws linux 2 docker daemon not running issue
reboot