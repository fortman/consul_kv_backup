# frozen_string_literal: true

require 'flazm_ruby_helpers/class'
require 'flazm_ruby_helpers/os'
require 'fileutils'

module ConsulKvBackup
  # Consul storage for previous watch data
  class Git
    include FlazmRubyHelpers::Class

    def initialize(git_config)
      initialize_variables(git_config)
      git_setup
    end

    def process_data(data)
      path = data['key_path']
      value = data['value']
      dc = data['consul_dc']

      git_set_branch(dc)

      if data['old_value'] and !data['new_value']
        git_rm(path)
      else
        git_add(path, value)
      end

       git_push if @git_push
    end

    private

    def git_setup
      FileUtils.mkdir_p(@git_root_dir) unless File.directory?(@git_root_dir)
      FlazmRubyHelpers::Os.exec("git config --global core.sshCommand '#{@git_config['core.sshCommand']}'")
      unless File.directory?("#{@git_root_dir}/.git")
        FlazmRubyHelpers::Os.exec("git clone #{@git_config['remote.origin.url']} .")
      end
      @git_config.each_pair do |key, value|
        FlazmRubyHelpers::Os.exec("git config --local #{key} '#{value}'")
      end
      if FlazmRubyHelpers::Os.exec("git count-objects")[0][0].match(/0 objects, 0 kilobytes/)
        FlazmRubyHelpers::Os.exec("git commit --allow-empty -m 'Initial commit'")
      end
    end

    def git_set_branch(branch = 'master')
      exist = git_branch_exists?(branch)
      if exist
        FlazmRubyHelpers::Os.exec("git reset --hard HEAD")
        FlazmRubyHelpers::Os.exec("git checkout #{branch}")
        FlazmRubyHelpers::Os.exec("git pull origin #{branch}")
      else
        FlazmRubyHelpers::Os.exec("git fetch")
        FlazmRubyHelpers::Os.exec("git branch #{branch} master")
        FlazmRubyHelpers::Os.exec("git checkout #{branch}")
      end
    end

    def git_branch_exists?(branch)
      FlazmRubyHelpers::Os.exec("git branch --list")[0].each do |line|
        return true if line.match(/#{branch}/)
      end
      false
    end

    def git_add(path, value)
      FileUtils.mkdir_p(File.dirname(@git_root_dir))
      file = File.open(path, 'w')
      file.write(value)
      file.close
      FlazmRubyHelpers::Os.exec('git add --all')
      FlazmRubyHelpers::Os.exec('git commit -m "automated backup: updating"')
    end

    def git_rm(path)
      FlazmRubyHelpers::Os.exec("git rm #{path}")
      FlazmRubyHelpers::Os.exec('git commit -m "automated backup: deleting"')
    end

    def git_rebase
      FlazmRubyHelpers::Os.exec('git fetch')
      FlazmRubyHelpers::Os.exec('git reset origin/master')
    end

    def git_push
      FlazmRubyHelpers::Os.exec('git push')
    end

    def defaults
      {
        git_root_dir: '/tmp/consul_backup',
        git_push: false,
        git_config: {}
      }
    end
  end
end