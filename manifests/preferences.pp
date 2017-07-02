class apt::preferences {

  file { '/etc/apt/preferences':
      ensure => absent;
  }

  # Remove the file that we were previously deploying. It's now been renamed to
  # current_codename
  file { '/etc/apt/preferences.d/stable':
    ensure => absent,
  }

  if ($apt::manage_preferences == true) and ($apt::custom_preferences != undef) {

    file {
      '/etc/apt/preferences.d/custom':
        ensure  => present,
        alias   => 'apt_config',
        content => template($apt::custom_preferences),
        require => File['/etc/apt/sources.list'],
        owner   => root, group => 0, mode => '0644';

      '/etc/apt/preferences.d/current_codename':
        ensure => absent;

      '/etc/apt/preferences.d/volatile':
        ensure => absent;

      '/etc/apt/preferences.d/lts':
        ensure => absent;

      '/etc/apt/preferences.d/nextcodename':
        ensure => absent;
    }
  }

  elsif $apt::manage_preferences == true {

    if $::operatingsystem == "Debian" {

      file {
        '/etc/apt/preferences.d/current_codename':
          ensure  => present,
          alias   => 'apt_config',
          content => template('apt/Debian/current_codename.erb'),
          require => File['/etc/apt/sources.list'],
          owner   => root, group => 0, mode => '0644';

        '/etc/apt/preferences.d/custom':
          ensure => absent;
      }
      # This file ensures that all debian packages that don't have a
      # preference file shouldn't be considered for auto-install or upgrade at
      # all.
      file { '/etc/apt/preferences.d/debian_fallback':
        ensure  => present,
        source  => 'puppet:///modules/apt/Debian/preferences_fallback',
        owner   => 'root',
        group   => 0,
        mode    => '0644',
        require => File['/etc/apt/sources.list'],
      }

      if $apt::use_volatile {

        file { '/etc/apt/preferences.d/volatile':
          ensure  => present,
          content => template('apt/Debian/volatile.erb'),
          require => File['/etc/apt/sources.list'],
          owner   => root, group => 0, mode => '0644';
        }
      }

      if $apt::use_lts {

        file { '/etc/apt/preferences.d/lts':
          ensure  => present,
          content => template('apt/Debian/lts.erb'),
          require => File['/etc/apt/sources.list'],
          owner   => root, group => 0, mode => '0644';
        }
      }

      if ($::debian_nextcodename) and ($::debian_nextcodename != "experimental") {

        file { '/etc/apt/preferences.d/nextcodename':
          ensure  => present,
          content => template('apt/Debian/nextcodename.erb'),
          require => File['/etc/apt/sources.list'],
          owner   => root, group => 0, mode => '0644';
        }
      }
    }

    elsif $::operatingsystem == "Ubuntu" {

      file { '/etc/apt/preferences':
       ensure  => present,
       alias   => 'apt_config',
       # only update together
       content => template("apt/Ubuntu/preferences_${apt::codename}.erb"),
       require => File['/etc/apt/sources.list'],
       owner   => root, group => 0, mode => '0644';
      }
    }
  }

  elsif $apt::manage_preferences == false {

    file {
      '/etc/apt/preferences.d/custom':
        ensure => absent;

      '/etc/apt/preferences.d/current_codename':
        ensure => absent;

      '/etc/apt/preferences.d/volatile':
        ensure => absent;

      '/etc/apt/preferences.d/lts':
        ensure => absent;

      '/etc/apt/preferences.d/nextcodename':
        ensure => absent;
    }
  }
}
