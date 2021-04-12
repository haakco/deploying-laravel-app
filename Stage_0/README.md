# Stage 0: The different stages to learning how to deploy PHP code

## Intro
This stage will cover simply setting up a simple server and deploying your code.

## Assumptions
1. Php code is in git.
1. You are using MySQL.
    1. If not, replace the MySQL step with your DB of choice.
1. You have a server.
    1. In this example and future ones, we'll be deploying to [DigitalOcean](https://m.do.co/c/179a47e69ec8)
     but the steps should mostly work with any servers.
1. The server is running Ubuntu 20.04
1. You have SSH key pair. 
   1. Needed to securely log into your server. 
1. You have a Domain Name, and you can add entries to point to the server.
   1. We'll be using example.com here. Just replace that with your domain of choice.
   1. I'll be using Cloudflare in these examples.
   1. I would recommend using a DNS provider that is supported by [Terraform](https://www.terraform.io/) and
       [LetsEncrypt](https://community.letsencrypt.org/t/dns-providers-who-easily-integrate-with-lets-encrypt-dns-validation/86438)

## Step 1: Get information needed
Decide on the domain that you would like to use for you server. e.g. www.example.com.

Decide on a name for your server that will be added as a dns entry to point to the server and
will be used while setting up the server.

This is more important for later steps where you'll have more than one server.

This can follow any naming system you want. 

For this example we are going to be boring and use 
the simple ```srv01``` which will then have a domain name of ```srv01.example.com```.

## Step 2: Create virtual server
Log into your [DigitalOcean](https://m.do.co/c/179a47e69ec8) and select the droplets tab.

![DO Droplets Tab](images/DO_droplets_btn.png)

Then click the create button and select Droplets - Create cloud servers.

![DO Create Button](images/DO_create_btn.png)

This will then bring up a page that allows you to create a virtual server.

For the example we are just going to create the smallest server possible, though you may need to select 
a larger one if you need more performance.

Pick are region that is closet to your clients. 

Under additional options select IPv6 and Monitoring.

![DO Create droplet additional options](images/DO_droplet_aditional_options.png)

Under authentication select or add your SSH key.

Now add the hostname with the domain that you chose above as the server hostname. e.g. ```srv01.example.com```

![DO Create droplet hostname](images/DO_droplet_hostname.png)

This will create PTR records pointing back to the servers IP's. Some service use this to 
validate your server, so it's a good idea to get correct.

Now click the create button to finalize.

![DO Create droplet final create](images/DO_droplet_final_create.png)

This will start creating your virtual server and take you to a page showing the creation progress.

Wait for the server to finish being created then continue with the next step.

## Step 3: Setup DNS





