class compass_agent_config (
$additional_nxlog_config = "compass_agent_config/${server_type}/${server_type}_${operatingsystem}_additional.nxlog.conf.erb",
)
{

  include 'nxlog'

  concat::fragment {'extrabase1_nxlog_config':
    target  => "${nxlog::cfg_dir}/nxlog.conf",
    content => template('compass_agent_config/additional.nxlog.conf.erb'),
    order   => '02',
  }
 # $additional_nxlog_config_with_os = "compass_agent_config/${server_type}/${server_type}_${operatingsystem}_additional.nxlog.conf.erb"
 # concat::fragment {'extrabase2_nxlog_config':
 #   target  => "${nxlog::cfg_dir}/nxlog.conf",
 #   content => template($additional_nxlog_config_with_os),
 #   order   => '03',
 # }

  concat::fragment {'extrabase3_nxlog_config':
    target  => "${nxlog::cfg_dir}/nxlog.conf",
    content => template($additional_nxlog_config),
    order   => '04',
  }
}
