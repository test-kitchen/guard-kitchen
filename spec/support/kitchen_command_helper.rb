# frozen_string_literal: true

# Helpers for the shell commands Guard::Kitchen shells out to.
module KitchenCommandHelper
  # Guard::Kitchen gives every kitchen command a three hour timeout.
  KITCHEN_TIMEOUT = 10_800

  # Stubs Mixlib::ShellOut for one exact kitchen command.
  #
  # @param command [String] the command line expected to be run
  # @param fails [Boolean] whether error! should raise ShellCommandFailed
  # @return [InstanceDouble] the stubbed shell out
  def stub_kitchen_command(command, fails: false)
    shell_out = instance_double(Mixlib::ShellOut, "`#{command}`")

    allow(shell_out).to receive(:live_stream=)
    allow(shell_out).to receive(:run_command)
    if fails
      allow(shell_out).to receive(:error!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
    else
      allow(shell_out).to receive(:error!)
    end

    allow(Mixlib::ShellOut).to receive(:new)
      .with(command, timeout: KITCHEN_TIMEOUT)
      .and_return(shell_out)

    shell_out
  end

  # Quiets Guard's UI and notifications so examples assert only what they mean to.
  def silence_guard_output
    allow(Guard::UI).to receive(:info)
    allow(Guard::Notifier).to receive(:notify)
  end
end
