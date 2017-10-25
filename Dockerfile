FROM openshift/base-centos7

MAINTAINER Ed Veretinskas <ed@mits4u.co.uk>

# Inform about software versions being used inside the builder
ENV MAVEN_VERSION="3.5.2" \
    JAVA_VERSION="9.0.1" \
    JAVA_PATCH="11"

ENV JAVA_HOME="/usr/java/jdk-${JAVA_VERSION}" \
    M2_HOME="/usr/local/apache-maven/apache-maven-${MAVEN_VERSION}" \
    JOLOKIA_VERSION="1.3.5" \
    JOLOKIA_ENABLED="false" \
    JOLOKIA_HOME="/opt/jolokia/" \
    APP_ROOT="/opt/app-root/" \
    DEBUG="false"

ENV PATH="${PATH}:${M2_HOME}/bin:${JAVA_HOME}/bin"

# Set labels used in OpenShift to describe the builder images
LABEL   io.openshift.s2i.scripts-url="image:///usr/local/s2i" \
        io.openshift.tags="builder,java,springboots2i" \
        summary="Builder image for creating Spring Boot micro-services" \
        name="openshift-springboot-s2i" \
        java.version="${JAVA_VERSION}" \
        java.architecture="x86_64" \
        java.vendor="mits4u.co.uk"

# Install JAVA_VERSION
RUN wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}+${JAVA_PATCH}/jdk-${JAVA_VERSION}_linux-x64_bin.rpm" \
 && rpm -ivh jdk-${JAVA_VERSION}_linux-x64_bin.rpm \
 && rm -rf jdk-${JAVA_VERSION}_linux-x64_bin.rpm

# Jolokia agent
RUN mkdir -p /opt/jolokia/etc \
 && curl http://central.maven.org/maven2/org/jolokia/jolokia-jvm/${JOLOKIA_VERSION}/jolokia-jvm-${JOLOKIA_VERSION}-agent.jar \
         -o /opt/jolokia/jolokia.jar
ADD jolokia /opt/jolokia/
RUN chmod 775 -R /opt/jolokia

# Install Maven
RUN curl -O http://www-eu.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
 && mkdir -p /usr/local/apache-maven && tar zxvf apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /usr/local/apache-maven \
 && rm -rf apache-maven-${MAVEN_VERSION}-bin.tar.gz \
 && chmod 775 -R /usr/local/apache-maven

# Copy the S2I scripts from ./.s2i/bin/ to /usr/local/s2i when making the builder image
COPY ./.s2i/bin/ /usr/local/s2i
RUN chmod -R 755 /usr/local/s2i

# Drop the root user and make the content of /opt/app-root owned by user 1001
RUN chown -R 1001:1001 ${APP_ROOT}

# Set the default user for the image, the user itself was created in the base image
USER 1001

# Specify the ports the final image will expose
EXPOSE 8080

ADD README.md /usr/local/s2i/usage.txt
CMD [ "/usr/local/s2i/usage" ]
