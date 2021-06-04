# aws-azkaban

## An AWS based azkaban platform

## Description
AWS Azkaban deploys two containerised versions of [Azkaban](https://azkaban.github.io/azkaban/docs/latest/) that both back onto an AWS EMR cluster along with the peripheral infrastructure required for functionality and security. One of the versions is for users through the Analytical Env and the other for use by admins and engineers (referred to as azkaban_external), that is accessible directly through a URL. The frontend of the service is handled by the webserver containers from which, tasks are sent to and then handled by the executors. An Aurora Serverless database is used to track active executors that can be called by the webservers when needed.

There are 3 lambdas in this repo that carry out administrative tasks:

**1. azkaban-truncate-table:**
Used to truncate the active executors table to ensure no inactive executors are called upon redeployment of the service.

**2. azkaban-zip-uploader:** 
Used to upload .zip files containing Azkaban projects from AWS S3. The lambda is triggered by a `*.success` file being uploaded to a dir in the given S3 and is used to safely access the Azkaban API from within the VPC.

**3. manage-azkaban-mysql-user**
Used to rotate the credentials used to access the Aurora Serverless DB that is mentioned above.

The deployment is handles using Concourse and the pipeline code can be found in the `/ci` directory.

## Development
This repo contains only the IAC and lambdas and these can be developed as they are found. The Azkaban containers themselves can be found [here](https://github.com/dwp/dataworks-hardened-images) along with further documentation on them. The containers are pushed to ECR and called by name by the infrastructure in this repo.

## Secrets in use
Currently two instances of Azkaban are deployed. `user` and `external`. They use differing authentication methods. External uses cognito.
In order to accommodate programmatic access to Azkaban external, a cognito user was created. The details are stored in the `../azkaban_external/cognito` secret.
In order to accommodate programmatic access to Azkaban user, a traditional user is created. The details are stored in the `/workflow_manager` secret.

### Requirements

* Terraform 0.12
* Python 3
* JQ
* Access to Dataworks AWS Environments

### Bootstrapping

Before beginning you will need to generate some Terraform files from templates, to do this you will need to simply run the following:
```bash
make bootstrap
```

You will then be able to develop against the development account (default Terraform workspace)

## High level infrastructure outline

![AWS Azkaban Infrastructure](docs/high_level_design.jpg)

## Azkaban Extensions

**CognitoUserManager** - An extension to the XML UserManager that can also receive a Cognito JSON Web Token. The user manager decodes and validates the token and from this information is able to authenticate the user.

**CognitoUserManagerProxy** - An extension which validates a users name and password against an existing Cognito User Pool using USER_SRP_AUTH type authentication. The pool details are stored in the webservers azkaban.properties

**EMR JobType** - A job type that extends the process job type and can receive the script and arguments that need to be submitted to the cluster. Ensures the correct group that it needs to be run as is submitted along with the script.

