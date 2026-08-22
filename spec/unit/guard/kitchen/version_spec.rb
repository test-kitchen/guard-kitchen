# frozen_string_literal: true

RSpec.describe "Guard::Kitchen::VERSION" do
  subject(:version) { Guard::Kitchen::VERSION }

  it "is defined" do
    expect(defined?(Guard::Kitchen::VERSION)).to eq("constant")
  end

  it "is a frozen string" do
    expect(version).to be_a(String).and be_frozen
  end

  it "looks like a version number" do
    expect(version).to match(/\A\d+\.\d+\.\d+/)
  end

  it "matches the version the gemspec advertises" do
    gemspec = Gem::Specification.load(
      File.expand_path("../../../../guard-kitchen.gemspec", __dir__)
    )

    expect(gemspec.version.to_s).to eq(version)
  end
end
