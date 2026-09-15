# frozen_string_literal: true

# A class that records every attempt to build it through JSON.load's
# create_additions hook, so specs can assert cached entries never do that.
class JsonGadget
  def self.invocations
    @invocations ||= []
  end

  def self.json_create(attributes)
    invocations << attributes
    new
  end
end
