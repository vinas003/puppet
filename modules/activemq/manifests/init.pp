class activemq {

  $packages = ['activemq']
  $services = ['activemq']
  
  package { $packages:
    ensure => installed,
  }
  
  service {$services:
    ensure  => running,
    enable  => true,
    require => Package[$packages],
  }
}
