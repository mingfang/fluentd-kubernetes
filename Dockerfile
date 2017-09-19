FROM ubuntu:16.04 as base

ENV DEBIAN_FRONTEND=noninteractive TERM=xterm
RUN echo "export > /etc/envvars" >> /root/.bashrc && \
    echo "export PS1='\[\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" | tee -a /root/.bashrc /etc/skel/.bashrc && \
    echo "alias tcurrent='tail /var/log/*/current -f'" | tee -a /root/.bashrc /etc/skel/.bashrc

RUN apt-get update
RUN apt-get install -y locales && locale-gen en_US.UTF-8 && dpkg-reconfigure locales
ENV LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD bash -c 'export > /etc/envvars && /usr/sbin/runsvdir-start'

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute python ssh rsync gettext-base

FROM base as build

RUN apt-get install -y --no-install-recommends build-essential
RUN curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-trusty-td-agent2.sh | sh
RUN /usr/sbin/td-agent-gem install --no-ri --no-rdoc fluent-plugin-kafka 
RUN /usr/sbin/td-agent-gem install --no-ri --no-rdoc zookeeper 
RUN /usr/sbin/td-agent-gem install --no-ri --no-rdoc fluent-plugin-kubernetes_metadata_filter 
RUN /usr/sbin/td-agent-gem install --no-ri --no-rdoc fluent-plugin-elasticsearch

FROM base as final

COPY --from=build /usr/sbin/td-agent /usr/sbin/td-agent
COPY --from=build /opt/td-agent /opt/td-agent

COPY td-agent.conf /etc/td-agent/td-agent.conf

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO
