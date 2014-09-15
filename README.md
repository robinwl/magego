[virtualbox]: https://www.virtualbox.org/
[vagrant]: https://www.vagrantup.com/downloads.html
[nginx]: http://nginx.org
[php5-fpm]: http://php-fpm.org/
[MySQL]: http://www.mysql.com/
[Percona]: http://www.percona.com/
[node.js]: http://nodejs.org/
[mailcatcher]: http://mailcatcher.me/
[Ruby]: https://www.ruby-lang.org/en/
[Magento]: http://magento.com/products/overview#community
[SSH]: http://www.openssh.com/
[gulp.js]: http://gulpjs.com/
[Grunt]: http://gruntjs.com/
[npm]: https://www.npmjs.org/
[composer]: https://getcomposer.org/
[n98-magerun]: http://magerun.net/
[modman]: https://github.com/colinmollenhour/modman

# MageGo

This repo provides a template Vagrantfile and provisioner to create a Magento virtual machine using the VirtualBox software hypervisor.

## Streamlined setup

1) Install dependencies

* [VirtualBox][virtualbox] 4.3.10 or greater.
* [Vagrant][vagrant] 1.6 or greater.

2) Clone this project 
```
git clone https://github.com/robinwl/magego.git
cd magego
```

3) Create config file
```
cp config.rb.sample config.rb
```

4) **OPTIONAL** Import current project

4a) Place Magento files in magego/public/
```
cd /path/to/magento
cp -ar * /path/to/magego/public
```

4b) Place database dump in magego/db/sql.sql . [Remember to change web/unsecure/base_url and web/secure/base_url](http://www.magentocommerce.com/wiki/recover/restore_base_url_settings)
```
cd /path/to/magego/db
mysqldump -uuser -ppass -h db.example.com magento > db.sql
```

4c)  Change config.rb to match your setup
```
cd /path/to/magego
edit config.rb
```


5) Startup and [SSH]

```
vagrant up
vagrant ssh
```

6) Setup composer (run inside box after 'vagrant ssh')
```
composer up
```

## Magento 1.9 with demo data setup
```
git clone https://github.com/robinwl/magego.git
cd magego
cp config.rb.sample config.rb
sed -i 's/$sample_data = false/$sample_data = true/g' config.rb
vagrant up

```

## Packages
* [nginx] (latest stable)
* [php5-fpm] 5.3/5.4 
* [MySQL] / [Percona] (latest stable)
* [node.js] 
* [npm]
* [Grunt]
* [gulp.js]
* [mailcatcher]
* [Ruby] 1.9
* [Magento] 1.9 or from source
* [composer]
* [n98-magerun]
* [modman]
