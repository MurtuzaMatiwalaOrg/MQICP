# Origin

this repository is from the original ibm-messaging/mq-docker repository on github

# Overview

This repository contains a Dockerfile and some scripts which demonstrate a way in which you might run IBM MQ in a [Docker](https://www.docker.com/whatisdocker/) container.

# Building the image

The image can be built using standard [Docker commands](https://docs.docker.com/userguide/dockerimages/) against the supplied Dockerfile.  For example:

~~~
cd MQICP
docker build -t mqimage .
~~~

This will create an image called mqimage in your local docker registry.

# What the image contains

The built image contains a full installation of [IBM MQ V9.0].  

# Running a container

After building a Docker image from the supplied files, you can [run a container](https://docs.docker.com/userguide/usingdocker/) which will create and start an MQ Queue Manager along with MQ objects imported into the Queue Manager.

In order to run a container from this image, it is necessary to accept the terms of the IBM Integration Bus for Developers license.  This is achieved by specifying the environment variable `LICENSE` equal to `accept` when running the image.  You can also view the license terms by setting this variable to `view`. Failure to set the variable will result in the termination of the container with a usage statement.  You can view the license in a different language by also setting the `LANG` environment variable.

The last important point of configuration when running a container from this image, is port mapping.  The Dockerfile exposes ports `1414` and `9883` for MQ by default, for Integration Node administration and Integration Server HTTP traffic respectively.  This means you can run with the `-P` flag to auto map these ports to ports on your host.  Alternatively you can use `-p` to expose and map any ports of your choice.

For example:

~~~
docker run --name myNode -e LICENSE=accept -e NODENAME=MYNODE -P iibv10image -e MQ_QMGR_NAME=MQ1
~~~

This will run a container that creates and starts an Integration Node called `MYNODE` and exposes ports `4414` and `7800` on random ports on the host machine. It also creates a queue manager called `MQ1` and starts this queue manager with some default queues defined.
For more information on configuring MQ please see [README.md](https://github.com/ibm-messaging/mq-docker/blob/master/README.md) for the standalone MQ container.

At this point you can use:
~~~
docker port <container name>
~~~

to see which ports have been mapped then connect to the Node's web user interface as normal (see [verification](# Verifying your container is running correctly) section below).

### Running administration commands

You can run any of the MQ commands using one of two methods:

##### Directly in the container

Attach a bash session to your container and execute your commands as you would normally:

~~~
docker exec -it <container name> /bin/bash
~~~

At this point you will be in a shell inside the container and run your commands.

##### Using Docker exec

Use Docker exec to run a non-interactive Bash session that runs any of the MQ commands.  For example:

~~~
docker exec <container name> /bin/bash -c runmqsc
~~~

### Accessing logs

This image also configures syslog, so when you run a container, your node will be outputting messages to /var/log/syslog inside the container.  You can access this by attaching a bash session as described above or by using docker exec.  For example:

~~~
docker exec <container id> tail -f /var/log/syslog
~~~

# Verifying your container is running correctly

Whether you are using the image as provided or if you have customised it, here are a few basic steps that will give you confidence your image has been created properly:

1. Run a container, making sure to expose port 1414 and 9443 to the host - the container should start without error
2. Access syslog as descried above - there should be no errors
3. Connect to a browser and connect via HTTPS to port 9443 to run the MQ administration console.

At this point, your container is running and you can start using MQ running as a container.


# License

The Dockerfile and associated scripts are licensed under the [Eclipse Public License 1.0](./LICENSE). 
IBM MQ Advanced for Developers is licensed under the IBM International License Agreement for Non-Warranted Programs. This license may be viewed from the image using the LICENSE=view environment variable as described above or may be found online. Note that this license does not permit further distribution.
