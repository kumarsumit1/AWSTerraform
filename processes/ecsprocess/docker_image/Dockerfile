FROM ubuntu:20.04

ARG BUCKET_NAME
ENV BUCKET_NAME = ${BUCKET_NAME}      
ENV JDK_VERSION=11
ENV DEBIAN_FRONTEND noninteractive
ENV APP_USER=ecsuser
ENV APP_WORKDIR=/opt/testapp

# Think carefully before using  --no-install-recommends
# https://askubuntu.com/questions/1216892/what-does-the-no-install-recommends-flag-do-exactly


RUN apt-get -y update && \
    apt-get install -y --show-progress sudo python3-pip \
#     openjdk-${JDK_VERSION}-jdk  \
#     vim-tiny curl iputils-ping net-tools jq \
    && apt-get autoremove && apt-get clean && \
    rm -rf /var/lib/apt/lists/

# ENV JAVA_HOME /usr/lib/jvm/java-${JDK_VERSION}-openjdk-amd64/


RUN groupadd hadoop && \
    useradd -G sudo,hadoop -s /bin/bash -d /home/${APP_USER} -m  -c ${APP_USER} ${APP_USER} && \
    echo "${APP_USER}  ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${APP_USER}

RUN mkdir -p ${APP_WORKDIR}
RUN chown -R ${APP_USER}:${APP_USER} ${APP_WORKDIR}     

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 10

ADD dirver.py requirements.txt  ${APP_WORKDIR}/    

RUN sudo -u ${APP_USER} pip3 install --user -r ${APP_WORKDIR}/requirements.txt

RUN ln -sf bash /bin/sh

USER ${APP_USER}

WORKDIR ${APP_WORKDIR}

#CMD ["python","dirver.py"]


ENTRYPOINT [ "python", "dirver.py"]