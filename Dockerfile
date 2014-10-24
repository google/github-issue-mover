# Install a dart container for the Issue Mover for GitHub project.
# Your dart server app will be accessible via HTTP on container port 8080. The port can be changed.
# You should adapt this Dockerfile to your needs.
# If you are new to Dockerfiles please read
# http://docs.docker.io/en/latest/reference/builder/
# to learn more about Dockerfiles.
#
# This file is hosted on GitHub. Therefore you can start it in docker like this:
# > docker build -t githubissuemover github.com/nicolasgarnier/github-issue-mover
# > docker run -p 80:8080 -d githubissuemover

FROM google/dart
MAINTAINER Nicolas Garnier <nivco@google.com>

WORKDIR /app

ADD pubspec.yaml /app/
RUN pub get

ADD web /app/web
RUN pub build

ADD bin /app/bin
RUN pub get --offline

WORKDIR /app
CMD []
ENTRYPOINT ["/usr/bin/dart", "/app/bin/server.dart"]
EXPOSE 8080 8181 5858
