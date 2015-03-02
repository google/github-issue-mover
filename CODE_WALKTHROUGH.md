# Code Walk Through

This document will walk you through the code and the deployment options of Issue
Mover for GitHub.

## Packages description

The [bin/](bin) directory contains all the server side code while the
[web/](web) directory contains all the client side code. Click through for
further description of the content of each directory.

### App Setup

If you deploy this app on a _production_ server (i.e. not _localhost_) you need to:

 - [Register a new GitHub Application](https://github.com/settings/applications/)
 - Set the **Authorization callback URL** to `https://<project_name>.appspot.com/exchange_code`
 - Copy the **Client ID** and **Client Secret** in the **server/credentials.yaml** file

## Running and deploying

You need to [install boot2docker](http://boot2docker.io/) and then install and
setup the Google Cloud SDK:

```sh
# Get gcloud
$ curl https://sdk.cloud.google.com | bash

# Authorize gcloud and set your default project
$ gcloud auth login
$ gcloud config set project <Project ID>

# Get App Engine component
$ gcloud components update app

# Check that Docker is running
$ boot2docker up
$ $(boot2docker shellinit)

# Download the Dart Docker image
$ docker pull google/dart-runtime
```

To run the app locally:

```sh
$ gcloud preview app run app.yaml
```

To open the app locally visit `http://localhost:8080`.

To deploy the app to production:

```sh
$ gcloud preview app deploy app.yaml
```

To open the app on production visit `http://<Project ID>.appspot.com`.
