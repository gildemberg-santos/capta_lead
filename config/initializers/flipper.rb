# frozen_string_literal: true

require "flipper"
require "flipper-active_record"

Flipper.configure do |config|
  config.adapter do
    Flipper::Adapters::ActiveRecord.new
  end
end
