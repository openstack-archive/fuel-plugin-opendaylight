
FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y apt-utils build-essential git libmaven-jar-plugin-java libmaven-javadoc-plugin-java\
    libxml-xpath-perl maven openjdk-8-jdk python-software-properties software-properties-common\
    sudo wget

RUN echo "ALL ALL=NOPASSWD: ALL" > /etc/sudoers.d/open-sudo
RUN chmod 0440 /etc/sudoers.d/open-sudo

ENV HOME=/root
ADD ./patches /root/patches
ADD settings.xml /root/.m2/settings.xml

ADD ./env.sh /root/env.sh
ADD ./buildPatchedOpenflowjavaJarball.sh /root/buildPatchedOpenflowjavaJarball.sh
RUN chmod +x /root/buildPatchedOpenflowjavaJarball.sh
RUN /root/buildPatchedOpenflowjavaJarball.sh
