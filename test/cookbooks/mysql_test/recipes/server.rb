node.set['mysql']['server_debian_password'] = 'ilikerandompasswords'
node.set['mysql']['server_root_password']   = 'ilikerandompasswords'
node.set['mysql']['server_repl_password']   = 'ilikerandompasswords'

include_recipe 'mysql::ruby'
include_recipe 'yum::epel' if platform_family?('rhel')

file '/etc/sysconfig/network' do
  content 'NETWORKING=yes'
  action  :create_if_missing
  only_if { platform_family?('rhel', 'fedora') }
end

include_recipe 'mysql::server'

mysql_connection = {
  :host     => 'localhost',
  :username => 'root',
  :password => node['mysql']['server_root_password']
}

mysql_database node['mysql_test']['database'] do
  connection mysql_connection
  action     :create
end

mysql_database_user node['mysql_test']['username'] do
  connection    mysql_connection
  password      node['mysql_test']['password']
  database_name node['mysql_test']['database']
  host          'localhost'
  privileges    [:select, :update, :insert, :delete]
  action        [:create, :grant]
end

mysql_conn_args = "--user=root --password='#{node['mysql']['server_root_password']}'"

execute 'create-sample-data' do
  command %Q{mysql #{mysql_conn_args} #{node['mysql_test']['database']} <<EOF
    CREATE TABLE tv_chef (name VARCHAR(32) PRIMARY KEY);
    INSERT INTO tv_chef (name) VALUES ('Alison Holst');
    INSERT INTO tv_chef (name) VALUES ('Nigella Lawson');
    INSERT INTO tv_chef (name) VALUES ('Paula Deen');
EOF}
  not_if "echo 'SELECT count(name) FROM tv_chef' | mysql #{mysql_conn_args} --skip-column-names #{node['mysql_test']['database']} | grep '^3$'"
end
