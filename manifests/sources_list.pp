# Configure an apt source
define apt::sources_list (
  $ensure  = 'present',
  $source  = undef,
  $content = undef
) {

  if $ensure == 'present' {
    if $source == undef and $content == undef {
      fail("One of \$source or \$content must be specified for apt_sources_snippet ${name}")
    }
    if $source != undef and $content != undef {
      fail("Only one of \$source or \$content must specified for apt_sources_snippet ${name}")
    }
  }

  include apt::dot_d_directories

  $realname = regsubst($name, '\.list$', '')

  # One would expect the 'file' resource on sources.list.d to trigger an
  # apt-get update when files are added or modified in the directory, but it
  # apparently doesn't.
  file { "/etc/apt/sources.list.d/${realname}.list":
    ensure => $ensure,
    mode   => '0644',
    owner  => 'root',
    group  => 0,
    notify => Exec['apt_updated'],
  }

  if $source {
    File["/etc/apt/sources.list.d/${realname}.list"] {
      source => $source,
    }
  }
  else {
    File["/etc/apt/sources.list.d/${realname}.list"] {
      content => $content,
    }
  }
}

