#
# Copyright 2013 Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
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
      run_kitchen("kitchen create",
        success: "Kitchen created",
        failure: "Kitchen create failed",
        error_prefix: "Kitchen",
        log_success: false)
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
      run_kitchen("kitchen destroy",
        success: "Kitchen destroyed",
        failure: "Kitchen destroy failed",
        error_prefix: "Kitchen",
        log_success: false)
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
      run_kitchen("kitchen verify",
        success: "Kitchen verify succeeded",
        failure: "Kitchen verify failed",
        error_prefix: "Kitchen verify")
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
      suites = changed_suites(paths)

      if suites.empty?
        ::Guard::UI.info("Guard::Kitchen is running converge for all suites")
        run_kitchen("kitchen converge",
          success: "Kitchen converge succeeded",
          failure: "Kitchen converge failed",
          error_prefix: "Kitchen converge")
      else
        names = suites.join(", ")
        ::Guard::UI.info("Guard::Kitchen is running suites: #{names}")
        run_kitchen("kitchen verify '(#{suites.join("|")})-.+' -p",
          success: "Kitchen verify succeeded for: #{names}",
          failure: "Kitchen verify failed for: #{names}",
          error_prefix: "Kitchen verify")
      end
    end

    private

    # Picks out the integration suites the changed paths belong to.
    #
    # @param paths [Array<String>] paths Guard saw change
    # @return [Array<String>] suite names, in the order first seen, without
    #   duplicates
    def changed_suites(paths)
      paths.filter_map { |path| path[%r{test/integration/(.+?)/.+}, 1] }.uniq
    end

    # Runs one kitchen command, streaming its output, and reports the result
    # through Guard.
    #
    # This is the shape every kitchen command in this plugin shares: run it,
    # notify success, or notify failure and tell Guard the task failed.
    #
    # @param command [String] the command line to run
    # @param success [String] message reported when the command succeeds
    # @param failure [String] message reported when the command fails
    # @param error_prefix [String] prefix for the log line describing the error
    # @param log_success [Boolean] whether to also log the success message
    # @return [void]
    # @raise [UncaughtThrowError] throws `:task_has_failed` if the command
    #   exits non-zero
    def run_kitchen(command, success:, failure:, error_prefix:, log_success: true)
      cmd = Mixlib::ShellOut.new(command, timeout: COMMAND_TIMEOUT)
      cmd.live_stream = $stdout
      cmd.run_command
      cmd.error!

      Notifier.notify(success, title: "test-kitchen", image: :success)
      ::Guard::UI.info(success) if log_success
    rescue Mixlib::ShellOut::ShellCommandFailed => e
      Notifier.notify(failure, title: "test-kitchen", image: :failed)
      ::Guard::UI.info("#{error_prefix} failed with #{e}")
      throw :task_has_failed
    end
  end
end
