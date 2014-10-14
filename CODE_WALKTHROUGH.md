# Code Walk Through

This document will walk you through the code and the deployment options of Issue Mover for GitHub.

## Packages description

TODO

## Deploying your own instance

This app runs in a Docker container and has an [automated Build repo](https://registry.hub.docker.com/u/nicolasgarnier/github-issue-mover) on Docker hub. It can easily be deployed on [Google Compute Engine](https://cloud.google.com/compute/) or on [Google App Engine Managed VM](https://cloud.google.com/appengine/docs/managed-vms/).

### App Setup

If you deploy this app on a _production_ server (i.e. not _localhost_) you need to:

 - [Register a new Github Application](https://github.com/settings/applications/)
 - Set the **Authorization callback URL** to `https://<project_name>.appspot.com/exchange_code`
 - Copy the **Client ID** and **Client Secret** in the **server/credentials.yaml** file

### Google Compute Engine

To create a new [Google Compute Engine](https://cloud.google.com/compute/) instance that is all setup with Dart and the app installed run:

```
gcloud compute instances create <instance_name>
    --image container-vm-v20140929
    --metadata-from-file google-container-manifest=<path_to>/containers.yaml
    --image-project google-containers
    --tags http-server
    --zone us-central1-a
    --machine-type n1-standard-4
```

The command will return - amongst other information - the external IP address of the created instance. You can simply open the IP address in your browser after waiting a bit to give some time to the instance to boot and setup the Docker container. Then the app should be all setup and running.

More details about the command above:

 - `--image` This will install a container optimized disk image/system. Check for the latest version [here](https://cloud.google.com/compute/docs/containers/container_vms).
 - `--metadata-from-file google-container-manifest` points to the app's [containers.yaml](containers.yaml). This will setup [Kubernetes](https://github.com/GoogleCloudPlatform/kubernetes) on the created Mnaged VM instance to download the Docker container directly from the apps's [nicolasgarnier/github-issue-mover automated build repo](https://registry.hub.docker.com/u/nicolasgarnier/github-issue-mover) on Docker hub. Bonus: the app will auto-update when the instance is re-started.
 - `--zone` and `--machine` You can change that to adapt the location and size of the VM instance that is created.
 
You can also run the docker container locally. Running the command below will automatically download the app from its GitHub repo and run it inside a Docker container on your machine:
 
```
docker build -t githubissuemover github.com/google/github-issue-mover
docker run -p 80:8080 -d githubissuemover
```

### Google App Engine

To deploy the app on [Google App Engine Managed VM](https://cloud.google.com/appengine/docs/managed-vms/) run:

`gcloud preview app deploy <path_to>/app.yaml --server=preview.appengine.google.com`

After running the command above you can access your app at **http://\<project_name\>.appspot.com**

To run the app locally:

`gcloud preview app run <path_to>/app.yaml`

#### Environment Setup

Before running the commands above you need to have installed Docker and the gcloud SDK and setup your environment. To do so follow the steps below.

To install Docker have a look at [Docker's install page](https://docs.docker.com/installation/#installation). On Mac OS you can install **boot2docker** at [boot2docker.io](http://boot2docker.io/) then run:

```
boot2docker init
boot2docker up
docker pull google/docker-registry
```

Install the **gcloud SDK and Tools** at [cloud.google.com/sdk/](https://cloud.google.com/sdk/) then run:

```
gcloud components update appengine-managed-vms
gcloud auth login
gcloud config set project <project_name>
gcloud preview app setup-managed-vms
```
