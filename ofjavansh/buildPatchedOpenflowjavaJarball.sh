#!/bin/bash

source /root/env.sh

REPO=${REPO:-openflowplugin}
REPOURL="https://github.com/opendaylight/${REPO}.git"
ODLTAG=${ODLTAG:-'stable/beryllium'}
MVNREM="/tmp/r"
PDIR="${HOME}/patches"
PFIL="openflowplugin_modify_nsh_subtype.patch"

echo "env:"
echo "HOME: ${HOME}"
echo "REPOURL: ${REPOURL}"
echo "REPO: ${REPO}"
echo "ODLTAG: ${ODLTAG}"
echo "-----------------"

cd $HOME
git clone -b $ODLTAG "$REPOURL" $REPO
cd $REPO
patch -p1 < ${PDIR}/${PFIL}
rm -rf $MVNREM
mvn clean install -Dmaven.repo.local=$MVNREM -Dorg.ops4j.pax.url.mvn.localRepository=$MVNREM source:jar javadoc:jar -nsu -DskipTests
