# © Copyright IBM Corporation 2015.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

FROM ubuntu:14.04

MAINTAINER Sam Rogers srogers@uk.ibm.com

# Install packages
RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    bash \
    bc \
    coreutils \
    curl \
    debianutils \
    findutils \
    gawk \
    grep \
    libc-bin \
    lsb-release \
    mount \
    passwd \
    procps \
    rpm \
    sed \
    tar \
	util-linux 

RUN rm -rf /var/lib/apt/lists/*

RUN apt-get dist-upgrade -y

#Install MQ

ARG MQ_URL=http://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/mqadv_dev903_linux_x86-64.tar.gz
ARG MQ_PACKAGES="MQSeriesRuntime-*.rpm MQSeriesServer-*.rpm MQSeriesMsg*.rpm MQSeriesJava*.rpm MQSeriesJRE*.rpm MQSeriesGSKit*.rpm MQSeriesWeb*.rpm"

RUN mkdir -p /tmp/mq \
  	&& cd /tmp/mq \
  	&& curl -LO $MQ_URL \
	&& tar -zxvf ./*.tar.gz \
	
	&& groupadd --gid 1000 mqm \
  	&& useradd --create-home --home-dir /home/mqm --uid 1000 --gid mqm mqm \
  	&& usermod -G mqm root \
	&& cd /tmp/mq/MQServer \
	
	# Accept the MQ license
  	&& ./mqlicense.sh -text_only -accept \
  	# Install MQ using the RPM packages
  	&& rpm -ivh --force-debian $MQ_PACKAGES \
  	# Recommended: Set the default MQ installation (makes the MQ commands available on the PATH)
  	&& /opt/mqm/bin/setmqinst -p /opt/mqm -i \
  	# Clean up all the downloaded files
  	&& rm -rf /tmp/mq \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/mqm \
	&& sed -i 's/PASS_MAX_DAYS\t99999/PASS_MAX_DAYS\t90/' /etc/login.defs \
  	&& sed -i 's/PASS_MIN_DAYS\t0/PASS_MIN_DAYS\t1/' /etc/login.defs \
	&& sed -i 's/password\t\[success=1 default=ignore\]\tpam_unix\.so obscure sha512/password\t[success=1 default=ignore]\tpam_unix.so obscure sha512 minlen=8/' /etc/pam.d/common-password
	
	COPY mq-dev-config.sh mq-license-check.sh mq.sh setup-mqm-web.sh setup-var-mqm.sh /usr/local/bin/
	COPY *.mqsc /etc/mqm/
	COPY admin.json /etc/mqm/

	COPY mq-dev-config /etc/mqm/mq-dev-config

RUN chmod +x /usr/local/bin/*.sh

COPY mq_manage.sh /usr/local/bin/
RUN chmod +rx /usr/local/bin/*.sh && \
 chmod 666 /etc/hosts

# Expose default admin port and http port, plus MQ ports
EXPOSE 1414 9443

# Set entrypoint to run management script
ENTRYPOINT ["mq_manage.sh"]
