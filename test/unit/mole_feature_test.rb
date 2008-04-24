require File.dirname(__FILE__) + '/../test_helper'

class MoleFeatureTest < Test::Unit::TestCase     
  fixtures :mole_features
          
  def test_all_feature
    feature = MoleFeature.all_feature
    assert_equal "All", feature.name
  end
end
