# The different stages to learning how to deploy a Laravel application

## Intro
This code covers the different stages in learning how to deploy a PHP app to production.

They are a companion to the talk **The different stages to learning to deploy code**

The idea is to take people from not knowing how to deploy code to fully automated deployment.

Instead, it's to give developers a graceful path to learn how to deploy apps to live servers.

Each stage builds on the previous step and attempts not to introduce too many new concepts. We are hopefully keeping the learning curve at a fun but manageable pace.

The initial stages are for people who are new to deploying applications to servers.

If you are new, please ignore all the latest magical way to deploy things like Kubernetes etc.
We will get there, but if you try to jump to that from the go, you'll most likely overwhelm yourself.

So please, if you are new to deploying code, start with the earlier stages.

If you are already comfortable with this, I would recommend just skipping ahead to the final stage.

## Stages

## Assumptions
1. Php code is in git.
2. You are using PostgreSQL.
1. If not, replace the PostgreSQL step with your DB of choice.
3. You have a server.
1. In this example and future ones, we'll be deploying to [DigitalOcean](https://m.do.co/c/179a47e69ec8)
   but the steps should mostly work with any servers.
4. You have a Domain Name, and you can add entries to point to the server.
1. I'll be using Cloudflare in these examples.
2. I would recommend using a DNS provider that supports
   [Terraform](https://www.terraform.io/) and
   [LetsEncrypt](https://community.letsencrypt.org/t/dns-providers-who-easily-integrate-with-lets-encrypt-dns-validation/86438)


### Stage 0
You are new to deploying PHP code to a server.

We'll take you through the quickest and simplest method to get a  server set up, and your code live.

[Follow along here](./Stage_0/README.md)
