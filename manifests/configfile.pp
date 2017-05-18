# == define: logstash::configfile
#
# This define is to manage the config files for Logstah
#
# === Parameters
#
# [*file*]
#  Supply a template to be used for the config
#
# [*order*]
#  The order number controls in which sequence the config file fragments are concatenated
#
# === Examples
#
#     logstash::configfile { 'apache':
#       content => template("${module_name}/path/to/apache.conf.erb"),
#       order   => 10
#     }
#
#     or with a puppet file source:
#
#     logstash::configfile { 'apache':
#       source => 'puppet://path/to/apache.conf',
#       order  => 10
#     }
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
#
define logstash::configfile (
  $content = undef,
  $source = undef,
  $order = 10,
  $service_name = $logstash::params::service_name,
) {

  concat::fragment { $name:
    target  => "ls_config_${service_name}",
    content => $content,
    source  => $source,
    order   => $order,
  }

}
