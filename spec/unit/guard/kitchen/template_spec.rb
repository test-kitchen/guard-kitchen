# frozen_string_literal: true

require "guard/compat/test/template"

# The Guardfile shipped in lib/guard/kitchen/templates is what `guard init
# kitchen` writes into a cookbook, so its watch patterns are part of the
# public behaviour of this gem.
RSpec.describe "the bundled Guardfile template" do
  subject(:template) { Guard::Compat::Test::Template.new(Guard::Kitchen) }

  {
    "integration tests" => "test/integration/default/bats/foo.bats",
    "recipes" => "recipes/default.rb",
    "attributes" => "attributes/default.rb",
    "files" => "files/default/foo.conf",
    "templates" => "templates/default/foo.erb",
    "providers" => "providers/thing.rb",
    "resources" => "resources/thing.rb",
  }.each do |description, path|
    it "watches #{description}" do
      expect(template.changed(path)).to eq([path])
    end
  end

  it "ignores paths a cookbook does not test from" do
    expect(template.changed("README.md")).to be_empty
  end

  it "ignores metadata.rb, which does not affect a converge on its own" do
    expect(template.changed("metadata.rb")).to be_empty
  end
end
