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
1. For DNS, I'll be using Cloudflare in these examples.
1. I would recommend using a DNS provider that supports [Terraform](https://www.terraform.io/) and
   [LetsEncrypt](https://community.letsencrypt.org/t/dns-providers-who-easily-integrate-with-lets-encrypt-dns-validation/86438)

## Steps 1-3

These are the same as for [Stage 0](../Stage_0/README.md). So please follow that till the end of Step 3.

We'll then start from Step 4 by using Ansible instead.

## Step 4: Setup the server

For this stage, we are going to automate the server software setup fully.

We are going to be using [Ansible](https://docs.ansible.com/ansible/latest/index.html).

An example of all the ansible scripts for this stage is [here](./ansible).

[./ansible](./ansible)

When creating Ansible scripts, one thing to keep in mind is that they should explain the final state you want.

They should be able to be run multiple times without errors.

While going through the steps to set up Ansible, we'll create separate playbooks for each step.

Though typically, you would create a single playbook to set the server up.

You can find this playbook at ```boostrap.yml```

### Step 4.1: Create your inventory file

In Ansible the first thing you need to set up is an Inventory file.

Ansible uses this file to know where to contact your server. The inventory file puts servers into different
groups so that only specific scripts will run against them.

We'll be using the ini format for now as it's the most common, and we'll use ```hosts.ini``` as the file name.

In their simplest form, the inventory files follow the following pattern.

```server_name ansible_ssh_host=<dns or ip for server>```

Below is an example for the server.

```ini
srv01 ansible_ssh_host = srv01.example.com
```

You can then also assign the servers to groups.

Just so we have an example, we will assign the server to the ```web``` and ```database``` groups.

Using the groups makes more sense if you have multiple servers that have specific characteristics.

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

While we at it, we're also going to add variables specifying our domain, PHP version, and the email that we want to register for
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

First, to run a script with Ansible you need to create a playbook.

The playbook is a file that specifies a filter on what it should run against and then the steps.

If you want to re-use the steps you want to run, you need to create a role.

In simple turns, you take the steps from the playbook and put them into the role.

You then specify which roles the playbook should run.

As we want to make this as re-usable as possible, we will be putting all the steps that should run into roles.

A role follows a specific structure.

First is they are under a directory called roles. The role then has its directory named after the role.

In our case, this will be ```update_server```. Then it expects there to be a subdirectory called ```tasks``` which
contains a file called ```main.yml```

This file will contain the steps you want the role to run.

There are other possible directories other than ```tasks``` that can be in the role. We'll go over them as we need them.

### Step 4.3: Update the server

As with the previous stage, we are going to start by updating the server.

The first thing is to create the role and the ```main.yml``` file.

So first, create the file ```roles/update_server/tasks/main.yml``` in the same directory as your inventory file.

```bash
mkdir -p ./roles/update_server/tasks
touch ./roles/update_server/tasks/main.yml
```

As it's a YAML file, we'll put ```---``` at the top of a file.

Next, we want to run the equivalent of the following command.

```bash
apt update
apt -y autoremove
reboot
```

You can get the documentation for the apt
command [here](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html)

Replace the steps above with the single command below.

```yaml
- name: Update on debian-based distros
  ansible.builtin.apt:
    upgrade: dist
    cache_valid_time: 600
    update_cache: yes
    autoremove: yes
    dpkg_options: 'force-confold,force-confnew'
```

The ```name: Update on debian-based distros``` is the string printed out when it runs that step.

We put this into our ```main.yml``` you can see it here [roles/upgrade_server/tasks/main.yml](ansible/roles/upgrade_server/tasks/main.yml)

Now that we have our first task, we need to create a playbook that will use it.

Here is the basic structure of a playbook

```yaml
---
- hosts: all
  roles:
    - role_name
    - second_role_name
  become: true
  gather_facts: true
```

The above says

```hosts: all``` Run on all hosts in the inventory file.

```become: true``` If you are not root, become root.

```gather_facts: true``` Gather system facts for use in scripts.

```roles:``` Run the list of roles

For the specific playbook, we want to create. We want it to run the ```upgrade_server``` role on all hosts.

To do that, we create the following playbook file, ```./upgrade_servers.yml``` and put the following it in.

```yaml
---
- hosts: all
  roles:
    - upgrade_server
  become: true
  gather_facts: true
```

Then finally, to run out the playbook, we execute the following command from inside the ```./ansible``` directory.

```bash
ansible-playbook -i ./hosts.ini ./upgrade_servers.yml
```

Running the command will upgrade the playbook against all hosts in the inventory file.

If you have many hosts in the file, and you want to limit which it will run against, you can instead run.

```bash
ansible-playbook -i ./hosts.ini ./upgrade_servers.yml -l srv01
```

### Step 4.4: Install the basics to run Laravel

In the following steps, I'll only go over what an ansible command does for the first time its use.

#### Install the database

We'll be adding all of the steps to the following new file ```roles/postgresql/tasks/main.yml```. You can find the
final version [here](./ansible/roles/postgresql/tasks/main.yml)

To install the database, we'll need to add the repository's key, add the repository, install Postgres and
finally, run the commands to create the DB and user.

First lets add the key:

```yaml
- name: Add an PostgreSQL apt key
  ansible.builtin.apt_key:
    keyserver: keyserver.ubuntu.com
    id: 7FCC7D46ACCC4CF8
```

Documentation for [apt_key here](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_key_module.html).

Now let's add the repository.

We also need to get the specific version of Ubuntu that we are using. For this, we can use the Ansible fact
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

Next, we'll install PostgreSQL. We are going to specify the version of PostgreSQL to install so that future runs won't
accidentally upgrade the sever.

For this example, we'll install Redis on the same server, but you can also create a separate role for it if you would like.

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

The command is the same as the one used to update, except here it is installing the programs we need.

Documentation for [apt here](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html).

Finally, we need to create the DB user and database.

To make this simpler, we are going to create the following bash script. Once the bash script has run, it will create
a file ```/root/db_created``` that Ansible will use to know not to run it multiple times.

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

In Ansible, we will copy this file over to the server, making it executable. We'll then run it with the variables to
create the DB and user.

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

The complete ```main.yml``` file is found at ```./roles/nginx_php/tasks/main.yml```.

First, we'll add the required PPA's

```yaml
- name: Add nginx stable repository from PPA and install its signing key on Ubuntu target
  ansible.builtin.apt_repository:
    repo: 'ppa:nginx/stable'
    
- name: Add Onreg PHP PPA
  ansible.builtin.apt_repository:
    repo: 'ppa:ondrej/php'
```

Next, we'll install the required programs.

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

While we are installing PHP, let's also get composer installed.

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

Next, we need to get Nginx to configure and generate certificates.

This time around, we will do it manually as it gives us more control over how SSL and Nginx are configured.

We'll first make sure the directories needed exist and that we remove the default Nginx site config.

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

Next, we are going to use ansible templates as opposed to just copying files over.

The template allows us to use variables in the config.

We'll replace the default nginx.conf with one that some more tuning it.

We'll then set up the primary HTTP site that certbot needs to validate its certificate. We'll also generate dhparams
to increase the SSL security.

We'll then generate the certificates, update Nginx to the final config for Larval.

Finally, we'll set certbot to check if it should update the certificates every week.

I'm not going to go over all the NGINX configs, but you can see the templates here to see what they are doing.

I would also recommend going to look at Mozilla SSL [config recommendations here](https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1d&guideline=5.6).

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

You should now be able to get the test page at https://example.com.

#### Do some PHP Tuning

Last time we didn't tune any of the php.ini files.

This time we are going to make some simple changes to show how to do this.

Once again, we are going to create a separate role and playbook for this.

You can see the complete versions at  ```./roles/php_tuning/tasks/main.yml``` and ```./php_tuning.yml```.

We are going to use the [ansible.builtin.lineinfile](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/lineinfile_module.html)
to make the changes.

Let's start with setting the timezone.

As Ubuntu has separate php.ini files for the client and fpm, you will need to update both.

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

There many setting we may want to tune in the file. Rather than do a command per set, we can instead loop
through a list to change multiple settings. See below for the rest of the settings changed.

I've only shown it for the cli settings, but the role does it for fpm as well.

You can look at the [./roles/php_tuning/tasks/main.yml](./ansible/roles/php_tuning/tasks/main.yml) files to
see an example of other things you may want to change.

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

You may also want to change some settings for fpm. See below for some locations you may want to change.

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

As we have updated the setting for PHP, we need to remember to restart php-fpm.

```yaml
- name: Reload nginx to activate letsencrypt site
  ansible.builtin.service:
    name: "php{{ php_ver }}-fpm"
    state: restarted
```

### Step 4.5: Deploying your application - Final Step

We are almost done with moving to Ansible.

We need to generate our ssh and then git clone our app and run its deployment scripts.

This time around, we aren't going to generate the ssh key pair on the server to make our deployment complicated.

Instead, we will generate a key pair locally and then have Ansible copy them to the server.

This way, if you need to deploy a second server, everything keeps on working.

First, let create the role and the ```main.yml``` file for the deployment. I've put it here.
[./roles/deployment/tasks/main.yml](./roles/deployment/tasks/main.yml).

Next, we want to create the ```files``` directory for this role to store the keys.

Next, we want to generate our keys. (These are explicitly not added to git to make sure no one uses them)

```shell
ssh-keygen -t ed25519 -a 100 -f ./roles/deployment/files/deploy_id_ed25519 -q -N ""
```

Remember to copy the public version to the Github repository.

Ok, now we copy the files over and add git to the known hosts.

```yaml
- name: Copy ssh keys to server
  ansible.builtin.copy:
    src: "{{ item }}"
    dest: "/root/.ssh/{{ item }}"
    owner: root
    group: root
    mode: '0600'
  with_items:
    - deploy_id_ed25519
    - deploy_id_ed25519.pub

- name: Ensure github.com is a known host
  lineinfile:
    dest: /root/.ssh/known_hosts
    create: yes
    state: present
    line: "{{ lookup('pipe', 'ssh-keyscan -t rsa github.com') }}"
    regexp: "^github\\.com"
```

We are going to change one this compared to Stage 0 now.

With GitHub, you can only use a deployment key in one repository. The simplest way to solve this problem is
to create an ssh config that alias GitHub to a name per repository specifying a unique key for that alias.

So we are going to do precisely that with our new key.

Below is an example of the ssh config.

```ssh-config
Host example-alias github.com
  Hostname github.com
  IdentityFile /root/.ssh/deploy_id_ed25519
```

The following will copy the config over. We are using the template so that if we want to have it be dynamic in the
future we can.

```yaml
- name: Create config file for root ssh
  template:
    src: ssh_config.j2
    dest: "/root/.ssh/config"
    owner: root
    group: root
    mode: 0640
```

You use it by replacing the ```github.com``` in your clone command with ```example-alias```.

Now, lest clone our repository like we did in Stage 0. The one thing you will notice is the
```When: bootstrap | default(false)``` This is so if we don't have to delete the directory if we are updating code.

```yaml
- name: Remove directory for clone
  ansible.builtin.file:
    path: /var/www/site
    state: absent
  when: bootstrap | default(false)

- name: Ensure github.com is a known host
  ansible.builtin.lineinfile:
    dest: /root/.ssh/known_hosts
    create: yes
    state: present
    line: "{{ lookup('pipe', 'ssh-keyscan -t rsa github.com') }}"
    regexp: "^github\\.com"
    
- name: Git checkout
  ansible.builtin.git:
    repo: 'git@example-alias:thedevdojo/wave.git'
    dest: /var/www/site
    clone: yes
    depth: 1
    update: yes
    force: yes
```

Finally, we need to copy the .env file over, do a composer install, and an artisan migrates, and we are done.

```yaml
- name: Copy env file over
  ansible.builtin.template:
    src: laravel_env.j2
    dest: "/var/www/site/.env"
    owner: www-data
    group: www-data
    mode: 0640

- name: Make sure the laravle directory is owned by www-data
  ansible.builtin.file:
    path: /var/www
    state: directory
    recurse: yes
    owner: www-data
    group: www-data

- name: Composer install
  become: yes
  become_user: www-data
  ansible.builtin.command:
    chdir: /var/www/site
    cmd: composer install

- name: Run any database migrations
  become: yes
  become_user: www-data
  ansible.builtin.shell:
    chdir: /var/www/site
    cmd: yes | php artisan migrate
```

Done :)

You should now be able to open your URL and see your site.
