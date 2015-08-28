Beaver
=======
Beaver is a deployment management system, to manage and deploy all of your sites in one command.
It's utilize [Capistrano](https://github.com/capistrano/capistrano/blob/master/README.md) which is a Remote multi-server automation tool based on Ruby [Rake](http://rake.rubyforge.org/).

A successful deployment with Beaver will result in a directory structure like the following:

``` sh
site
├── current
├── releases
├── repo
└── shared
```

Each time you deploy,

The `repo` folder will be synced with the last version of the site from the remote repository.

A new directory will be created under the `releases` directory, and the new version of the site will be placed there. 

The `current` folder is a symbolic link, and it will point to the new release directory whenever you will create a new release.


Installation
-------------------

### Windows 7

1. Clone the Beaver project into your favorite directory

2. Install RubyGems

RubyGems is a package manager for the Ruby libraries. Download RubyGems for windows, you can get it [here](http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-1.9.3-p484.exe?direct).

Run it.

The installation will add `ruby` and `gem` environment variables into your system path.

If not just run 

``` sh
$ set PATH=C:\Ruby193\bin;%PATH%
```

3. Install Capistrano: 

``` sh
$ gem install capistrano -v 3.0.1
```


### OSX

1. Clone the Beaver project

2. Install Capistrano: 

``` sh
$ sudo gem install capistrano -v 3.0.1
```



Folder structure
-------------------

Cloning the Beaver project will create the following folder structure:

``` sh
beaver/
│
├── Capfile
├── beaver.rb
├── deploy.rb
├── config/
│   └── deploy/
│     	 ├── examples/
│    	 │		├── sandbox.rb
│        │		├── qa.rb
│        │		├── staging.rb
│        │		└── production.rb
│		 │
│        └──.gitignore
│
├── sites/
│
└── lib
```

Configuration
-------------------

In order to configure your servers and ssh keys, you will have to add environments config files 
under the `C:\beaver\config\deploy` folder... 

Go to the examples folder:

``` sh
$ cd C:\beaver\config\deploy\examples

```

Under that folder you can find server configurations, divided into environments files.
Within each environment file, you will find a list, of all it's related severs, for example:

``` ruby
server 'ec2-50-19-45-59.compute-1.amazonaws.com', user: 'ubuntu', roles: %w{web app db}
``` 

The above, defines the server host, the user, and it's roles. 

All you need to do is to copy the files that you need into the `C:\yourfolder\config\deploy` folder and declare the servers 
that will take part in the deployment process!

You can declare as many servers as you want, but, if all of the server share the same database, be sure to add the `db` role,
only on the primary server(the top most server)

``` ruby
server 'ec2-50-19-45-59.compute-1.amazonaws.com', user: 'ubuntu', roles: %w{web app db}
server 'ec2-50-16-63-231.compute-1.amazonaws.com', user: 'ubuntu', roles: %w{web app}
server 'ec2-54-227-115-121.compute-1.amazonaws.com', user: 'ubuntu', roles: %w{web app}
```

Next, you have to configure your ssh keys.

### Windows 7

1. Add your shh private key under `C:\Users\USERNAME\.ssh`

2. Within each environment config file replace the `USERNAME` with your user name.


``` ruby
set :ssh_options, {
	keys: ["#{ENV['USERNAME']}/.ssh/keyname.pem"],
	forward_agent: false,
	auth_methods: %w(publickey)
}
```


### OSX

1. Add your shh private key under `/home/user/.ssh/id_rsa`

2. Within each environment config file replace the `user` with your user name.


``` ruby
set :ssh_options, {
	keys: %w(/home/user/.ssh/id_rsa),
	forward_agent: false,
	auth_methods: %w(password)
}
```




Usage
-------------------

1. Go into the beaver project and run the `beaver.rb` script

``` sh
$ cd C:\beaver
$ ruby beaver.rb -h
``` 

This will display all of the vireos options


### Deploy

``` sh
$ ruby beaver.rb -e sandbox -s example1.com,example2.com,example3.com
``` 

Running the `beaver.rb` with those options will deploy the sites: example1.com,example2.com,example3.com into all of the
configured sandbox servers.
The `-s` option takes an array of comma delimited sites (no spaces).


### Rollback

``` sh
$ ruby beaver.rb -e sandbox -s  example1.com,example2.com,example3.com -a rollback
```

### Generic tasks

Beaver enable you to run tasks witch are not part of the deploy process.

``` sh
$ ruby beaver.rb -e sandbox -s example1.com -a namespace:task
```

``` sh
$ ruby beaver.rb -e sandbox -a namespace:task
```

### Some more options

* `-H, --hosts` Optional, Let's you list all of the hostnames you wish to deploy to and it will create an environment file with the listed hostnames.

If you wish to query the AWS api in order to get a list of servers hostnames you wish to deploy to (useful in autoscale), you can pass the following params: 

* `--accesskey` AWS config access key
* `--secretaccess` AWS config secret access key
* `--region ` AWS region 
* `--filters` AWS tags, ordered in key,value pairs 
 
Defining the above params, will create a servers config file (with the name of the `-e env`).

Alternatively, you can create a this file on your own.
