# frozen_string_literal: true

module Qualification
  class Interpreter
    Result = Struct.new(:status, :confidence, keyword_init: true)

    def self.call(probability, threshold: 0.5)
      distance = (probability - threshold).abs.round(4)
      confidence =
        if distance >= 0.3 then "high"
        elsif distance >= 0.1 then "medium"
        else "low"
        end

      Result.new(
        status: probability >= threshold ? "qualified" : "not_qualified",
        confidence:
      )
    end
  end
end
