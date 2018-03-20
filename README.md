# Deployment Tracking for chat.OpenShift.io

Build status: [![Build Status](https://ci.centos.org/job/devtools-chat-build-master/badge/icon)](https://ci.centos.org/job/devtools-chat-build-master/)

This is a openshift config tracker repository for the service deployment of chat.OpenShift.io
For documentation about tooling, process and format, please refer to https://github.com/openshiftio/saasherder.

#### The big picture 

We have container definitions under https://github.com/rhdt/mattermost-openshift , from there recent versions are being tracked on https://github.com/CentOS/container-index which are then build on Centos Container Pipeline and getting published into registry.centos.org.

And this repository contains the openshift definitions for deploying those containers on Openshift platform.
