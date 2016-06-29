class puppet {

  $packages = ['puppet']
  $services = ['puppet']

  $splay = fqdn_rand(30)
  
  package { $packages:
    ensure => installed,
  }

  # Define some standards for our mcollective-files
  define puppet-file() {
    # $name is the name of the object calling the this (the mcollective-file)
    # dirname is the path to te files directory, basename is the name of the file without the path
    $dirname  = dirname($name)
    $filename = basename($name)

    # Here we set the bind-files definitions, root:root with 644 are default premissions
    file { "puppet-$name":                     # Lets name this resource bind-$name meaning prefix the filename with the puppet class name
      path    => $name,                        # The filepath
      mode    => 600,                          # Set permissions
      owner   => root,                         # Set owner
      group   => root,                         # Set group owner
      # notify  => Service[$puppet::services], # We do not have puppet service running, we use cron for it
      require => Package[$puppet::packages],   # Before we copy the file these packages, directories must be installed
      content => template("puppet/$filename.erb"), # the puppetmaster find this file in path-to-puppet-modules/bind/templates/$filename.erb .erb since its a template
    }
  }
  
  
  # Not disable puppet on the puppetmaster server
  if !($hostname == 'puppet') {
    
    service { $services:
      ensure  => stopped,
      enable => false,
      require => Package[$packages],
     }

     puppet-file {
       [
        '/etc/puppet/puppet.conf',
        '/etc/cron.d/vina-puppet',
       ]:
     }
  }
}
