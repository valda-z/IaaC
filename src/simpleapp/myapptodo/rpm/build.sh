#!/bin/bash
echo ">>>> prepare build dir ..."
rm -rf ../rpm/*
rpmdev-setuptree

echo ">>>> git clone ..."
git clone ${GIT_URL} src

echo ">>>> building JAVA ..."
pushd src/${PROJECTDIR}
mvn clean package

echo ">>>> prepare artifacts for RPM build ..."
popd
cp -rf src/${PROJECTDIR}/rpm .
cp -f src/${PROJECTDIR}/target/*.jar .

echo ">>>> building RPM ..."
rpmbuild -ba SPECS/*.spec

echo ">>>> copy RPM to output ..."
for i in *.rpm
do 
    curl -X PUT -T $i -H "x-ms-date: $(date -u)" -H "x-ms-blob-type: BlockBlob" \
    "https://${BLOBSTORAGE}.blob.core.windows.net/${BLOBCONTAINER}/${i}?${SAS}"
    echo "$i"
done

