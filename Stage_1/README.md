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

## Steps 1-3

These are exactly the same as for [Stage 0](../Stage_0/README.md). So please follow that till the end of Step 3.

We'll then start from Step 4 with using ansible instead.

## Step 4: Setup the server

For this stage we are going to fully automate the server software setup.

We are going to be using [Ansible](https://docs.ansible.com/ansible/latest/index.html).

An example of all the ansible scripts for this stage can be found [here](./ansible).

[./ansible](./ansible)

One thing to keep in mind when creating Ansible scritps is that they should explain the state you want to be.

Basically they should be able to be run multiple times without errors.

While going through the steps to setup Ansible we'll be creating seperate playbooks for each step.

Though normally you would create single playbook to set the server up.

You can find this playbook at ```boostrap.yml```

### Step 4.1: Create your inventory file

In Ansible the first thing you need to set up is an Inventory file.

This file is used by ansible to know where to contact your server and can also be used to put servers into different
groups so that only specific scripts will run against them.

We'll be using the ini format for now as it's the most common, and we'll put use ```hosts.ini``` as the file name

In its simplest form the inventory files follows the following pattern.

```server_name ansible_ssh_host=<dns or ip for server>```

Bellow is an example for the server

```ini
srv01 ansible_ssh_host = srv01.example.com
```

You can then also assign the servers to groups.

Just so we have an example we are going to assing the server to the ```web``` and ```database``` groups.

This makes more sense if you have multiple servers that have specific characteristics.

The group format is ```[group_name]```

So our final inventory file will contain this.

```ini
srv01 ansible_ssh_host = srv01.example.com

[web]
srv01

[database]
srv01
```

Finally, we want ssh to use the root user.

You can do this by either setting the variable by host ```ansible_user=root``` or by setting the variable for all host
by using ```[all:vars]```.

While we at it we're also going to add variables specifying our domain, php version, and the email that we want to register for 
LetsEncrypt.

So our ```hosts.ini``` finally becomes.

```ini
srv01 ansible_ssh_host=srv01.example.com

[all:vars]
ansible_user=root
domain_name=example.com
letsencrypt_email=cert@example.com
php_ver=7.4

[web]
srv01

[database]
srv01
```

### Step 4.2: Some quick ansible background

First to run a script with Ansible you need to create a playbook.

This is just basically a file that specifies a filter on what it should run against and then the steps that should run.

If you want to re-use the steps you want to run you need to then create a role.

In simple turns you just take the steps from the play book and put them into the role.

You then specify which roles the play book should run.

As we want to make this as re-usable as possible we are going to be putting all the steps that should run into roles.

A role follow a specific structure.

First is they are under a directory called roles. The role then has its own directory named after the role.

In our case this will be ```update_server```. Then it expects there to be a subdirectory called ```tasks``` which
contains a file called ```main.yml```

This file will contain the steps you want the role to run.

There are other possible directories other than ```tasks``` that can be in the role. We'll go over them as we need them.

### Step 4.3: Update the server

As with the previous stage we are going to start by updating the server.

So first think is to create the role and the ```main.yml``` file.

So first create the file ```roles/update_server/tasks/main.yml``` in the same directory as your inventory file.

```bash
mkdir -p ./roles/update_server/tasks
touch ./roles/update_server/tasks/main.yml
```

As it's a YAML file we'll put ```---``` at the top of a file.

Next we want to run the equivalent of the following command.

```bash
apt update
apt -y autoremove
reboot
```

You can get the documentation for the apt
command [here](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html)

All three steps above can be replaced with the single command bellow.

```yaml
- name: Update on debian-based distros
  ansible.builtin.apt:
    upgrade: dist
    cache_valid_time: 600
    update_cache: yes
    autoremove: yes
```

The ```name: Update on debian-based distros``` is the string that will be printed out when it runs that step.

We put this into our ```main.yml``` you can see it here [roles/upgrade_server/tasks/main.yml](ansible/roles/upgrade_server/tasks/main.yml)

Now that we have our first task we need to create a playbook that will use it.

Here is the basic structure of a play book

```yaml
---
- hosts: all
  roles:
    - role_name
    - second_role_name
  become: true
  gather_facts: true
```

The above basically says 

```hosts: all``` Run on all hosts in the inventory file.

```become: true``` If you are not root become root.

```gather_facts: true``` Gather system facts for use in scripts.

```roles:``` Run the list of roles

For the specific play book we want to create. We want it to run the ```upgrade_server``` role on all hosts.

To do that we create the following playbook file ```./upgrade_servers.yml``` and put the following it in.

```yaml
---
- hosts: all
  roles:
    - upgrade_server
  become: true
  gather_facts: true
```

Then finally to run out play book we execute the following command from inside the ```./ansible``` directory.

```bash
ansible-playbook -i ./hosts.ini ./upgrade_servers.yml
```

This should run the upgrade playbook against all hosts in the inventory file.

If you have many hosts in the file, and you want to limit which it will run against you can rather run.

```bash
ansible-playbook -i ./hosts.ini ./upgrade_servers.yml -l srv01
```

### Step 4.4: Install the basics to run Laravel

In the following steps I'll only go over what an ansible command does for the first time its use.

#### Install the database

We'll be adding all of steps to the following new file ```roles/postgresql/tasks/main.yml```. You can find the
final version [here](./ansible/roles/postgresql/tasks/main.yml)

To install the database we'll need to add the repository's key, add the repository, install postgres and 
finally run the commands to create the db and user.

First lets add the key:

```yaml
- name: Add an PostgreSQL apt key
  ansible.builtin.apt_key:
    keyserver: keyserver.ubuntu.com
    id: 7FCC7D46ACCC4CF8
```

Documentation for [apt_key here](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_key_module.html).

Now let's add the repository.

We also need to get the specific version of ubuntu that we are using. For this we can use the ansible fact
```ansible_distribution_release```.

So the step to add the PostgreSQL repository is:

```yaml
- name: Add postgresql repository
  ansible.builtin.apt_repository:
    repo: "deb https://apt.postgresql.org/pub/repos/apt/ {{ ansible_distribution_release }}-pgdg main"
    state: present
    filename: pgdg.list
```

Documentation for [apt_repository here](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_repository_module.html).

Next we'll install PostgreSQL. We are going to specify the version of PostgreSQL to install os that future runs won't 
accidentally upgrade the sever.

For this example we'll install redis on the same server, but you can also create a separate role for it if you would like.

```yaml
- name: Install PostgresSQL and Redis
  ansible.builtin.apt:
    update_cache: yes
    cache_valid_time: 600
    name:
      - postgresql-13
      - postgresql-client
      - redis
```

This uses the same command we used to do the update, except here it is installing the programs we need.

Documentation for [apt here](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html).

Finally, we need to create the db user and database.

To make this simpler we are going to create the following bash script. Once the bash script it has run it will create
a file ```/root/db_created``` that ansible will use to know not to run it multiple times.

```bash
#!/usr/bin/env bash
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Missing variable should follow the following example"
  echo "./createDb db_example user_example password_example"
  exit
fi

cd /var/lib/postgresql/ || exit

touch /root/db_created
sudo su postgres <<EOF
psql -c "CREATE USER $2 WITH PASSWORD '$3';"
createdb -O$2 -Eutf8 $1;
echo "Postgres database '$1' with user $2 created."
EOF
```

We'll put this script into the ```files``` directory at ```roles/postgresql/files/createDb.sh```

In ansible we will copy this file over to the server making it executable. We'll then run it with the variables to 
create the db and user.

Bellow are the steps to take.
```yaml
- name: Create and setup db
  ansible.builtin.copy:
    src: createDb.sh
    dest: /root/createDb.sh
    owner: root
    group: root
    mode: '0744'
  ansible.builtin.command:
    cmd: /root/createDb.sh db_example user_example password_example
    creates: /root/db_created
```

Finally, we create our playbook and save it to ```postgresql.yml```.

We also limit this playbook to only run on servers in the database group.

```yaml
---
- hosts: database
  roles:
    - postgresql
  become: true
  gather_facts: true
```

The following command will run the playbook.

```bash
ansible-playbook -i ./hosts.ini ./postgresql.yml
```

#### Install the NGINX, PHP and required PHP modules

The complete ```main.yml``` file for this can be found at ```./roles/nginx_php/tasks/main.yml```.

First we'll add the required PPA's

```yaml
- name: Add nginx stable repository from PPA and install its signing key on Ubuntu target
  ansible.builtin.apt_repository:
    repo: 'ppa:nginx/stable'
    
- name: Add Onreg PHP PPA
  ansible.builtin.apt_repository:
    repo: 'ppa:ondrej/php'
```

Next we'll install the required programs.

```yaml
- name: Install NGINX
  ansible.builtin.apt:
    update_cache: yes
    cache_valid_time: 600
    name:
      - nginx

- name: Install PHP and PHP Modules
  ansible.builtin.apt:
    update_cache: yes
    cache_valid_time: 600
    name:
      - php{{ php_ver }}
      - php{{ php_ver }}-cli
      - php{{ php_ver }}-fpm
      - php{{ php_ver }}-bcmath
      - php{{ php_ver }}-common
      - php{{ php_ver }}-curl
      - php{{ php_ver }}-dev
      - php{{ php_ver }}-gd
      - php{{ php_ver }}-gmp
      - php{{ php_ver }}-grpc
      - php{{ php_ver }}-igbinary
      - php{{ php_ver }}-imagick
      - php{{ php_ver }}-intl
      - php{{ php_ver }}-mcrypt
      - php{{ php_ver }}-mbstring
      - php{{ php_ver }}-mysql
      - php{{ php_ver }}-opcache
      - php{{ php_ver }}-pcov
      - php{{ php_ver }}-pgsql
      - php{{ php_ver }}-protobuf
      - php{{ php_ver }}-redis
      - php{{ php_ver }}-soap
      - php{{ php_ver }}-sqlite3
      - php{{ php_ver }}-ssh2
      - php{{ php_ver }}-xml
      - php{{ php_ver }}-zip

- name: Install CertBot
  ansible.builtin.apt:
    update_cache: yes
    cache_valid_time: 600
    name:
      - certbot
      - python3-certbot-nginx
```

While we are installing php let's also get composer installed.

```yaml
- name: Download composer installer
  get_url:
    dest: /usr/src/composer-setup.php
    url: https://getcomposer.org/installer

- name: Download and install Composer
  shell: php /usr/src/composer-setup.php --install-dir=/bin --filename=composer
  args:
    chdir: /usr/src/
    creates: /bin/composer
    warn: false
```

Next we need to get nginx configure and generate certificates.

This time round we are going to do it manually as it gives us more control over how ssl and nginx is configured.

We'll first make sure the directories needed exist and that we remove the default nginx site config.

```yaml
- name: create letsencrypt directory
  ansible.builtin.file:
    name: /var/www/letsencrypt
    state: directory

- name: Remove default nginx config
  ansible.builtin.file:
    name: /etc/nginx/sites-enabled/default
    state: absent
```

Next we are going to use ansible templates as apposed to just coping files over.

This allows us to use variables in the config.

We'll replace the default nginx.conf with one that some more tuning it.

We'll then set up the basic http site that certbot needs to validate its certificate. We'll also generate dhparams
to increase the ssl security.

We'll then generate the certificates, update nginx to the final config for Larval.

Finally, we'll set certbot to check if it should update the certificates every week.

I'm not going to go over all the NGINX configs but you can see the templates here to see what they are all doing.

I would also recommend going to look at Mozilla ssl [config recommendations here](https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1d&guideline=5.6).  

```yaml
- name: Create directory for site
  ansible.builtin.file:
    name: /var/www/site/public
    state: directory

- name: Add index file to test that everything is working
  ansible.builtin.template:
    src: templates/index.html.j2
    dest: /var/www/site/public/index.html
    
- name: Install system nginx config
  template:
    src: templates/nginx.conf.j2
    dest: /etc/nginx/nginx.conf

- name: Install nginx site for letsencrypt requests
  ansible.builtin.template:
    src: templates/nginx-http.j2
    dest: /etc/nginx/sites-enabled/http

- name: Reload nginx to activate letsencrypt site
  ansible.builtin.service:
    name: nginx
    state: restarted

- name: Create letsencrypt certificate
  ansible.builtin.shell: letsencrypt certonly -n --webroot -w /var/www/letsencrypt -m {{ letsencrypt_email }} --agree-tos -d {{ domain_name }} -d www.{{ domain_name }}
  args:
    creates: /etc/letsencrypt/live/{{ domain_name }}

- name: Generate dhparams
  ansible.builtin.shell: openssl dhparam -out /etc/nginx/dhparams.pem 2048
  args:
    creates: /etc/nginx/dhparams.pem

- name: Install nginx site for specified site
  ansible.builtin.template:
    src: templates/nginx-le.j2
    dest: /etc/nginx/sites-enabled/le

- name: Reload nginx to activate specified site
  ansible.builtin.service:
    name: nginx
    state: restarted

- name: Add letsencrypt cronjob for cert renewal
  ansible.builtin.cron:
    name: letsencrypt_renewal
    special_time: weekly
    job: letsencrypt --renew certonly -n --webroot -w /var/www/letsencrypt -m {{ letsencrypt_email }} --agree-tos -d {{ domain_name }} && service nginx reload
```

The following command will run the playbook.

```bash
ansible-playbook -i ./hosts.ini ./nginx_php.yml
```

You should now be able to get the test page at https://example.com

#### Do some PHP Tuning

Last time we didn't tune any of the php.ini files.

This time we are going to make some simple changes to show how to do this.

Once again we are going to create a seperate role and playbook for this.

You can see the complete versions at  ```./roles/php_tuning/tasks/main.yml``` and ```./php_tuning.yml```.

We are going to use the [ansible.builtin.lineinfile](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/lineinfile_module.html) 
to make the changes.

Let's start with setting the timezone. 

As Ubuntu has separate php.ini files for cli and for fpm. You will need to update both.

```yaml
- name: Set date.timezone for CLI
  ansible.builtin.lineinfile:
    dest: /etc/php/{{ php_ver }}/cli/php.ini
    regexp: "^#?date.timezone ="
    line: "date.timezone = UTC"
    backrefs: yes
    state: present

- name: Set date.timezone for FPM
  ansible.builtin.lineinfile:
    dest: /etc/php/{{ php_ver }}/fpm/php.ini
    regexp: "^#?date.timezone ="
    line: "date.timezone = UTC"
    backrefs: yes
    state: present
```

There many setting we may want to tune in the file. Rather than do a command per setting we can rather loop
through a list to change multiple settings. See bellow for the reset of the settings changed.

I've only shown it for the cli settings, but the role does it for fpm as well.

You can look at the [./roles/php_tuning/tasks/main.yml](./ansible/roles/php_tuning/tasks/main.yml) files to
see example of other things you may want to change.

```yaml
- name: Change mulitple setting for php.ini for cli
  lineinfile:
    dest: /etc/php/{{ php_ver }}/cli/php.ini
    regexp: "{{ item.regexp }}"
    line: "{{ item.line }}"
    backrefs: yes
    state: present
  with_items:
    - { regexp: '^#?upload_max_filesize =', line: 'upload_max_filesize = 128M' }
    - { regexp: '^#?post_max_size =', line: 'post_max_size = 128M' }
    - { regexp: '^#?default_charset =', line: 'default_charset = "UTF-8"' }
    - { regexp: '^#?memory_limit =', line: 'memory_limit = 1G' }
    - { regexp: '^#?max_execution_time =', line: 'max_execution_time = 600' }
    - { regexp: '^#?max_input_time =', line: 'max_input_time = 600' }
    - { regexp: '^#?default_socket_timeout =', line: 'default_socket_timeout = 600' }
    - { regexp: '^#?realpath_cache_size =', line: 'realpath_cache_size = 16384K' }
    - { regexp: '^#?realpath_cache_ttl =', line: 'realpath_cache_ttl = 7200' }
    - { regexp: '^#?intl.default_locale =', line: 'intl.default_locale = en' }
    - { regexp: '^#?expose_php =', line: 'expose_php = Off' }
    - { regexp: '^#?opcache.enable =', line: 'opcache.enable = 1' }
    - { regexp: '^#?opcache.enable_cli =', line: 'opcache.enable_cli = 1' }
    - { regexp: '^#?opcache.memory_consumption =', line: 'opcache.memory_consumption = 128' }
    - { regexp: '^#?opcache.interned_strings_buffer =', line: 'opcache.interned_strings_buffer = 16' }
    - { regexp: '^#?opcache.max_accelerated_files =', line: 'opcache.max_accelerated_files = 16229' }
    - { regexp: '^#?opcache.revalidate_path =', line: 'opcache.revalidate_path = 1' }
    - { regexp: '^#?opcache.fast_shutdown =', line: 'opcache.fast_shutdown = 0' }
    - { regexp: '^#?opcache.enable_file_override =', line: 'opcache.enable_file_override = 0' }
    - { regexp: '^#?opcache.validate_timestamps =', line: 'opcache.validate_timestamps = 1' }
    - { regexp: '^#?opcache.revalidate_freq =', line: 'opcache.revalidate_freq = 30' }
    - { regexp: '^#?opcache.save_comments =', line: 'opcache.save_comments = 1' }
    - { regexp: '^#?opcache.load_comments =', line: 'opcache.load_comments = 1' }
    - { regexp: '^#?opcache.dups_fix =', line: 'opcache.dups_fix = 1' }
    - { regexp: '^#?serialize_precision =', line: 'serialize_precision = -1' }
    - { regexp: '^#?precision =', line: 'precision = 16' }
    - { regexp: '^#?display_startup_error =', line: 'display_startup_error = Off' }
```

You may also want to change some settings for fpm. See below for some settings you may want to change.

```yaml
- name: Change setting for fpm
  lineinfile:
    dest: /etc/php/{{ php_ver }}/fpm/pool.d/www.conf
    regexp: "{{ item.regexp }}"
    line: "{{ item.line }}"
    backrefs: yes
    state: present
  with_items:
    - { regexp: '^#?listen.backlog =', line: 'listen.backlog = 65536' }
    - { regexp: '^#?pm.max_children =', line: 'pm.max_children = 16' }
    - { regexp: '^#?pm.start_servers =', line: 'pm.start_servers = 4' }
    - { regexp: '^#?pm.min_spare_servers =', line: 'pm.min_spare_servers = 4' }
    - { regexp: '^#?pm.max_spare_servers =', line: 'pm.max_spare_servers = 8' }
    - { regexp: '^#?pm.max_requests =', line: 'pm.max_requests = 0' }
    - { regexp: '^#?pm.status_path =', line: 'pm.status_path = /fpm-status' }
    - { regexp: '^#?ping.path =', line: 'ping.path = /fpm-ping' }
    - { regexp: '^#?listen = ', line: 'listen = /run/php/php-fpm.sock' }
```

As we have updated setting for php we need to remember to restart php-fpm.

```yaml
- name: Reload nginx to activate letsencrypt site
  ansible.builtin.service:
    name: "php{{ php_ver }}-fpm"
    state: restarted
```

### Step 4.5: Deploying your application - Final Step

We are almost done with moving to ansible.

We just need to generate our ssh and then git clone our app and run its deployment scripts.

This time round we aren't going to generate the ssh key pare on the server as it will make our deployment complicated.

Rather we are going to generate a key pair locally and then have ansible copy them to the server.

This way if you need to deploy a second server everything just keeps on working.

First let creat the role and the ```main.yml``` file for the deployment. I've put it here 
[./roles/deployment/tasks/main.yml](./roles/deployment/tasks/main.yml).

Next we want to create the ```files``` directory for this role to store the keys.

Next we want to generate our keys. (These are explicitly not added to git just to make sure no one uses them)

```shell
ssh-keygen -t ed25519 -a 100 -f ./roles/deployment/files/deploy_id_ed25519 -q -N ""
```


