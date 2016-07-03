class yum {

  # Set splay time for running yum update
  $splay = fqdn_rand(30)

  # Basic packages all servers should have
  $packages = [
               'deltarpm',
               'screen',
               'lsof',
               'nload',
               'iotop',
               'nmap-ncat',
               'nmap',
               'htop',
               'sendmail',
               'git',
               'postfix',
               'emacs',
               'rpm-build',
               'mlocate',
               'bind-utils',
               'tcpdump',
               'nano',
               'setools-console',
               'bash-completion-extras',
              ]

  package { ['epel-release']:
    ensure => installed,
  }

  package { $packages:
    ensure => installed,
    require => Package['epel-release'] # Install epel before the packages
  }

  # Define some standards for our mcollective-files
  define yum-file() {
    # $name is the name of the object calling the this (the mcollective-file)
    # dirname is the path to te files directory, basename is the name of the file without the path
    $dirname  = dirname($name)
    $filename = basename($name)

    # Here we set the bind-files definitions, root:root with 644 are default premissions
    file { "yum-$name":                        # Lets name this resource bind-$name meaning prefix the filename with the puppet class name
      path    => $name,                        # The filepath
      mode    => 644,                          # Set permissions
      owner   => root,                         # Set owner
      group   => root,                         # Set group owner
      require => Package[$yum::packages],   # Before we copy the file these packages, directories must be installed
      content => template("yum/$filename.erb"), # the puppetmaster find this file in path-to-puppet-modules/bind/templates/$filename.erb .erb since its a template
    }
  }

  yum-file {
    [
     '/etc/yum.repos.d/puppetlabs.repo',
     '/etc/yum.repos.d/CentOS-Base.repo',
     '/etc/yum.repos.d/epel.repo',
     '/etc/yum/pluginconf.d/fastestmirror.conf',
     '/etc/pki/rpm-gpg/RPM-GPG-KEY-nightly-puppetlabs',
     '/etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs',
     '/etc/cron.d/vina-yum-daily',
    ]:
  }
}
