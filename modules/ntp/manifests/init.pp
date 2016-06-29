class ntp {

  $packages = ['ntp']
  $services = ['ntpd']
  
  package { $packages:
    ensure => installed,
  }

  service { $services:
    ensure  => running,
    enable  => true,
    require => Package['ntp'],
  }  
}
