
# README

ASI Application to manage the USDA operations for 2023.

Versions
-----
* Ruby: 2.6.2
* Rails: 5.2.2.1
* NodeJS: 8.10.0
* Yarn: 1.9.4

Setup
-----
- Install [RVM](https://rvm.io/)
- Install [NodeJS](https://nodejs.org/en/) (through [NVM](https://github.com/creationix/nvm))
- Install [Yarn](https://yarnpkg.com/en/)
- Install Gems
```shell
bundle install
```
- Install [React-Rails](https://github.com/reactjs/react-rails)
```shell
rails g react:install
```

Configuring RGeo and GEOS
-----
- Check if Rails is configured with GEOS
```shell
$ rails c
> RGeo::Geos.supported?
=> false
```

- Install the dependencies
```shell
sudo apt-get -y install libgeos-3.4.2 libgeos-dev libproj0 libproj-dev
```

- Uninstall RGeo Gem
```shell
gem uninstall rgeo
```

- Get the GEOS directory and reinstall the Gem
```shell
$ geos-config --prefix
/usr
$ gem install rgeo -- --with-geos-dir=/usr
```
  
Yarn
---
NodeJS Package Manager that replaced Bower
```shell
$ yarn install
```

Start the Delayed Jobs
---
```shell
$ RAILS_ENV=production bin/delayed_job start
$ RAILS_ENV=production bin/delayed_job restart
$ RAILS_ENV=production bin/delayed_job stop
```