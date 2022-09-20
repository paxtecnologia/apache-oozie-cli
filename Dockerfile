# FROM golang:1.16-alpine AS build
FROM maven:3.8-jdk-8
# FROM maven:3.8-eclipse-temurin-17
ARG OOZIE_VERSION="5.2.0"
ARG OOZIE_DOWNLOAD_URL="https://archive.apache.org/dist/oozie/$OOZIE_VERSION"
# REF https://www.cloudduggu.com/oozie/installation/

RUN apt update \ 
  && apt install -y zip xmlstarlet

RUN mkdir -p /opt/build/oozie \
  && curl -fsSL -o /tmp/oozie.tar.gz ${OOZIE_DOWNLOAD_URL}/oozie-${OOZIE_VERSION}.tar.gz \
  && tar -xzf /tmp/oozie.tar.gz -C /opt/build/oozie --strip-components=1 \
  && rm -f /tmp/oozie.tar.gz \
  && chmod +x /opt/build/oozie/bin/mkdistro.sh \
  && sed -i 's,<version>0.1.6</version>,<version>0.1.8</version>,g' /opt/build/oozie/fluent-job/fluent-job-api/pom.xml \
  && xmlstarlet ed --inplace -N x=http://maven.apache.org/POM/4.0.0 \
  -s '/x:project/x:repositories' -t elem -n "repository" \
  -s '/x:project/x:repositories/repository[last()]' -t elem -n "id" -v "pentaho"\
  -s '/x:project/x:repositories/repository[last()]' -t elem -n "url" -v "https://public.nexus.pentaho.org/repository/omni" \
  /opt/build/oozie/pom.xml


# RUN mkdir -p /usr/share/oozie \
#   && curl -fsSL -o /tmp/oozie.tar.gz ${OOZIE_DOWNLOAD_URL}/oozie-${OOZIE_VERSION}.tar.gz \
#   && tar -xzf /tmp/oozie.tar.gz -C /usr/share/oozie --strip-components=1 \
#   && rm -f /tmp/oozie.tar.gz \
#   && chmod +x /usr/share/oozie/bin/mkdistro.sh \
#   && sed -i 's,<version>0.1.6</version>,<version>0.1.8</version>,g' /usr/share/oozie/fluent-job/fluent-job-api/pom.xml \
#   && xmlstarlet ed --inplace -N x=http://maven.apache.org/POM/4.0.0 \
#   -s '/x:project/x:repositories' -t elem -n "repository" \
#   -s '/x:project/x:repositories/repository[last()]' -t elem -n "id" -v "pentaho"\
#   -s '/x:project/x:repositories/repository[last()]' -t elem -n "url" -v "https://public.nexus.pentaho.org/repository/omni" \
#   /usr/share/oozie/pom.xml
# && sed -i 's,<hive.version>1.2.2</hive.version>,<hive.version>2.3.9</hive.version>,g' /usr/share/oozie/pom.xml
#   && chmod +x /usr/share/oozie/distro/src/main/bin/oozie-setup.sh \
#   && chmod +x /usr/share/oozie/client/src/main/bin/oozie 
#   && ln -s /usr/share/oozie/client/src/main/bin/oozie /usr/bin/oozie


RUN --mount=type=cache,id=m2-cache,sharing=shared,target=/root/.m2 \
  /opt/build/oozie/bin/mkdistro.sh -DskipTests

RUN mkdir -p /opt/distro/oozie \
  && tar -xzf /opt/build/oozie/distro/target/oozie-${OOZIE_VERSION}-distro.tar.gz -C /opt/distro/oozie \
  && find /opt/distro/oozie

# RUN mkdir -p /usr/share/oozie \
#   && tar -xzf /opt/build/oozie/distro/target/oozie-${OOZIE_VERSION}-distro.tar.gz -C /usr/share/oozie \
#   find /usr/share/oozie

# RUN /usr/share/oozie/distro/src/main/bin/oozie-setup.sh sharelib create -fs ${FS_URI}
# RUN /usr/share/oozie/client/src/main/bin/oozie