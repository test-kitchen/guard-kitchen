# frozen_string_literal: true

RSpec.describe Guard::Kitchen do
  subject(:kitchen) { described_class.new }

  before { silence_guard_output }

  # start, stop and run_all differ only in the command they run and the
  # messages they emit, so their behaviour is described once here.
  shared_examples "a kitchen command" do |command:, announcement:, success:, failure:|
    it "runs `#{command}` with a three hour timeout" do
      shell_out = stub_kitchen_command(command)

      expect(Mixlib::ShellOut).to receive(:new)
        .with(command, timeout: 10_800)
        .and_return(shell_out)
      expect(shell_out).to receive(:run_command)

      run_command
    end

    it "streams the command output as it happens" do
      shell_out = stub_kitchen_command(command)
      expect(shell_out).to receive(:live_stream=).with($stdout)

      run_command
    end

    it "announces what it is about to do" do
      stub_kitchen_command(command)
      expect(Guard::UI).to receive(:info).with(announcement)

      run_command
    end

    it "notifies success" do
      stub_kitchen_command(command)
      expect(Guard::Notifier).to receive(:notify)
        .with(success, title: "test-kitchen", image: :success)

      run_command
    end

    context "when the command fails" do
      it "notifies failure and tells Guard the task failed" do
        stub_kitchen_command(command, fails: true)

        expect(Guard::Notifier).to receive(:notify)
          .with(failure, title: "test-kitchen", image: :failed)

        expect { run_command }.to throw_symbol(:task_has_failed)
      end

      it "does not report success" do
        stub_kitchen_command(command, fails: true)

        expect(Guard::Notifier).to_not receive(:notify)
          .with(success, anything)

        catch(:task_has_failed) { run_command }
      end
    end
  end

  describe "#initialize" do
    it "is a Guard plugin" do
      expect(described_class.ancestors).to include(Guard::Plugin)
    end

    it "keeps the options it was given" do
      watcher = double("watcher")
      plugin = described_class.new(watchers: [watcher])

      expect(plugin.options[:watchers]).to eq([watcher])
    end

    it "can be built without any options" do
      expect { described_class.new }.to_not raise_error
    end
  end

  describe "#start" do
    def run_command = kitchen.start

    include_examples "a kitchen command",
      command: "kitchen create",
      announcement: "Guard::Kitchen is starting",
      success: "Kitchen created",
      failure: "Kitchen create failed"

    it "reports the underlying error" do
      stub_kitchen_command("kitchen create", fails: true)

      expect(Guard::UI).to receive(:info)
        .with("Kitchen failed with Mixlib::ShellOut::ShellCommandFailed")

      catch(:task_has_failed) { kitchen.start }
    end
  end

  describe "#stop" do
    def run_command = kitchen.stop

    include_examples "a kitchen command",
      command: "kitchen destroy",
      announcement: "Guard::Kitchen is stopping",
      success: "Kitchen destroyed",
      failure: "Kitchen destroy failed"

    it "reports the underlying error" do
      stub_kitchen_command("kitchen destroy", fails: true)

      expect(Guard::UI).to receive(:info)
        .with("Kitchen failed with Mixlib::ShellOut::ShellCommandFailed")

      catch(:task_has_failed) { kitchen.stop }
    end
  end

  describe "#run_all" do
    def run_command = kitchen.run_all

    include_examples "a kitchen command",
      command: "kitchen verify",
      announcement: "Guard::Kitchen is running all tests",
      success: "Kitchen verify succeeded",
      failure: "Kitchen verify failed"

    it "logs success as well as notifying it" do
      stub_kitchen_command("kitchen verify")
      expect(Guard::UI).to receive(:info).with("Kitchen verify succeeded")

      kitchen.run_all
    end
  end

  describe "#reload" do
    it "destroys the instance before recreating it" do
      expect(kitchen).to receive(:stop).ordered
      expect(kitchen).to receive(:start).ordered

      kitchen.reload
    end
  end

  describe "#run_on_changes" do
    context "when integration tests changed" do
      it "verifies only the suite that changed" do
        stub_kitchen_command("kitchen verify '(default)-.+' -p")

        expect(Guard::UI).to receive(:info).with("Guard::Kitchen is running suites: default")
        expect(Guard::UI).to receive(:info).with("Kitchen verify succeeded for: default")
        expect(Guard::Notifier).to receive(:notify)
          .with("Kitchen verify succeeded for: default", title: "test-kitchen", image: :success)

        kitchen.run_on_changes(["test/integration/default/bats/foo.bats"])
      end

      it "verifies every suite that changed" do
        stub_kitchen_command("kitchen verify '(default|monkey)-.+' -p")

        expect(Guard::UI).to receive(:info).with("Guard::Kitchen is running suites: default, monkey")

        kitchen.run_on_changes(
          ["test/integration/default/bats/foo.bats", "test/integration/monkey/bats/foo.bats"]
        )
      end

      it "names a suite once even when several of its files changed" do
        stub_kitchen_command("kitchen verify '(default)-.+' -p")

        expect(Guard::UI).to receive(:info).with("Guard::Kitchen is running suites: default")

        kitchen.run_on_changes(
          ["test/integration/default/bats/foo.bats", "test/integration/default/bats/bar.bats"]
        )
      end

      it "handles suite names containing dashes and underscores" do
        stub_kitchen_command("kitchen verify '(my-suite_2)-.+' -p")

        expect(Guard::UI).to receive(:info).with("Guard::Kitchen is running suites: my-suite_2")

        kitchen.run_on_changes(["test/integration/my-suite_2/bats/foo.bats"])
      end

      context "when the verify fails" do
        it "notifies failure for the suites it tried" do
          stub_kitchen_command("kitchen verify '(default)-.+' -p", fails: true)

          expect(Guard::Notifier).to receive(:notify)
            .with("Kitchen verify failed for: default", title: "test-kitchen", image: :failed)
          expect(Guard::UI).to receive(:info)
            .with("Kitchen verify failed with Mixlib::ShellOut::ShellCommandFailed")

          expect { kitchen.run_on_changes(["test/integration/default/bats/foo.bats"]) }
            .to throw_symbol(:task_has_failed)
        end
      end
    end

    context "when something other than an integration test changed" do
      it "converges every suite" do
        stub_kitchen_command("kitchen converge")

        expect(Guard::UI).to receive(:info).with("Guard::Kitchen is running converge for all suites")
        expect(Guard::UI).to receive(:info).with("Kitchen converge succeeded")
        expect(Guard::Notifier).to receive(:notify)
          .with("Kitchen converge succeeded", title: "test-kitchen", image: :success)

        kitchen.run_on_changes(["recipes/default.rb"])
      end

      it "converges when nothing at all changed" do
        stub_kitchen_command("kitchen converge")

        expect(Guard::UI).to receive(:info).with("Guard::Kitchen is running converge for all suites")

        kitchen.run_on_changes([])
      end

      it "converges for a path under test/integration with no suite directory" do
        stub_kitchen_command("kitchen converge")

        expect(Guard::UI).to receive(:info).with("Guard::Kitchen is running converge for all suites")

        kitchen.run_on_changes(["test/integration/README.md"])
      end

      context "when the converge fails" do
        it "notifies failure and tells Guard the task failed" do
          stub_kitchen_command("kitchen converge", fails: true)

          expect(Guard::Notifier).to receive(:notify)
            .with("Kitchen converge failed", title: "test-kitchen", image: :failed)
          expect(Guard::UI).to receive(:info)
            .with("Kitchen converge failed with Mixlib::ShellOut::ShellCommandFailed")

          expect { kitchen.run_on_changes(["recipes/default.rb"]) }
            .to throw_symbol(:task_has_failed)
        end
      end
    end
  end
end
