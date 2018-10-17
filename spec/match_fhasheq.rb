require 'rspec/expectations'

RSpec::Matchers.define :be_equal_hash_within do |tolerance, expected|
	match do |actual|
		Set.new(actual.keys) == Set.new(expected.keys) && actual.keys.all?{|k|
			(actual[k] - expected[k]).abs < tolerance
		}
	end #match

	diffable
end #Matchers.define :be_equal_hash_within

RSpec::Matchers.define :be_equal_array_hash_within do |tolerance, expected|
	match do |actual|
		Set.new(actual.keys) == Set.new(expected.keys) &&
			actual.keys.all?{|k|
			actual[k].length == expected[k].length &&
				actual[k].each.with_index.all?{|v,i|
				(v - expected[k][i]).abs < tolerance
			}
		}
	end #match

	diffable
end #Matchers.define :be_equal_array_hash_within
