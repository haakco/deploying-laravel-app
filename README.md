# Deploying a Laravel Application
## Intro
I've noticed recently that several people seem to be struggling with the correct way to deploy a Laravel
application.

This isn't that surprising with all the conflicting information out there.

Also quiet a bit of the information is trying to get people to start with the most complicated deploys,
which with the quantity of new things to learn in one go make it incredible difficult.

So I've written these tutorial on how to deploy starting from the most simple and then adding each
new technology to eventually get you to the more complicated deployments.

The idea is to give people a place to start and some real work examples.

This isn't meant to cover everything but should cover most of what you need.

Every section has a fully working deployment.

You just need to replace the ```example.com``` domain with your own.

Feel free to jump around or stop at any of the stages.

Unlike what you will get told on the internet. There is no single method that works for everyone.

I'm sure that even the examples I have provided will not be optimal for come companies :).

## Assumptions
1. Php code is in git.
1. You are using PostgreSQL.
  1. If not, replace the PostgreSQL step with your DB of choice.
1. You have a server.
1. In this example and future ones, we'll be deploying to [DigitalOcean](https://m.do.co/c/179a47e69ec8)
   but the steps should mostly work with any servers.
1. The server is running Ubuntu 20.04
1. You have SSH key pair.
  1. Needed to log into your server securely.
1. You have a Domain Name, and you can add entries to point to the server.
  1. We'll be using example.com here. Just replace that with your domain of choice.
1. For DNS I'll be using Cloudflare in these examples.
  1. I would recommend using a DNS provider that supports [Terraform](https://www.terraform.io/) and
     [LetsEncrypt](https://community.letsencrypt.org/t/dns-providers-who-easily-integrate-with-lets-encrypt-dns-validation/86438)

### [Stage 1: Simple deploy](https://github.com/haakco/deploying-laravel-app-stage1-simple-deploy)
You are new to deploying PHP code to a server.

We'll take you through the quickest and simplest method to get a  server set up, and your code live.

[Follow along here Stage 1](https://github.com/haakco/deploying-laravel-app-stage1-simple-deploy/README.md)

### [Stage 2: Simple deploy with ansible](https://github.com/haakco/deploying-laravel-app-stage2-simple-with-ansible-deploy)
Ok we are now going to step up the complexity and automate the setup of the server with ansible.

[Follow along here Stage 2](https://github.com/haakco/deploying-laravel-app-stage2-simple-with-ansible-deploy)

### [Stage 3: : Simple deploy with ansible and Terraform](https://github.com/haakco/deploying-laravel-app-stage3-simple-with-ansible-terraform-deploy)
With this stage we are going to continue with our automation and automate the full infrastructure setup
using terraform and packer to build our images.

[Follow along here Stage 3](https://github.com/haakco/deploying-laravel-app-stage3-simple-with-ansible-terraform-deploy)

### [Stage 4: Docker and Terraform deploy](https://github.com/haakco/deploying-laravel-app-stage4-docker-terraform-deploy)
For this stage, we'll move to create docker containers. Having versioned containers makes it simpler, role forward and backwards.
It also gives us a way to test locally on a system that is close to production.

[Follow along here Stage 4](https://github.com/haakco/deploying-laravel-app-stage4-docker-terraform-deploy)

### [Stage 5: Kubernetes and Terraform deploy](https://github.com/haakco/deploying-laravel-app-stage5-docker-kubernetes-terraform-deploy)
This stage covers how to deploy to kubernetes and set up a local kubernetes development enviroment. 

[Follow along here Stage 5](https://github.com/haakco/deploying-laravel-app-stage5-docker-kubernetes-terraform-deploy)
