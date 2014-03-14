require 'mina/bundler'
require 'mina/rails'

namespace :puma do
  set :web_server, :puma

  set_default :puma_role,      -> { user }
  set_default :puma_env,       -> { fetch(:rails_env, 'production') }
  set_default :puma_config,    -> { "#{deploy_to}/#{shared_path}/config/puma.rb" }
  set_default :puma_socket,    -> { "#{deploy_to}/#{shared_path}/tmp/sockets/puma.sock" }
  set_default :puma_state,     -> { "#{deploy_to}/#{shared_path}/tmp/pids/puma.state" }
  set_default :puma_pid,       -> { "#{deploy_to}/#{shared_path}/tmp/pids/puma.pid" }
  set_default :puma_cmd,       -> { "#{bundle_prefix} puma" }
  set_default :pumactl_cmd,    -> { "#{bundle_prefix} pumactl" }
  set_default :pumactl_socket, -> { "#{deploy_to}/#{shared_path}/tmp/sockets/puma.sock" }

  desc 'Start puma'
  task :start => :environment do
    queue! %[
      if [ -e '#{pumactl_socket}' ]; then
        echo 'Puma is already running!';
      else
        if [ -e '#{puma_config}' ]; then
          cd #{deploy_to}/#{current_path} && #{puma_cmd} -C #{puma_config}
        else
          cd #{deploy_to}/#{current_path} && #{puma_cmd} -q -d -e #{puma_env} -b 'unix://#{puma_socket}' -S #{puma_state} --control 'unix://#{pumactl_socket}'
        fi
      fi
    ]
  end

  %w[halt stop status].map do |command|
    desc "#{command} puma"
    task command => :environment do
      queue! %[
        if [ -e '#{pumactl_socket}' ]; then
          cd #{deploy_to}/#{current_path} && #{pumactl_cmd} -S #{puma_state} #{command}
        else
          echo 'Puma is not running!';
        fi
      ]
    end
  end

  %w[phased-restart restart].map do |command|
    desc "#{command} puma"
    task command => :environment do
      queue! %[
        if [ -e '#{pumactl_socket}' ]; then
          cd #{deploy_to}/#{current_path} && #{pumactl_cmd} -S #{puma_state} #{command}
        else
          echo 'Puma is not running! Try to start ...';
          cd #{deploy_to}/#{current_path} && #{puma_cmd} -C #{puma_config}
        fi
      ]
    end
  end

end
