# based on https://github.com/gfx/docker-android-project/blob/master/Dockerfile
FROM ubuntu:16.04

MAINTAINER only <server888@yeah.net>

ENV DEBIAN_FRONTEND noninteractive

# Install dependencies
RUN dpkg --add-architecture i386 && \
    apt-get -qq update && \
    apt-get -qqy install libc6:i386 libstdc++6:i386 zlib1g:i386 libncurses5:i386 curl bzip2 xz-utils wget tar unzip git --no-install-recommends && \
    apt-get clean



# Download and Install Open-JDK-8
# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > ${SDK_HOME}/bin/docker-java-home \
	&& chmod +x ${SDK_HOME}/bin/docker-java-home

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

ENV JAVA_VERSION 8u91
#ENV JAVA_DEBIAN_VERSION 8u91-b14-3ubuntu1~16.04.1

# see https://bugs.debian.org/775775
# and https://github.com/docker-library/java/issues/19#issuecomment-70546872
#ENV CA_CERTIFICATES_JAVA_VERSION 20160321

RUN set -x \
	&& apt-get -y update \
	&& apt-get -y install -y openjdk-8-jdk  \
		#openjdk-8-jdk = "$JAVA_DEBIAN_VERSION" \
	        #ca-certificates-java = "$CA_CERTIFICATES_JAVA_VERSION" \
	&& rm -rf /var/lib/apt/lists/* \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]

# see CA_CERTIFICATES_JAVA_VERSION notes above
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

# Install git lfs support.
#RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash

#RUN apt-get -qq update && apt-get install -qqy git-lfs cppcheck ssh file make ccache lib32stdc++6 lib32z1 lib32z1-dev \
# && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install git lfs support.
#RUN git lfs install

# install android sdk
ENV VERSION_SDK_TOOLS "3859397"
ENV ANDROID_HOME="/opt/android/android-sdk-linux"

RUN mkdir -p ${ANDROID_HOME}  && curl -s https://dl.google.com/android/repository/sdk-tools-linux-${VERSION_SDK_TOOLS}.zip > ${ANDROID_HOME}/sdk.zip && \
    unzip ${ANDROID_HOME}/sdk.zip -d ${ANDROID_HOME} && \
    rm -v ${ANDROID_HOME}/sdk.zip

RUN mkdir -p $ANDROID_HOME/licenses/ \
  && echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > $ANDROID_HOME/licenses/android-sdk-license \
  && echo "84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_HOME/licenses/android-sdk-preview-license

# accept android license for sdk.
RUN mkdir -p /root/.android &&  touch /root/.android/repositories.cfg
RUN yes | ${ANDROID_HOME}/tools/bin/sdkmanager --licenses

RUN ${ANDROID_HOME}/tools/bin/sdkmanager --update && \
  (while sleep 3; do echo "y"; done) | ${ANDROID_HOME}/tools/bin/sdkmanager "build-tools;25.0.3" "build-tools;26.0.2" "build-tools;27.0.3" \
  "extras;android;m2repository" "extras;google;m2repository" "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" \
  "platform-tools" "platforms;android-25" "platforms;android-26" "platforms;android-27" "cmake;3.6.4111459"

# Android NDK
# TODO: Use specified NDK version. Use ndk r14b as default.
ENV ANDROID_NDK_VERSION r14b
ENV ANDROID_NDK_HOME="${ANDROID_HOME}/ndk-bundle"

# download
RUN mkdir /opt/android-ndk-tmp && \
    cd /opt/android-ndk-tmp && \
    wget -q https://dl.google.com/android/repository/android-ndk-${ANDROID_NDK_VERSION}-linux-x86_64.zip && \
# uncompress
    unzip -q android-ndk-${ANDROID_NDK_VERSION}-linux-x86_64.zip && \
# move to its final location
    mv ./android-ndk-${ANDROID_NDK_VERSION} ${ANDROID_NDK_HOME} && \
# remove temp dir
    cd ${ANDROID_NDK_HOME} && \
    rm -rf /opt/android-ndk-tmp 
    
RUN echo "y" | /opt/android/android-sdk-linux/tools/android update sdk  --no-ui --all   --filter extra-android-m2repository



# ---- End Android NDK.

RUN echo "SDK Manager Finish."
ENV PATH="${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${ANDROID_NDK_HOME}:${PATH}" 


# Download and unzip Gradle

ENV GRADLE_HOME /opt/gradle
ENV GRADLE_VERSION 4.10.1
ENV GRADLE_SDK_URL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
RUN curl -L "${GRADLE_SDK_URL}" -o gradle-${GRADLE_VERSION}-bin.zip  \
	&& unzip gradle-${GRADLE_VERSION}-bin.zip -d ${GRADLE_HOME}  \
	&& rm -rf gradle-${GRADLE_VERSION}-bin.zip
ENV PATH ${GRADLE_HOME}/gradle-${GRADLE_VERSION}/bin:$PATH

ENV TERM dumb
