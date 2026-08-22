require "guard"
require "guard/plugin"

module Guard
  class Kitchen < Plugin
    # The released version of guard-kitchen.
    #
    # @return [String] a frozen semantic version string
    VERSION = "0.1.0".freeze
  end
end
