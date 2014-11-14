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

FROM google/dart-runtime
MAINTAINER Nicolas Garnier <nivco@google.com>
