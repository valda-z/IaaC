### BASE image - bare base image for RPM build
FROM centos:7.6.1810 as rpm
RUN yum install -y gcc gcc-c++ \
                   libtool libtool-ltdl \
                   make cmake \
                   git \
                   pkgconfig \
                   sudo \
                   automake autoconf \
                   yum-utils rpm-build rpmdevtools && \
    yum clean all

# install JAVA
ENV JAVA_HOME /usr/lib/jvm/java-openjdk

# Install Packages
RUN yum update -y; \
    yum install -y java-1.8.0-openjdk-devel wget unzip curl git vim python-setuptools sudo; \
    easy_install supervisor; \
    yum clean all

ARG MAVEN_VERSION=3.3.9
ARG USER_HOME_DIR="/root"
RUN mkdir -p /usr/share/maven && \
curl -fsSL http://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar -xzC /usr/share/maven --strip-components=1 && \
ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
# speed up Maven JVM a bit
ENV MAVEN_OPTS="-XX:+TieredCompilation -XX:TieredStopAtLevel=1"

ENV BUILDFOLEDR=/home/builder/rpm
ENV HOME=/home/builder
RUN useradd builder -u 1000 -m -G users,wheel && \
    echo "builder ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "# macros"                      >  ${HOME}/.rpmmacros && \
    echo "%_topdir    ${BUILDFOLEDR}" >> ${HOME}/.rpmmacros && \
    echo "%_sourcedir %{_topdir}"        >> ${HOME}/.rpmmacros && \
    echo "%_builddir  %{_topdir}"        >> ${HOME}/.rpmmacros && \
    echo "%_specdir   %{_topdir}"        >> ${HOME}/.rpmmacros && \
    echo "%_rpmdir    %{_topdir}"        >> ${HOME}/.rpmmacros && \
    echo "%_srcrpmdir %{_topdir}"        >> ${HOME}/.rpmmacros && \
    mkdir ${BUILDFOLEDR} && \
    chown -R builder ${HOME}

USER builder
ENV FLAVOR=rpmbuild OS=centos DIST=el7

WORKDIR ${HOME}
COPY --chown=builder:builder ./build.sh .

CMD [ "/bin/bash", "build.sh" ]
