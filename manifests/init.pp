# Debian/nexenta specific build module
#
# build::install { 'top':
#   download => 'http://www.unixtop.org/dist/top-3.7.tar.gz',
#   creates  => '/usr/local/bin/top',
# }

define build::install ($download, $creates, $pkg_folder='', $pkg_format="tar", $pkg_extension="", $buildoptions="", $makeopts="", $makeinstallopts="", $extractorcmd="", $rm_build_folder=true) {
  
  if defined( Package['autoconf'] ) { debug("Package autoconf already installed") } else { package { 'autoconf': ensure => installed } }
  if defined( Package['automake'] ) { debug("Package automake already installed") } else { package { 'automake': ensure => installed } }
  if defined( Package['binutils'] ) { debug("Package binutils already installed") } else { package { 'binutils': ensure => installed } }
  if defined( Package['bison'] ) { debug("Package bison already installed") } else { package { 'bison': ensure => installed } }
  if defined( Package['flex'] ) { debug("Package flex already installed") } else { package { 'flex': ensure => installed } }
  if defined( Package['gcc'] ) { debug("Package gcc already installed") } else { package { 'gcc': ensure => installed } }
  if defined( Package['gcc-c++'] ) { debug("Package gcc-c++ already installed") } else { package { 'gcc-c++': ensure => installed } }
  if defined( Package['gdb'] ) { debug("Package gdb already installed") } else { package { 'gdb': ensure => installed } }
  if defined( Package['gettext'] ) { debug("Package gettext already installed") } else { package { 'gettext': ensure => installed } }
  if defined( Package['libtool'] ) { debug("Package libtool already installed") } else { package { 'libtool': ensure => installed } }
  if defined( Package['make'] ) { debug("Package make already installed") } else { package { 'make': ensure => installed } }
  if defined( Package['pkgconfig'] ) { debug("Package pkgconfig already installed") } else { package { 'pkgconfig': ensure => installed } }
  
  $cwd    = "/usr/local/src"
  
  $test   = "/usr/bin/test"
  $unzip  = "/usr/bin/unzip"
  $tar    = "/bin/tar"
  $bunzip = "/usr/bin/bunzip2"
  $gunzip = "/usr/bin/gunzip"
  
  $filename = basename($download)
  
  $extension = $pkg_format ? {
    zip     => ".zip",
    bzip    => ".tar.bz2",
    tar     => ".tar.gz",
    default => $pkg_extension,
  }
  
  $foldername = $pkg_folder ? {
    ''      => gsub($filename, $extension, ""),
    default => $pkg_folder,
  }
  
  $extractor = $pkg_format ? {
    zip     => "$unzip -q -d $cwd $cwd/$filename",
    bzip    => "$bunzip -c $cwd/$filename | $tar -xf -",
    tar     => "$gunzip < $cwd/$filename | $tar -xf -",
    default => $extractorcmd,
  }
  
  exec { "download-$name":
    cwd     => "$cwd",
    command => "/usr/bin/wget -q $download",
    timeout => 120, # 2 minutes
    unless  => "$test -f $creates",
  }
  
  exec { "extract-$name":
    cwd     => "$cwd",
    command => "$extractor",
    timeout => 120, # 2 minutes
    require => Exec["download-$name"],
    unless  => "$test -f $creates"
  }
  
  exec { "config-$name":
    cwd     => "$cwd/$foldername",
    command => "$cwd/$foldername/configure $buildoptions",
    timeout => 120, # 2 minutes
    require => Exec["extract-$name"],
    unless  => "$test -f $creates"
  }
  
  exec { "make-install-$name":
    cwd     => "$cwd/$foldername",
    command => "/usr/bin/make $makeopts && /usr/bin/make install $makeinstallopts",
    timeout => 600, # 10 minutes
    require => Exec["config-$name"],
    unless  => "$test -f $creates"
  }
  
  # remove build folder
  case $rm_build_folder {
    true: {
      notice("remove build folder")
      exec { "remove-$name-build-folder":
        cwd     => "$cwd",
        command => "/bin/rm -rf $cwd/$foldername",
        require => Exec["make-install-$name"],
      } # exec
    } # true
  } # case
  
}
