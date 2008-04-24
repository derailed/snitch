require File.dirname(__FILE__) + '/../test_helper'

class SnitchHelperTest < Test::Unit::TestCase 
  all_helpers
  all_fixtures
          
  def test_format_time
    now        = Time.gm( 2007, "apr", 27, 6, 30, 30 )
    created_at = Time.gm( 2007, "apr", 27, 6, 30, 30 )
    assert_equal "06:30:30", format_time( created_at, now ), "Expecting same day time"
                                                  
    created_at = Time.gm( 2007, "apr", 26, 6, 30, 30 )    
    assert_equal "04/26 06:30:30", format_time( created_at, now ), "Expecting different day time"    
  end        
                          
  def test_format_feature_name
    assert_equal "Fred:blee"   , format_feature_name( "FredController:blee" )
    assert_equal "DohFred:blee", format_feature_name( "DohFredController:blee" )
    assert_equal "All"         , format_feature_name( "All" )    
    assert_equal "N/A"         , format_feature_name( nil )    
  end  
                 
  def test_format_user
    fred = User.find( 1 )
    assert_equal "Fred", format_user( fred ) 
  end  
                  
  # def test_tag_img       
  #   log = mole_logs( :perf )
  #   assert_equal "<img class=\"image_tag\">clock.gif</img>", tag_img( log )
  #   log = mole_logs( :exception )                                                              
  #   assert_equal "<img class=\"image_tag\">bomb.gif</img>", tag_img( log )    
  #   log = mole_logs( :log1 )                                                              
  #   assert_equal "<img class=\"image_tag\">item.gif</img>", tag_img( log )    
  # end         

  def test_log_color      
    log = mole_logs( :perf )
    assert_equal "#056251", log_color( log )
    log = mole_logs( :exception )                                                              
    assert_equal "#993366", log_color( log )    
    log = mole_logs( :log1 )                                                              
    assert_equal "#4c4d4d", log_color( log )    
  end    
     
  def test_format_params     
    log = mole_logs( :log1 )             
    assert_equal "<span>arg1: val1</span> <span>arg2: val2</span>", format_params( log.params )
    log = mole_logs( :no_args )             
    assert_equal "no args", format_params( log.params )
  end

  def test_format_flat_params     
    log = mole_logs( :log1 )             
    assert_equal "arg1: val1\rarg2: val2", format_flat_params( log.params )
    log = mole_logs( :no_args )             
    assert_equal "no args", format_flat_params( log.params )
  end
    
end