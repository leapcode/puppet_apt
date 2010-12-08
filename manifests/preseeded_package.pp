define apt::preseeded_package ($content = "", $ensure = "installed") {
  $seedfile = "/var/cache/local/preseeding/$name.seeds"
  $real_content = $content ? { 
    ""      => template ( "site-apt/$name.seeds",
                          "site-apt/$lsbdistcodename/$name.seeds",
                          "$name.seeds", "$lsbdistcodename/$name.seeds" ),
    default => $content
  }   

  file { $seedfile:
    content => $real_content,
    mode => 0600, owner => root, group => root,
  }   

  package { $name:
    ensure => $ensure,
    responsefile => $seedfile,
    require => File[$seedfile],
  }   
}  
