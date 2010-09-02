class apt::default_sources_list {
  include lsb
  config_file {
    # include main, security and backports
    # additional sources could be included via an array
    "/etc/apt/sources.list":
      content => template("apt/sources.list.erb"),
      require => Package['lsb'];
  }
}
