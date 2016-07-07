class openvpn {

  $packages = ['openvpn']
  
  $services = ['openvpn@server']

  package { $packages:
    ensure => installed,
  }

  service { $services:
    ensure  => running,
    enable  => true,
    require => Package[$packages],
  }

  # Define some standards for our Web-files
  define openvpn-file($mode = 600, $owner = root) {
    # $name is the name of the object calling the this (the Web-file)
    # dirname is the path to te files directory, basename is the name of the file without the path
    $dirname  = dirname($name)
    $filename = basename($name)

    # Here we set the Web-files definitions, root:root 644 are default premissions
    file { "$module_name-$name":                         # Lets name this resource web-$name meaning prefix the filename with the puppet class name
      path    => $name,                                  # The filepath
      mode    => $mode,                                  # Set permissions to 600
      owner   => $owner,                                 # Set owner to root
      group   => $owner,                                 # Set group owner to root
      notify  => Service[$openvpn::services],            # It should notify the service httpd if the file changes
      require => [                                       # Before we copy the file these packages, directories must be installed
                  Package[$openvpn::packages],
                  File['/etc/openvpn/ccd'],
                 ],
      content => template("$module_name/$filename.erb"), # The puppetmaster find this file in path-to-puppet-modules/web/templates/$filename.erb .erb since its a template
    }
  }

  file_line { 'openvpn-ip_forwarding':
    path => '/etc/sysctl.conf',
    line => 'net.ipv4.ip_forward = 1',
  }
    
  file { ['/etc/openvpn/ccd']:
    ensure  => directory,
    require => Package[$openvpn::packages],
  }

  openvpn-file {
    [
     '/etc/openvpn/server.conf',
     '/etc/openvpn/ta.key',
     '/etc/openvpn/ca.crt',
     '/etc/openvpn/server.crt',
     '/etc/openvpn/server.key',
     '/etc/openvpn/dh.pem',
    ]:
  }

  # These are not a sensitive files so 644 on them
  openvpn-file { ['/etc/openvpn/ccd/client1']:
    mode => 644,
  }

  # Needed the very first time we run puppet on a vpn server
  exec { 'openvpn-ensure_ip_forward':
    command => 'sysctl -w net.ipv4.ip_forward=1 && touch /usr/share/openvpn-ip_forward',
    creates => '/usr/share/openvpn-ip_forward',
    path    => ['/usr/bin', '/usr/sbin'], # Path to search for commands
    require => Service[$services],
  }  
}
