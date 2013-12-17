require 'spree_core'
require 'spree_gift_card/engine'

# in config/initializers/spree_gift_card.rb
#
# SpreeGiftCard.configure do |config|
#   config.code_length    = 12
#   config.has_expiration = true
# end
#
module SpreeGiftCard
  class Config
    attr_accessor :has_expiration
    attr_accessor :code_length

    def initialize
      self.has_expiration = false
      self.code_length    = 21
    end
  end

  class << self
    def config
      @config ||= Config.new
      @config
    end

    def configure(&proc)
      @config ||= Config.new
      yield @config
    end

    def has_expiration?
      config.has_expiration
    end
  end
end
