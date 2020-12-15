# aws-azkaban

## An AWS based azkaban platform

## Description

## Local Development

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

**Cognito UserManager** - An extension to the XML UserManager that can also receive a Cognito JSON Web Token. The user manager decodes and validates the token and from this information is able to authenticate the user.

**EMR JobType** - A job type that extends the process job type and can receive the script and arguments that need to be submitted to the cluster. Ensures the correct group that it needs to be run as is submitted along with the script.

