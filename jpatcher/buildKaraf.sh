#!/bin/bash

declare -A yipatch
mydir=$HOME
tag='release/beryllium-sr2'
odlbase='https://github.com/opendaylight'
disturl='https://git.opendaylight.org/gerrit/p/integration/distribution.git'
projects=( 'openflowplugin' 'ovsdb' 'sfc' 'netvirt' );
mvnr='/tmp/r'

rm -rf $mvnr

#counting patches
for project in ${projects[@]} ; do
    cd ${mydir}/patches/${project}
    yipatch[${project}]=$(echo *)
done

#getting and patching projects
for project in ${projects[@]} ; do
    rm -rf ${mydir}/${project}
    echo ">>>>Acquiring: $project"
    cd $mydir
    git clone "${odlbase}/${project}.git" $project
    cd ${mydir}/${project}
    git checkout $tag
    for pfil in ${yipatch[$project]} ; do
	echo ">>>>Applying: $pfil on $project"
	patch -p1 < ${mydir}/patches/${project}/${pfil}
    done
done

#building
for project in ${projects[@]} ; do
    echo ">>>>Building: $project"
    cd ${mydir}/${project}
    mvn clean install\
	-Dmaven.repo.local=$mvnr\
	-Dorg.ops4j.pax.url.mvn.localRepository=$mvnr\
	source:jar javadoc:jar -nsu -DskipTests
    rc=$?
    if [[ $rc -ne 0 ]] ; then
        echo 'Build failed: $project'
        exit $rc
    fi
done

#distribution
cd $mydir
git clone $disturl
cd ${mydir}/distribution
git checkout $tag
echo ">>>>Building: distribution-karaf"
mvn clean install\
    -Dmaven.repo.local=$mvnr\
    -Dorg.ops4j.pax.url.mvn.localRepository=$mvnr\
    -Dstream=beryllium -nsu -DskipTests
grc=$?
if [[ $grc -ne 0 ]] ; then
    echo 'Build distribution failed: $grc'
    exit $grc
fi
echo ">>>>READY"
OUTDIR="${mydir}/distribution/distribution-karaf/target"
DIST="distribution-karaf-0.4.2-Beryllium-SR2"
sha256sum -b "${OUTDIR}/${DIST}.tar.gz" > "${OUTDIR}/${DIST}.sha256"
