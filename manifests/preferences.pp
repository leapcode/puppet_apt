class apt::preferences {

  $pref_contents = $apt::custom_preferences ? {
    ''      => $::operatingsystem ? {
      'debian' => template("apt/${::operatingsystem}/preferences.erb"),
      'ubuntu' => template("apt/${::operatingsystem}/preferences_${apt::codename}.erb"),
    },
    default => $apt::custom_preferences
  }

  file { '/etc/apt/preferences':
    ensure  => present,
    alias   => 'apt_config',
    # only update together
    content => $pref_contents,
    require => File['/etc/apt/sources.list'],
    owner   => root, group => 0, mode => '0644';
  }
}
