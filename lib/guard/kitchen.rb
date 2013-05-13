#
# Copyright 2013 Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "guard"
require "guard/guard"
require "mixlib/shellout"

module Guard
  class Kitchen < Guard
    def start
      ::Guard::UI.info("Guard::Kitchen is starting")
      cmd = Mixlib::ShellOut.new("kitchen create", :timeout => 10800)
      cmd.live_stream = STDOUT
      cmd.run_command
      begin
        cmd.error!
        Notifier.notify('Kitchen created', :title => 'test-kitchen', :image => :success)
      rescue Mixlib::ShellOut::ShellCommandFailed => e
        Notifier.notify('Kitchen create failed', :title => 'test-kitchen', :image => :failed)
        ::Guard::UI.info("Kitchen failed with #{e.to_s}")
        throw :task_has_failed
      end
    end

    def stop
      ::Guard::UI.warning("Guard::Kitchen cannot stop for you, due to strange bug.")
      ::Guard::UI.warning("You likely want to run 'kitchen destroy'")
      #::Guard::UI.info("Guard::Kitchen is stopping")
      #cmd = Mixlib::ShellOut.new("kitchen destroy")
      #cmd.live_stream = STDOUT
      #cmd.run_command
      #begin
      #  cmd.error!
      #rescue Mixlib::ShellOut::ShellCommandFailed => e
      #  ::Guard::UI.info("Kitchen failed with #{e.to_s}")
      #  throw :task_has_failed
      #ensure
      #  # Sometimes, we leave the occasional shell process unreaped!
      #  Process.waitall
      #end
    end

    def reload
      stop
      start
    end

    def run_all
      ::Guard::UI.info("Guard::Kitchen is running all tests")
      cmd = Mixlib::ShellOut.new("kitchen verify", :timeout => 10800)
      cmd.live_stream = STDOUT
      cmd.run_command
      begin
        cmd.error!
        Notifier.notify('Kitchen verify succeeded', :title => 'test-kitchen', :image => :success)
        ::Guard::UI.info("Kitchen verify succeeded")
      rescue Mixlib::ShellOut::ShellCommandFailed => e
        Notifier.notify('Kitchen verify failed', :title => 'test-kitchen', :image => :failed)
        ::Guard::UI.info("Kitchen verify failed with #{e.to_s}")
        throw :task_has_failed
      end
    end

    def run_on_changes(paths)
      suites = {}
      paths.each do |path|
        if path =~ /test\/integration\/(.+?)\/.+/
          suites[$1] = true
        end
      end
      if suites.length > 0
        ::Guard::UI.info("Guard::Kitchen is running suites: #{suites.keys.join(', ')}")
        cmd = Mixlib::ShellOut.new("kitchen verify '(#{suites.keys.join('|')})-.+' -p", :timeout => 10800)
        cmd.live_stream = STDOUT
        cmd.run_command
        begin
          cmd.error!
          Notifier.notify("Kitchen verify succeeded for: #{suites.keys.join(', ')}", :title => 'test-kitchen', :image => :success)
          ::Guard::UI.info("Kitchen verify succeeded for: #{suites.keys.join(', ')}")
        rescue Mixlib::ShellOut::ShellCommandFailed => e
          Notifier.notify("Kitchen verify failed for: #{suites.keys.join(', ')}", :title => 'test-kitchen', :image => :failed)
          ::Guard::UI.info("Kitchen verify failed with #{e.to_s}")
          throw :task_has_failed
        end
      else
        ::Guard::UI.info("Guard::Kitchen is running converge for all suites")
        cmd = Mixlib::ShellOut.new("kitchen converge", :timeout => 10800)
        cmd.live_stream = STDOUT
        cmd.run_command
        begin
          cmd.error!
          Notifier.notify("Kitchen converge succeeded", :title => 'test-kitchen', :image => :success)
          ::Guard::UI.info("Kitchen converge succeeded")
        rescue Mixlib::ShellOut::ShellCommandFailed => e
          Notifier.notify("Kitchen converge failed", :title => 'test-kitchen', :image => :failed)
          ::Guard::UI.info("Kitchen converge failed with #{e.to_s}")
          throw :task_has_failed
        end
      end
    end
  end
end
