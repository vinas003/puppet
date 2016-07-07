class ssh {

  $packages = ['openssh']
  $services = ['sshd']
  
  package { $packages:
    ensure => installed,
  }

  service { $services:
    ensure  => running,
    enable  => true,
    require => Package[$packages],
  }

  # Define some standards for our Web-directory
  define ssh-file($mode = 600, $owner = root) {
    # $name is the name of the object calling the this (the Web-file)
    # dirname is the path to te files directory, basename is the name of the file without the path
    $dirname  = dirname($name)
    $filename = basename($name)
    
    # Here we set the Web-files definitions, root:root with 644 are default premissions
    file { "$module_name-$name":          # Lets name this resource web-$name meaning prefix the filename with the puppet class name
      path    => $name,                   # The filepath
      mode    => $mode,                   # Set permissions to 600
      owner   => $owner,                  # Set owner to root
      group   => $owner,                  # Set group owner to root
      notify  => Service[$ssh::services], # It should notify the service httpd if the file changes
      require => Package[$ssh::packages], # Before we copy the file these packages, directories must be installed
      content => template("$module_name/$filename.erb"), # the puppetmaster find this file in path-to-puppet-modules/ssh/templates/$filename.erb .erb since its a template
    }
  }

  # Our ssh servers should have iptables with ssh anti bruteforce
  if ($hostname =~ /^ssh/) {

    package { 'iptables-services':
      ensure => installed,
    }
    
    service { 'iptables':
      ensure  => running,
      enable  => true,
      require => Package['iptables-services'],
    }
    
    ssh-file { ['/etc/sysconfig/iptables']:
      mode    => 640,
      notify  => Service['iptables'], # It should notify the service if the file changes
      require => Package['iptables-services'],
    }
  } # End if hostname =~ /^ssh/
  
  ssh-file { ['/etc/ssh/sshd_config']:
    mode => 640,
  }

  ssh-file { ['/home/centos/.ssh/authorized_keys']:
    owner => centos,
  }

  exec { 'generate ed25519 hostkey':
    path    => ['/usr/bin', '/usr/sbin'], # Path to search for commands
    command => 'rm /etc/ssh/ssh_host_ed25519_key && ssh-keygen -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key && touch /etc/ssh/ssh_host_ed25519_key-generated',
    notify  => Service[$services],   # It should notify the service httpd if the file changes
    require => Package[$packages],   # Before we copy the file these packages, directories must be installed
    creates => '/etc/ssh/ssh_host_ed25519_key-generated',              # Puppet executes the command when this file NOT exists (so first time)
  }  
}
