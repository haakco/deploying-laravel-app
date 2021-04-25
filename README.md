# Stage 1: Start automating the server setup
## Intro
This stage follow stage 0 except we'll replace the manual server setup with Ansible.

### Pros
* Repeatable.
* Setup is documented.
* Once you have the ansible script very quick to set up new servers.

### Cons
* Hard not to have a difference between prod and dev
* Missing recommended extra programs, e.g. Redis, Postfix, Centralised logging
* Single point of failure (Only one server)
* No documentation on how the server was set up

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

### [Stage 0](./Stage_0/README.md)
You are new to deploying PHP code to a server.

We'll take you through the quickest and simplest method to get a  server set up, and your code live.

[Follow along here Stage 0](./Stage_0/README.md)

### [Stage 1](./Stage_1/README.md)
Ok we are now going to step up the complexity and automate the setup of the server with ansible.

[Follow along here Stage 1](./Stage_1/README.md)
