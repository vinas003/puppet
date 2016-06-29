class bind {

  $packages = ['bind']
  $services = ['named']
  
  package { $packages:
    ensure => installed,
  }

  service { 'named':
    ensure  => running,
    enable  => true,
    require => Package[$packages],
  }

  # Define some standards for our Web-files
  define bind-file($mode = 640, $owner = root, $group = named) {
    # $name is the name of the object calling the this (the Web-file)
    # dirname is the path to te files directory, basename is the name of the file without the path
    $dirname  = dirname($name)
    $filename = basename($name)

    # Here we set the bind-files definitions, root:root with 644 are default premissions
    file { "bind-$name":                         # Lets name this resource bind-$name meaning prefix the filename with the puppet class name
      path    => $name,                          # The filepath
      mode    => $mode,                          # Set permissions
      owner   => $owner,                         # Set owner
      group   => $group,                         # Set group owner
      notify  => Service[$bind::services],               # It should notify the service named if the file changes
      require => Package[$bind::packages],       # Before we copy the file these packages, directories must be installed
      content => template("bind/$filename.erb"), # the puppetmaster find this file in path-to-puppet-modules/bind/templates/$filename.erb .erb since its a template
    }
  }

  # create directories
  file { [ '/etc/named/', '/etc/named/zones/']:
    mode    => 750,
    owner   => root,
    group   => named,
    ensure  => directory,          # They should be directories instead of a file
    require => Package[$packages], # Before we create the directories the files the package must be installed
  }
  
  bind-file {
    [
     '/etc/named.conf',
     '/etc/named/named.conf.local',
     '/etc/named/zones/db.10',
     '/etc/named/zones/db.vinasec.se',
    ]:
  }
}
