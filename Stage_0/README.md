# Stage 0: The different stages to learning how to deploy PHP code

## Intro
This stage will cover simply setting up a simple server and deploying your code.

## Assumptions
1. Php code is in git.
2. You are using MySQL.
1. If not, replace the MySQL step with your DB of choice.
3. You have a server.
1. In this example and future ones, we'll be deploying to [DigitalOcean](https://m.do.co/c/179a47e69ec8)
   but the steps should mostly work with any servers.
4. You have a Domain Name, and you can add entries to point to the server.
1. I'll be using Cloudflare in these examples.
2. I would recommend using a DNS provider that is supported by [Terraform](https://www.terraform.io/) and
   [LetsEncrypt](https://community.letsencrypt.org/t/dns-providers-who-easily-integrate-with-lets-encrypt-dns-validation/86438)


