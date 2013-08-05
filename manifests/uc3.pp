# Installs CVMFS Client and the various dependencies
# Modified version of MWT2 CVMFS code.
#  -L.B. 25-Jun-2013

import "uc3"

class cvmfs::uc3::base($version='latest') { 
  package {'fuse.x86_64':   ensure => present}

  package {'autofs.x86_64': ensure => present}

  package { 'cvmfs' :            
    ensure     => "${version}",
    require    => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-CernVM'],
  }

  package { 'cvmfs-init-scripts' : 
    ensure     => present,
    require    => Package['cvmfs'] 
  }

  file { "/etc/fuse.conf" :
    source     => "puppet:///modules/cvmfs/uc3/fuse.conf",
    require    => Package['fuse.x86_64']
  }

  file {'/etc/pki/rpm-gpg/RPM-GPG-KEY-CernVM': source => "puppet:///modules/cvmfs/uc3/RPM-GPG-KEY-CernVM"}

  file { "/etc/auto.master" :
    owner      => "root",
    group      => "root",
    mode       => 644,
    source     => "puppet:///modules/cvmfs/uc3/auto.master",
    require    => Package['autofs.x86_64'],
    notify     => [Service['autofs']]
  }

  file { "/etc/cvmfs/default.local" :
    owner      => "root",
    group      => "root",
    mode       => 644,
    notify     => Service["autofs"],
    require    => Package['cvmfs'],
    source     => "puppet:///modules/cvmfs/uc3/default.local"
  }

  file { '/scratch/cvmfs' :
    ensure     => directory,
    owner      => "cvmfs",
    group      => "cvmfs",
    require    => [File['/scratch'], Package['cvmfs']]
  }

  service { "autofs" :
    enable     => true,
    ensure     => true,
    pattern    => "automount",
    require    => Package['autofs.x86_64'],
    subscribe  => File['/etc/cvmfs/default.local'], 
  }
}

# Places the appropriate keys and config files for each repo we want.
define cvmfs::uc3::repository { 
  file { "/etc/cvmfs/config.d/${name}.conf" :
    owner   => "root",
    group   => "root",
    mode    => 644,
    notify  => Service["autofs"],
    source  => "puppet:///modules/cvmfs/uc3/${name}.conf",
    require => Package['cvmfs'],
  }
  file { "/etc/cvmfs/keys/${name}.pub":
    owner   => "root",
    group   => "root",
    mode    => 444,
    notify  => Service["autofs"],
    source  => "puppet:///modules/cvmfs/uc3/${name}.pub",
    require => Package['cvmfs'],
  }
  # To do: write some code to append the keys to the default.local for CVMFS
}

# Configures a node to use the Certficate Authority located in the MWT2 CVMFS repository
class cvmfs::uc3::link::certificates {
  file { '/share/certificates' :
    ensure     => link,
    target     => "/cvmfs/osg.mwt2.org/osg/CA/certificates",
    force      => true,
    require    => Package['cvmfs'],
  }
  file { '/etc/grid-security':
    ensure     => directory,
  }
  file { '/etc/grid-security/certificates' :
    ensure     => link,
    target     => "/cvmfs/osg.mwt2.org/osg/CA/certificates",
    force      => true,
    require    => Package['cvmfs'],
  }
}

##### PROBABLY NOT NEEDED FOR NON-UC3 SEEDER CLUSTERS 
## this is probably just historical linkage
class cvmfs::uc3::link::app {

  file { [ '/share/osg', '/share/osg/mwt2' ] :
    ensure     => directory,
    mode       => 755,
    owner      => 'root',
    group      => 'root',
    require    => Package['cvmfs'],
  }

  file { '/osg' :
    ensure     => link,
    target     => "/share/osg",
    force      => true
  }

  file { '/share/osg/mwt2/app' :
    ensure     => link,
    target     => "/cvmfs/osg.mwt2.org/mwt2/app",
    force      => false
  }
}

class cvmfs::uc3::link::wnclient {

  $remove_nfs_dirs = [ '/share/wn-client' ]

  mount { $remove_nfs_dirs: ensure => absent }


  file { '/share/wn-client' :
    ensure     => link,
    target     => "/cvmfs/osg.mwt2.org/mwt2/wn-client",
    force      => true,
    require    => [
       Package['cvmfs'],
    ]
  }

}
##########################
