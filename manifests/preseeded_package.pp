# Install a package with a preseed file to automatically answer some questions.

define apt::preseeded_package (
  $ensure  = 'installed',
  $content = '',
) {

  $seedfile = "/var/cache/local/preseeding/${name}.seeds"
  $real_content = $content ? {
    ''      => template ( "site_apt/${::debian_codename}/${name}.seeds" ),
    default => $content;
  }

  file { $seedfile:
    content => $real_content,
    mode    => '0600',
    owner   => 'root',
    group   => 0,
  }

  package { $name:
    ensure       => $ensure,
    responsefile => $seedfile,
    require      => File[$seedfile],
  }
}
