require 'rspec/expectations'

RSpec::Matchers.define :be_equal_hash_within do |tolerance, expected|
	match do |actual|
		Set.new(actual.keys) == Set.new(expected.keys) && actual.keys.all?{|k|
			(actual[k] - expected[k]).abs < tolerance
		}
	end #match

	diffable
end #Matchers.define :be_equal_hash_within

