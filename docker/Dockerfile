FROM everydayhero/ubuntu:16.04

ENV REPLACE_OS_VARS true
ENV PORT 8080
EXPOSE 8080

ADD "releases/0.0.1/scout.tar.gz" /app
RUN ln -s /app/releases/0.0.1/scout.sh /app/scout.sh

WORKDIR /app
CMD ./scout.sh foreground
