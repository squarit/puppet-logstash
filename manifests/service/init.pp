# == Define: logstash::service::init
#
# This class exists to coordinate all service management related actions,
# functionality and logical units in a central place.
#
# <b>Note:</b> "service" is the Puppet term and type for background processes
# in general and is used in a platform-independent way. E.g. "service" means
# "daemon" in relation to Unix-like systems.
#
#
# === Parameters
#
# This class does not provide any parameters.
#
#
# === Examples
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
#
define logstash::service::init (
  $ensure             = $logstash::ensure,
  $status             = $logstash::status,
  $restart_on_change  = $logstash::restart_on_change,
  $init_defaults_file = $logstash::init_defaults_file,
  $init_defaults      = $logstash::init_defaults,
  $init_template      = $logstash::init_template,
  $defaults_location  = $logstash::params::defaults_location,
  $service_hasstatus  = $logstash::params::service_hasstatus,
  $service_hasrestart = $logstash::params::service_hasrestart,
  $service_pattern    = $logstash::params::service_pattern,
  $configdir          = $logstash::configdir,
  $logstash_user      = $logstash::logstash_user,
  $logstash_group     = $logstash::logstash_group,
) {

  #### Service management

  # set params: in operation
  if $ensure == 'present' {

    case $status {
      # make sure service is currently running, start it on boot
      'enabled': {
        $service_ensure = 'running'
        $service_enable = true
      }
      # make sure service is currently stopped, do not start it on boot
      'disabled': {
        $service_ensure = 'stopped'
        $service_enable = false
      }
      # make sure service is currently running, do not start it on boot
      'running': {
        $service_ensure = 'running'
        $service_enable = false
      }
      # do not start service on boot, do not care whether currently running
      # or not
      'unmanaged': {
        $service_ensure = undef
        $service_enable = false
      }
      # unknown status
      # note: don't forget to update the parameter check in init.pp if you
      #       add a new or change an existing status.
      default: {
        fail("\"${status}\" is an unknown service status value")
      }
    }

  # set params: removal
  } else {

    # make sure the service is stopped and disabled (the removal itself will be
    # done by package.pp)
    $service_ensure = 'stopped'
    $service_enable = false

  }

  $notify_service = $restart_on_change ? {
    true  => Service[$name],
    false => undef,
  }


  if ( $status != 'unmanaged' ) {

    # defaults file content. Either from a hash or file
    if ($init_defaults_file != undef) {
      $defaults_content = undef
      $defaults_source  = $init_defaults_file
    } elsif ($init_defaults != undef and is_hash($init_defaults) ) {
      $defaults_content = template("${module_name}/etc/sysconfig/defaults.erb")
      $defaults_source  = undef
    } else {
      $defaults_content = undef
      $defaults_source  = undef
    }

    # Check if we are going to manage the defaults file.
    if ( $defaults_content != undef or $defaults_source != undef ) {

      file { "${defaults_location}/${name}":
        ensure  => $ensure,
        source  => $defaults_source,
        content => $defaults_content,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        before  => Service[$name],
        notify  => $notify_service
      }

    }

    # init file from template
    if ($init_template != undef) {

      file { "/etc/init.d/${name}":
        ensure  => $ensure,
        content => template($init_template),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        before  => Service[$name],
        notify  => $notify_service
      }

    }

  }

  # create the config file
  file_concat { "ls-config_${name}":
    ensure  => 'present',
    tag     => "LS_CONFIG_${::fqdn}_${name}",
    path    => "${configdir}/conf.d/${name}.conf",
    owner   => $logstash_user,
    group   => $logstash_group,
    mode    => '0644',
    notify  => $notify_service,
    require => File[ "${configdir}/conf.d" ]
  }

  # action
  service { $name:
    ensure     => $service_ensure,
    enable     => $service_enable,
    name       => $name,
    hasstatus  => $service_hasstatus,
    hasrestart => $service_hasrestart,
    pattern    => $service_pattern,
  }

}
