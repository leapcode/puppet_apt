# Introduction

This aims to document the replacement of the shared apt module by the [puppetlabs](https://github.com/puppetlabs/puppetlabs-apt) one.

I've tried to look at all the classes supported by our shared module.

## Some thoughts on moving to the puppetlabs module

Whereas the shared module tried to be a coherent mass of code doing all the apt-related things we needed to do, the puppetlabs module takes a more modular approach. This means some of the features we had are not present and will never be added, since "they are not part of the main apt core functionalities"...

This means we'll have to start using multiple modules as "plugins" to the main puppetlabs apt module.

# Minor deprecations & warnings

## lsb
One has to make sure `lsb-release` package is installed. Our shared apt module used to have a dependency on our `lsb` module that did that, but we deprecated that module.

## `apt_updated` deprecation
The puppetlabs module uses the `apt_update` exec, whereas the shared module uses `apt_updated`. If you where calling this exec in other modules, you'll need to update this for the new exec name.

## stdlib

Make sure your version of stdlib is recent. Mine wasn't and the apt module was failing on the pin functions because the `length` function was missing.

## Partial management of the config files by default
By default, the puppetlabs apt module only partially manages the apt configuration and will not purge configuration added by hand. This differs from the shared module behavior, where those modifications would get overwritten by our templates.

To keep the old behavior, pass:

    class { 'apt':
      purge => {
        sources.list   => true,
        sources.list.d => true,
        preferences    => true,
        preferences.d  => true,
      },
    }

## apt sources

By default, the puppetlabs module won't create any sources. To replicate the shared module template, use this:

    apt::source {
      "${lsbdistcodename}":
        location => 'http://deb.debian.org/debian',
        repos    => 'main contrib non-free';

      "${lsbdistcodename}-security":
        location => 'http://security.debian.org/debian-security',
        repos    => 'main contrib non-free',
        release  => "${lsbdistcodename}/updates";

      "${lsbdistcodename}-backports":
        location => 'http://deb.debian.org/debian',
        repos    => 'main contrib non-free',
        release  => "${lsbdistcodename}-backports";

      'testing':
        location => 'http://deb.debian.org/debian',
        repos    => 'main contrib non-free',
        release  => "testing";
    }

Sadly I can't find a way to iter the next codename from the facts :(. You can either use testing instead of "the next release" or specify it manually.

# Classes comparison

## apticron

Apticron is not supported by the puppetlabs module either, but [this slightly out of date](https://github.com/dhoppe/puppet-apticron) module from the Forge (the most popular one), although it doesn't state support for Debian 9 and could profit from a little love.

## dist_upgrade

The behavior of the three `dist_upgrade` classes (`apt::cron::dist_upgrade`, `apt::dist_upgrade` and `apt::dist_upgrade::initiator`) are not supported by the puppetlabs module.

Maybe consider moving to a workflow using `unattended-upgrades`?

## dselect

`dselect` is not supported and nothing seems to do what the shared module feature did.

## apt-listchanges

I ported and upgraded our modules `apt::listchanges` code to a
[separate module](https://gitlab.com/baldurmen/puppet-apt_listchanges).

It basically does the same thing, but in a more modern style. Check the
parameters list as types are now defined.

## proxy

Here is how you would configure an apt proxy:

    class { 'apt':
      proxy => {
        host  => 'hostname',
        port  => '8080',
        https => true,
       ensure => file,
      },
    }

## reboot required

The puppetlabs notice will not manage `reboot-required` like the shared one did, but it creates a fact named `apt_reboot_required` that could be used by some external monitoring system.

Since it only looks at `/var/run/reboot-required`, it might be a better idea to use something like a combination of the `needrestart` package and an external monitoring system.

The [needrestart](https://github.com/hetznerZA/hetzner-needrestart) module seems to work well.

## unattended-upgrades

The puppetlabs modules does not support `unattended-upgrades` natively anymore [it used to](https://tickets.puppetlabs.com/browse/MODULES-4943).

The recommended way to setup this feature is to use the compatible [voxpopuli/unattended-upgrades](https://github.com/voxpupuli/puppet-unattended_upgrades) module.

This modules does quite a lot and is quite complex. More to come on this.

# Defines comparison

## apt confs

You can using the `apt::conf` define:

    class { 'apt::conf':
      'whatever_config':
        ensure        => present,
        content       => 'foo bar the config you want to see',
        priority      => '20',
        notify_update => true,
    }

The content part can get quite long, so I would recommend using [heredocs](https://puppet.com/docs/puppet/4.8/lang_data_string.html#heredocs).

## preferences_snippet

The way to pin a package is now [much more fleshed out](https://github.com/puppetlabs/puppetlabs-apt#defined-type-aptpin) and looks like:

    apt::pin { 'certbot':
      codename => 'buster',
      packages => [ 'python3-certbot', 'python3-certbot-apache' ],
    }

Be aware, as by default if you don't specify a list of packages, this define pins all packages.

## apt_packages (preseed)

As far as I can see, there is nothing in the puppetlabs module that lets you preseed packages.

## GPG key management

The shared module simply used to push a `.gpg` file to `/etc/apt/trusted.gpg.d` to manage GPG keys.

The puppetlabs module is a bit more sophisticated and lets you either import a key from a source (path, ftp, https, etc.) or fetches keys from a keyserver. 

    apt::key { 'my_local_key':
      id      => '13C904F0CE085E7C36307985DECF849AA6357FB7',
      source  => "puppet://files/gpg/13C904F0CE085E7C36307985DECF849AA6357FB7.gpg",
    }

    apt::key { 'puppetlabs':
      id      => '6F6B15509CF8E59E6E469F327F438280EF8D349F',
      server  => 'pgp.mit.edu',
      options => 'http-proxy="http://proxyuser:proxypass@example.org:3128"',
    }

The heavy lifting is done by [these](https://github.com/puppetlabs/puppetlabs-apt/blob/dc3ead0ed5f4d735869565660c982983d379a519/lib/puppet/type/apt_key.rb) [two](https://github.com/puppetlabs/puppetlabs-apt/blob/dc3ead0ed5f4d735869565660c982983d379a519/lib/puppet/provider/apt_key/apt_key.rb) Ruby files.

## upgrade_package

This can be done by using `apt::pin` and specifying a version:

    apt::pin { 'perl':
      packages => 'perl',
      version  => '5.26.1-4',
    }

## dpkg_statoverride

Is there a reason you are using this instead of using `file`?

## Facts

There are a bunch of new and [interesting facts](https://github.com/puppetlabs/puppetlabs-apt#facts).

# Contributing to the puppetlabs module

[Submitting a patch seems to be feasible](https://docs.puppet.com/forge/contributing.html), but is also a lot more work than just creating a pull request.

# Hiera

Here's some sane Hiera config I'm using.

```
classes:
  - apt
  - needrestart
  - unattended_upgrades

apt::purge:
  'sources.list': true
  'sources.list.d': true
  'preferences': true
  'preferences.d': true

apt::sources:
  "%{facts.lsbdistcodename}":
    comment: 'Stable'
    pin: '990'
    location: 'http://deb.debian.org/debian/'
    repos: 'main contrib non-free'
  "%{facts.lsbdistcodename}-security":
    comment: 'Stable security'
    location: 'http://security.debian.org/debian-security'
    repos: 'main contrib non-free'
    release: "%{facts.lsbdistcodename}/updates"
  "%{facts.lsbdistcodename}-backports":
    comment: 'Backports'
    pin: 200
    location: 'http://deb.debian.org/debian/'
    repos: 'main contrib non-free'
    release: "%{facts.lsbdistcodename}-backports"
  'buster':
    comment: 'Buster'
    pin: 2
    location: 'http://deb.debian.org/debian/'
    repos: 'main contrib non-free'
    release: 'buster'

needrestart::action: automatic
```
