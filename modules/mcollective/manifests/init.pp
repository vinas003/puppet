class mcollective {

  $packages = ['mcollective', 'mcollective-puppet-agent', 'mcollective-shell-agent', 'mcollective-service-agent']
  $managment_packages = ['mcollective-client', 'mcollective-puppet-client', 'mcollective-shell-client', 'mcollective-service-client']

  $services = ['mcollective']
  
  package { $packages:
    ensure => installed,
  }

  service { $services:
    ensure  => running,
    enable  => true,
    require => Package['mcollective'],
  }

  $mcollective_host      = 'puppet.vinasec.se'
  $mcollective_password  = 'PASSWORD_HERE'

  # Define some standards for our Web-files
  define mcollective-file($mode = 400, $owner = root, $group = root) {
    # $name is the name of the object calling the this (the mcollective-file)
    # dirname is the path to te files directory, basename is the name of the file without the path
    $dirname  = dirname($name)
    $filename = basename($name)

    # Here we set the bind-files definitions, root:root with 644 are default premissions
    file { "mcollective-$name":                  # Lets name this resource bind-$name meaning prefix the filename with the puppet class name
      path    => $name,                          # The filepath
      mode    => $mode,                          # Set permissions
      owner   => $owner,                         # Set owner
      group   => $group,                         # Set group owner
      notify  => Service[$mcollective::services],               # It should notify the service named if the file changes
      require => Package[$mcollective::packages],       # Before we copy the file these packages, directories must be installed
      content => template("mcollective/$filename.erb"), # the puppetmaster find this file in path-to-puppet-modules/bind/templates/$filename.erb .erb since its a template
    }
  }
  
  # The managment nodes
  if ($hostname == 'root') or ($hostname == 'puppet') {

    package { $managment_packages:
      ensure => installed,
    }
    
    file {
      [
       '/etc/mcollective.d/',
       '/etc/mcollective.d/credentials/',
       '/etc/mcollective.d/credentials/certs',
       '/etc/mcollective.d/credentials/private_keys'
      ]:
        mode   => 700,
        owner  => root,
        group  => root,
        ensure => directory,
        notify => Service[$services],
    }

    mcollective-file {
      [
       '/etc/mcollective.d/credentials/certs/mcollective-servers.pem',
       '/etc/mcollective.d/credentials/private_keys/vina.mco_key.pem',
       '/etc/mcollective.d/credentials/certs/vina.mco.pem',
       '/etc/mcollective/client.cfg',
      ]:
    }    
  }

  mcollective-file {
    [
     '/etc/mcollective/ssl/clients/vina.mco.pem',
     '/etc/mcollective/ssl/server_private.pem',
     '/etc/mcollective/ssl/server_public.pem',
     '/etc/mcollective/server.cfg',
    ]:
  }    
  
  file { '/etc/mcollective/facts.yaml':
    owner    => root,
    group    => root,
    mode     => 400,
    loglevel => debug, # reduce noise in Puppet reports
    content  => inline_template("<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime_seconds|timestamp|free)/ }.to_yaml %>"), # exclude rapidly changing facts
  }
}

