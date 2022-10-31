ARG OOZIE_VERSION="5.2.1"
ARG OOZIE_DOWNLOAD_URL="https://archive.apache.org/dist/oozie/$OOZIE_VERSION"
ARG GPLEXTRAS_URL=http://archive.cloudera.com/gplextras/misc/
ARG GPLEXTRAS_VERSION=2.2

FROM maven:3.8-openjdk-8 AS build
LABEL origin-build-file="https://github.com/carlossg/docker-maven/blob/0da0b5395ec5f2884a84239b62646bc1b0a8bb43/libericaopenjdk-8-debian/Dockerfile"
ARG OOZIE_VERSION
ARG OOZIE_DOWNLOAD_URL
ARG GPLEXTRAS_URL
ARG GPLEXTRAS_VERSION

RUN apt update \ 
  && apt install -y zip xmlstarlet

RUN mkdir -p /opt/build/oozie \
  && curl -fsSL -o /tmp/oozie.tar.gz ${OOZIE_DOWNLOAD_URL}/oozie-${OOZIE_VERSION}.tar.gz \
  && tar -xzf /tmp/oozie.tar.gz -C /opt/build/oozie --strip-components=1 \
  && rm -f /tmp/oozie.tar.gz \
  && chmod +x /opt/build/oozie/bin/mkdistro.sh\
  && sed -i 's,<version>0.1.6</version>,<version>0.1.8</version>,g' /opt/build/oozie/fluent-job/fluent-job-api/pom.xml \
  && xmlstarlet ed --inplace -N x=http://maven.apache.org/POM/4.0.0 \
  -s '/x:project/x:repositories' -t elem -n "repository" \
  -s '/x:project/x:repositories/repository[last()]' -t elem -n "id" -v "pentaho"\
  -s '/x:project/x:repositories/repository[last()]' -t elem -n "url" -v "https://public.nexus.pentaho.org/repository/omni" \
  /opt/build/oozie/pom.xml

RUN --mount=type=cache,id=m2-cache,sharing=shared,target=/root/.m2 \
  /opt/build/oozie/bin/mkdistro.sh -DskipTests

RUN  mkdir -p /opt/build/oozie/distro/target/oozie-${OOZIE_VERSION}-distro/oozie-${OOZIE_VERSION}/libext \
  && curl -fsSL -o /tmp/ext.zip ${GPLEXTRAS_URL}/ext-${GPLEXTRAS_VERSION}.zip \
  && cp /tmp/ext.zip /opt/build/oozie/distro/target/oozie-${OOZIE_VERSION}-distro/oozie-${OOZIE_VERSION}/libext \
  && tar -xzf /opt/build/oozie/distro/target/oozie-${OOZIE_VERSION}-distro/oozie-${OOZIE_VERSION}/oozie-client-${OOZIE_VERSION}.tar.gz -C /tmp

FROM bellsoft/liberica-openjdk-debian:8
ARG OOZIE_VERSION
ARG OOZIE_DOWNLOAD_URL
ARG GPLEXTRAS_URL
ARG GPLEXTRAS_VERSION
RUN mkdir -p /usr/local/oozie

COPY --from=build /tmp/oozie-client-${OOZIE_VERSION} /usr/local/oozie

ENV OOZIE_HOME /usr/local/oozie
ENV PATH "$PATH:/usr/local/oozie/bin"