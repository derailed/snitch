require File.dirname(__FILE__) + '/../test_helper'

class MoleLogTest < Test::Unit::TestCase     
  all_fixtures
          
  def test_fetch_top_features
    filter    = SnitchFilter.create_filter      
    timestamp = Time.gm( 2007, "apr", 27, 1, 0 )
    features  = MoleLog.fetch_top_features( filter, timestamp )
    assert_equal  4, features.first.mole_feature_id
    assert_equal "3", features.first.count
    assert_equal  3,  features.last.mole_feature_id
    assert_equal "1", features.last.count    
  end

  def test_fetch_top_users
    filter    = SnitchFilter.create_filter      
    timestamp = Time.gm( 2007, "apr", 27, 1, 0 )
    features  = MoleLog.fetch_top_users( filter, timestamp )
    assert_equal  1    , features.size
    assert_equal "6"   , features.first.count
    assert_equal "Fred", features.first.name
    assert_equal 1     , features.first.user_id
  end
  
  def test_fetch_live_users
    filter    = SnitchFilter.create_filter      
    timestamp = Time.gm( 2007, "apr", 27, 1, 0 )
    features  = MoleLog.fetch_live_users( filter, timestamp )
    assert_equal  1    , features.size
    assert_equal "Fred", features.first.name
  end           

  def test_fetch_logs
    filter    = SnitchFilter.create_filter      
    timestamp = Time.gm( 2007, "apr", 27, 1, 0 )
    features  = MoleLog.fetch_logs( filter, timestamp )
    assert_equal  6, features.size
  end     
                  
  def test_find_latest_logs
    filter    = SnitchFilter.create_filter      
    timestamp = Time.gm( 2007, "apr", 27, 7, 0 )
    features  = MoleLog.find_latest_logs( 10 )
    assert_equal  6, features.size
  end     
end
