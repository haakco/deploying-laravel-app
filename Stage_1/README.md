# Stage 1: The different stages to learning how to deploy a Laravel App

## Intro
This stage will cover simply setting up a simple server and deploying your code.

### Pros
* Simple
* Get to learn what for future stages
* Up and running quickly

### Cons
* Not repeatable
* Hard not to have a difference between prod and dev
* Missing recommended extra programs, e.g. Redis, Postfix, Centralised logging
* Single point of failure (Only one server)
* No documentation on how the server was setup

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

## Steps 1-2
