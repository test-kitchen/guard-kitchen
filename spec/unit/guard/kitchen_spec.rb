require 'spec_helper'
require 'guard/kitchen'

describe "Guard::Kitchen" do
  describe "start" do
    it "runs kitchen create" do
      shellout = double('shellout')
      shellout.should_receive(:live_stream=).with(STDOUT)
      shellout.should_receive(:run_command)
      shellout.should_receive(:error!)
      Mixlib::ShellOut.should_receive(:new).with("kitchen create").and_return(shellout)
      Guard::Kitchen.new.start
    end
  end
end
