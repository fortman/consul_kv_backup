# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'open3'
require 'flazm_ruby_helpers/os'
require 'flazm_ruby_helpers/http'
require 'flazm_ruby_helpers/project'

spec_file = Gem::Specification.load('consul_kv_backup.gemspec')

task default: :docker_build

task :docker_tag, [:version, :docker_image_id] do |_task, args|
  puts "Docker id #{args['docker_image_id']} => tag rfortman/consul_kv_backup:#{args['version']}"
  tag_cmd = "docker tag #{args['docker_image_id']} rfortman/consul_kv_backup:#{args['version']}"
  Open3.popen3(tag_cmd) do |_stdin, _stdout, stderr, wait_thr|
    error = stderr.read
    puts error unless wait_thr.value.success?
  end
end

task docker_build: [:build] do
  docker_image_id = nil
  build_cmd = "docker build --build-arg gem_file=consul_kv_backup-#{spec_file.version}.gem ."
  threads = []
  Open3.popen3(build_cmd) do |_stdin, stdout, stderr, wait_thr|
    { out: stdout, err: stderr }.each do |key, stream|
      threads << Thread.new do
        until (raw_line = stream.gets).nil?
          match = raw_line.match(/Successfully built (.*)$/i)
          docker_image_id = match.captures[0] if match
          puts raw_line.to_s
        end
      end
    end
    threads.each(&:join)
    if wait_thr.value.success?
      Rake::Task['docker_tag'].invoke(spec_file.version, docker_image_id)
      Rake::Task['docker_tag'].reenable
      Rake::Task['docker_tag'].invoke('latest', docker_image_id)
    end
  end
end

task :start_deps do
  cmd = 'docker-compose --file test/docker-compose.yml up -d consul rabbitmq'
  FlazmRubyHelpers::Os.exec(cmd)
  urls = [
    'http://localhost:8500/v1/status/leader',
    'http://localhost:15672'
  ]
  FlazmRubyHelpers::Http.wait_for_urls(urls)
  cmd = 'docker-compose --file test/docker-compose.yml up -d consul-kv-watcher'
  FlazmRubyHelpers::Os.exec(cmd)
end

task up: [:start_deps] do
  cmd = 'docker-compose --file test/docker-compose.yml up -d consul-kv-backup'
  _output, _status = FlazmRubyHelpers::Os.exec(cmd)
end

task :down do
  cmd = 'docker-compose --file test/docker-compose.yml down'
  _output, _status = FlazmRubyHelpers::Os.exec(cmd)
end

task publish: [:build, :docker_build] do
  FlazmRubyHelpers::Project::Git.publish(spec_file.version.to_s, 'origin', 'master')
  FlazmRubyHelpers::Project::Docker.publish(spec_file.metadata['docker_image_name'], spec_file.version.to_s)
  FlazmRubyHelpers::Project::Docker.publish(spec_file.metadata['docker_image_name'], 'latest')
  FlazmRubyHelpers::Project::Gem.publish(spec_file.name.to_s, spec_file.version.to_s)
end

task :unpublish do
  _output, _success = FlazmRubyHelpers::Os.exec("git tag --delete #{spec_file.version.to_s}")
  _output, _success = FlazmRubyHelpers::Os.exec("gem yank #{spec_file.name.to_s} -v #{spec_file.version.to_s}")
  puts "Please delete the tag from dockerhub at https://cloud.docker.com/repository/registry-1.docker.io/#{spec_file.metadata['docker_image_name']}/tags"
end
