require 'spec_helper'
require 'guard/kitchen'

describe "Guard::Kitchen" do
  let(:kitchen) do
    Guard::Kitchen.new
  end

  describe "start" do
    before(:each) do
      @shellout = double('shellout')
      @shellout.stub(:live_stream=).with(STDOUT)
      @shellout.stub(:run_command)
      @shellout.stub(:error!)
      Guard::UI.stub(:info).with('Guard::Kitchen is starting')
      Mixlib::ShellOut.stub(:new).with("kitchen create", :timeout => 10800).and_return(@shellout)
    end

    it "runs kitchen create" do
      Mixlib::ShellOut.should_receive(:new).with("kitchen create", :timeout => 10800).and_return(@shellout)
      Guard::UI.should_receive(:info).with('Guard::Kitchen is starting')
      Guard::Notifier.should_receive(:notify).with('Kitchen created', :title => 'test-kitchen', :image => :success)
      kitchen.start
    end

    it "notifies on failure" do
      @shellout.should_receive(:error!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      Guard::UI.should_receive(:info).with('Guard::Kitchen is starting')
      Guard::Notifier.should_receive(:notify).with('Kitchen create failed', :title => 'test-kitchen', :image => :failed)
      Guard::UI.should_receive(:info).with('Kitchen failed with Mixlib::ShellOut::ShellCommandFailed')
      expect { kitchen.start }.to throw_symbol(:task_has_failed)
    end
  end

  describe "stop" do
    before(:each) do
      @shellout = double('shellout')
      @shellout.stub(:live_stream=).with(STDOUT)
      @shellout.stub(:run_command)
      @shellout.stub(:error!)
      Guard::UI.stub(:info).with('Guard::Kitchen is stopping')
      Mixlib::ShellOut.stub(:new).with("kitchen destroy", :timeout => 10800).and_return(@shellout)
    end

    it "runs kitchen destroy" do
      Mixlib::ShellOut.should_receive(:new).with("kitchen destroy", :timeout => 10800).and_return(@shellout)
      Guard::UI.should_receive(:info).with('Guard::Kitchen is stopping')
      Guard::Notifier.should_receive(:notify).with('Kitchen destroyed', :title => 'test-kitchen', :image => :success)
      kitchen.stop
    end

    it "notifies on failure" do
      @shellout.should_receive(:error!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      Guard::UI.should_receive(:info).with('Guard::Kitchen is stopping')
      Guard::Notifier.should_receive(:notify).with('Kitchen destroy failed', :title => 'test-kitchen', :image => :failed)
      Guard::UI.should_receive(:info).with('Kitchen failed with Mixlib::ShellOut::ShellCommandFailed')
      expect { kitchen.stop }.to throw_symbol(:task_has_failed)
    end
  end

  describe "reload" do
    it "calls stop and start" do
      kitchen.should_receive(:stop)
      kitchen.should_receive(:start)
      kitchen.reload
    end
  end

  describe "run_all" do
    before(:each) do
      @shellout = double('shellout')
      @shellout.stub(:live_stream=).with(STDOUT)
      @shellout.stub(:run_command)
      @shellout.stub(:error!)
      Guard::UI.stub(:info).with('Guard::Kitchen is running all tests')
      Guard::Notifier.stub(:notify)
      Mixlib::ShellOut.stub(:new).with("kitchen verify", :timeout => 10800).and_return(@shellout)
    end

    it "runs kitchen verify" do
      Guard::UI.should_receive(:info).with('Guard::Kitchen is running all tests')
      Guard::UI.should_receive(:info).with('Kitchen verify succeeded')
      Guard::Notifier.should_receive(:notify).with('Kitchen verify succeeded', :title => 'test-kitchen', :image => :success)
      Mixlib::ShellOut.should_receive(:new).with("kitchen verify", :timeout => 10800).and_return(@shellout)
      kitchen.run_all
    end

    it "notifies on failure" do
      @shellout.should_receive(:error!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      Guard::UI.should_receive(:info).with('Kitchen verify failed with Mixlib::ShellOut::ShellCommandFailed')
      Guard::Notifier.should_receive(:notify).with('Kitchen verify failed', :title => 'test-kitchen', :image => :failed)
      expect { kitchen.run_all }.to throw_symbol(:task_has_failed)
    end
  end

  describe "run_on_changes" do
    describe "with integration test changes" do
      before(:each) do
        @shellout = double('shellout')
        @shellout.stub(:live_stream=).with(STDOUT)
        @shellout.stub(:run_command)
        @shellout.stub(:error!)
        Guard::Notifier.stub(:notify)
      end

      it "runs integration test suites in isolation" do
        Guard::UI.should_receive(:info).with("Guard::Kitchen is running suites: default")
        Guard::UI.should_receive(:info).with("Kitchen verify succeeded for: default")
        Guard::Notifier.stub(:notify).with("Kitchen verify succeeded for: default", :title => 'test-kitchen', :image => :success)
        Mixlib::ShellOut.should_receive(:new).with("kitchen verify '(default)-.+' -p", :timeout=>10800).and_return(@shellout)
        kitchen.run_on_changes(["test/integration/default/bats/foo.bats"])
      end

      it "runs multiple integration test suites in isolation" do
        Guard::UI.should_receive(:info).with("Guard::Kitchen is running suites: default, monkey")
        Guard::UI.should_receive(:info).with("Kitchen verify succeeded for: default, monkey")
        Guard::Notifier.stub(:notify).with("Kitchen verify succeeded for: default, monkey", :title => 'test-kitchen', :image => :success)
        Mixlib::ShellOut.should_receive(:new).with("kitchen verify '(default|monkey)-.+' -p", :timeout=>10800).and_return(@shellout)
        kitchen.run_on_changes(["test/integration/default/bats/foo.bats","test/integration/monkey/bats/foo.bats"])
      end
    end

    describe "with cookbook changes" do
      before(:each) do
        @shellout = double('shellout')
        @shellout.stub(:live_stream=).with(STDOUT)
        @shellout.stub(:run_command)
        @shellout.stub(:error!)
        Guard::Notifier.stub(:notify)
      end

      it "runs a full converge" do
        Guard::UI.should_receive(:info).with("Guard::Kitchen is running converge for all suites")
        Guard::UI.should_receive(:info).with("Kitchen converge succeeded")
        Guard::Notifier.stub(:notify).with("Kitchen converge succeeded", :title => 'test-kitchen', :image => :success)
        Mixlib::ShellOut.should_receive(:new).with('kitchen converge', :timeout => 10800).and_return(@shellout)
        kitchen.run_on_changes(["recipes/default.rb"])
      end
    end
  end
end
