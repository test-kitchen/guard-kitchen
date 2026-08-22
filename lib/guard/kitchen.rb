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
require "guard/plugin"
require "mixlib/shellout" unless defined?(Mixlib::ShellOut)
require "guard/kitchen/version"

# Guard's namespace, reopened here to add the Kitchen plugin.
#
# @see https://github.com/guard/guard Guard
module Guard
  # A Guard plugin that drives Test Kitchen.
  #
  # Guard calls into this plugin as files change in a cookbook: it creates the
  # instances when Guard starts, destroys them when Guard stops, and runs
  # `kitchen verify` or `kitchen converge` in between depending on what changed.
  #
  # Every command is shelled out to with a three hour timeout and its output is
  # streamed straight to `$stdout`, so a long converge stays visible. When a
  # command fails the plugin notifies through Guard and throws
  # `:task_has_failed`, which is how a Guard plugin reports failure without
  # bringing the whole session down.
  #
  # @example Watch a cookbook with the bundled Guardfile
  #   guard init kitchen
  #   guard
  #
  # @see https://github.com/test-kitchen/test-kitchen Test Kitchen
  # @see https://github.com/guard/guard Guard
  class Kitchen < Plugin
    # The timeout, in seconds, given to every kitchen command. Three hours,
    # since a converge over a slow network can legitimately take that long.
    COMMAND_TIMEOUT = 10_800

    # @param options [Hash] options Guard passes to the plugin, including the
    #   `:watchers` declared for it in the Guardfile
    # @option options [Array<Guard::Watcher>] :watchers the Guardfile watchers
    def initialize(options = {})
      super
      # you can still access the watchers with options[:watchers]
      # rest of the implementation...
    end

    # Creates the Test Kitchen instances.
    #
    # Called by Guard when the session starts, and again by {#reload}.
    #
    # @return [void]
    # @raise [UncaughtThrowError] throws `:task_has_failed` if `kitchen create`
    #   exits non-zero
    def start
      ::Guard::UI.info("Guard::Kitchen is starting")
      cmd = Mixlib::ShellOut.new("kitchen create", timeout: COMMAND_TIMEOUT)
      cmd.live_stream = STDOUT
      cmd.run_command
      begin
        cmd.error!
        Notifier.notify("Kitchen created", title: "test-kitchen", image: :success)
      rescue Mixlib::ShellOut::ShellCommandFailed => e
        Notifier.notify("Kitchen create failed", title: "test-kitchen", image: :failed)
        ::Guard::UI.info("Kitchen failed with #{e}")
        throw :task_has_failed
      end
    end

    # Destroys the Test Kitchen instances.
    #
    # Called by Guard when the session ends, and by {#reload} before it starts
    # the instances again.
    #
    # @return [void]
    # @raise [UncaughtThrowError] throws `:task_has_failed` if `kitchen destroy`
    #   exits non-zero
    def stop
      ::Guard::UI.info("Guard::Kitchen is stopping")
      cmd = Mixlib::ShellOut.new("kitchen destroy", timeout: COMMAND_TIMEOUT)
      cmd.live_stream = STDOUT
      cmd.run_command
      begin
        cmd.error!
        Notifier.notify("Kitchen destroyed", title: "test-kitchen", image: :success)
      rescue Mixlib::ShellOut::ShellCommandFailed => e
        Notifier.notify("Kitchen destroy failed", title: "test-kitchen", image: :failed)
        ::Guard::UI.info("Kitchen failed with #{e}")
        throw :task_has_failed
      end
    end

    # Rebuilds the instances from scratch by destroying and recreating them.
    #
    # @return [void]
    # @see #stop
    # @see #start
    def reload
      stop
      start
    end

    # Verifies every suite.
    #
    # @return [void]
    # @raise [UncaughtThrowError] throws `:task_has_failed` if `kitchen verify`
    #   exits non-zero
    def run_all
      ::Guard::UI.info("Guard::Kitchen is running all tests")
      cmd = Mixlib::ShellOut.new("kitchen verify", timeout: COMMAND_TIMEOUT)
      cmd.live_stream = STDOUT
      cmd.run_command
      begin
        cmd.error!
        Notifier.notify("Kitchen verify succeeded", title: "test-kitchen", image: :success)
        ::Guard::UI.info("Kitchen verify succeeded")
      rescue Mixlib::ShellOut::ShellCommandFailed => e
        Notifier.notify("Kitchen verify failed", title: "test-kitchen", image: :failed)
        ::Guard::UI.info("Kitchen verify failed with #{e}")
        throw :task_has_failed
      end
    end

    # Runs the narrowest thing that covers the change.
    #
    # Paths under `test/integration/<suite>/` name the suites they belong to,
    # so only those suites are verified. Anything else -- a recipe, an
    # attribute, a template -- could affect every suite, so the whole cookbook
    # is converged instead.
    #
    # @example Only the suites whose tests changed are verified
    #   plugin.run_on_changes(["test/integration/default/bats/foo.bats"])
    #   #=> runs: kitchen verify '(default)-.+' -p
    #
    # @example A recipe change converges everything
    #   plugin.run_on_changes(["recipes/default.rb"])
    #   #=> runs: kitchen converge
    #
    # @param paths [Array<String>] paths Guard saw change
    # @return [void]
    # @raise [UncaughtThrowError] throws `:task_has_failed` if the kitchen
    #   command exits non-zero
    def run_on_changes(paths)
      suites = {}
      paths.each do |path|
        if path =~ %r{test/integration/(.+?)/.+}
          suites[$1] = true
        end
      end
      if suites.length > 0
        ::Guard::UI.info("Guard::Kitchen is running suites: #{suites.keys.join(", ")}")
        cmd = Mixlib::ShellOut.new("kitchen verify '(#{suites.keys.join("|")})-.+' -p", timeout: COMMAND_TIMEOUT)
        cmd.live_stream = STDOUT
        cmd.run_command
        begin
          cmd.error!
          Notifier.notify("Kitchen verify succeeded for: #{suites.keys.join(", ")}", title: "test-kitchen", image: :success)
          ::Guard::UI.info("Kitchen verify succeeded for: #{suites.keys.join(", ")}")
        rescue Mixlib::ShellOut::ShellCommandFailed => e
          Notifier.notify("Kitchen verify failed for: #{suites.keys.join(", ")}", title: "test-kitchen", image: :failed)
          ::Guard::UI.info("Kitchen verify failed with #{e}")
          throw :task_has_failed
        end
      else
        ::Guard::UI.info("Guard::Kitchen is running converge for all suites")
        cmd = Mixlib::ShellOut.new("kitchen converge", timeout: COMMAND_TIMEOUT)
        cmd.live_stream = STDOUT
        cmd.run_command
        begin
          cmd.error!
          Notifier.notify("Kitchen converge succeeded", title: "test-kitchen", image: :success)
          ::Guard::UI.info("Kitchen converge succeeded")
        rescue Mixlib::ShellOut::ShellCommandFailed => e
          Notifier.notify("Kitchen converge failed", title: "test-kitchen", image: :failed)
          ::Guard::UI.info("Kitchen converge failed with #{e}")
          throw :task_has_failed
        end
      end
    end
  end
end
