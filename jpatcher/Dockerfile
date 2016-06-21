
FROM ubuntu:16.04
RUN apt-get update
RUN apt-get install -y apt-utils build-essential git libmaven-deploy-plugin-java\
                   libmaven-install-plugin-java libmaven-install-plugin-java-doc\
                           libmaven-jar-plugin-java libmaven-javadoc-plugin-java\
                libxml-xpath-perl maven openjdk-8-jdk python-software-properties\
             software-properties-common sudo wget curl
RUN echo "ALL ALL=NOPASSWD: ALL" > /etc/sudoers.d/open-sudo
RUN chmod 0440 /etc/sudoers.d/open-sudo
RUN useradd -ms /bin/bash ubuntu
WORKDIR /home/ubuntu
ADD settings.xml /home/ubuntu/.m2/settings.xml
ADD buildKaraf.sh /home/ubuntu/buildKaraf.sh
add patches /home/ubuntu/patches
RUN chmod +x /home/ubuntu/buildKaraf.sh
RUN chown -R ubuntu:ubuntu .
USER ubuntu
RUN /home/ubuntu/buildKaraf.sh
