# Configure basic pins for debian/Ubuntu codenames
#
# This all ensures that apt behaves as expected with regards to packages when
# we have more sources than just the one for the current codenamed release.
#
# This class should not be included directly. It is automatically called in by
# the 'apt' class. Thus you should use the apt class instead.
#
class apt::preferences {

  file { '/etc/apt/preferences':
    ensure => absent,
  }
  # Remove the file that we were previously deploying. It's now been renamed to
  # current_codename
  file { '/etc/apt/preferences.d/stable':
    ensure => absent,
  }

  if ($apt::manage_preferences == true) and ($apt::custom_preferences != undef) {
    file { '/etc/apt/preferences.d/custom':
      ensure  => present,
      alias   => 'apt_config',
      content => template($apt::custom_preferences),
      owner   => 'root',
      group   => 0,
      mode    => '0644',
      require => File['/etc/apt/sources.list'],
    }
    file { '/etc/apt/preferences.d/current_codename':
      ensure => absent,
    }
    file { '/etc/apt/preferences.d/volatile':
      ensure => absent,
    }
    file { '/etc/apt/preferences.d/lts':
      ensure => absent,
    }
    file { '/etc/apt/preferences.d/nextcodename':
      ensure => absent,
    }
  }
  elsif $apt::manage_preferences == true {

    if $::operatingsystem == 'Debian' {
      file { '/etc/apt/preferences.d/current_codename':
        ensure  => present,
        alias   => 'apt_config',
        content => template('apt/Debian/current_codename.erb'),
        owner   => 'root',
        group   => 0,
        mode    => '0644',
        require => File['/etc/apt/sources.list'],
      }
      # Cleanup for cases where users might switch from using
      # custom_preferences to not using it anymore.
      file { '/etc/apt/preferences.d/custom':
        ensure => absent,
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
          owner   => 'root',
          group   => 0,
          mode    => '0644',
          require => File['/etc/apt/sources.list'],
        }
      }

      if $apt::use_lts {
        file { '/etc/apt/preferences.d/lts':
          ensure  => present,
          content => template('apt/Debian/lts.erb'),
          owner   => 'root',
          group   => 0,
          mode    => '0644',
          require => File['/etc/apt/sources.list'],
        }
      }

      if ($::debian_nextcodename) and ($::debian_nextcodename != 'experimental') {
        file { '/etc/apt/preferences.d/nextcodename':
          ensure  => present,
          content => template('apt/Debian/nextcodename.erb'),
          owner   => 'root',
          group   => 0,
          mode    => '0644',
          require => File['/etc/apt/sources.list'],
        }
      }
    }
    elsif $::operatingsystem == 'Ubuntu' {
      file { '/etc/apt/preferences':
        ensure  => present,
        alias   => 'apt_config',
        # only update together
        content => template("apt/Ubuntu/preferences_${apt::codename}.erb"),
        owner   => 'root',
        group   => 0,
        mode    => '0644',
        require => File['/etc/apt/sources.list'],
      }
    }
  }
  elsif $apt::manage_preferences == false {
    file { '/etc/apt/preferences.d/custom':
      ensure => absent,
    }
    file { '/etc/apt/preferences.d/current_codename':
        ensure => absent,
    }
    file { '/etc/apt/preferences.d/volatile':
        ensure => absent,
    }
    file { '/etc/apt/preferences.d/lts':
        ensure => absent,
    }
    file { '/etc/apt/preferences.d/nextcodename':
        ensure => absent,
    }
  }
}
