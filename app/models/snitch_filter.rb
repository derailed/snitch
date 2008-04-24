require 'ostruct'

class SnitchFilter      
  
  # ---------------------------------------------------------------------------
  # Build logs filter                                          
  def self.create_filter( options={} )  
    filter = OpenStruct.new             
    if options["range"].nil?
      filter.range    = 60                
    else
      filter.range = options["range"].to_i
    end
    
    if options["feature"].nil?
      filter.feature = MoleFeature.find_all_feature( options[:app_name] )
    else
      filter.feature = options["feature"].to_i
    end    
    
    if options["user"].nil?
      filter.user_id = 0
    else
      filter.user_id = options["user"].to_i
    end        
    filter
  end  
   
  # ---------------------------------------------------------------------------
  # Convenience debug                      
  def dump_filter( filter )
    RAILS_DEFAULT_LOGGER.info "\n\nU:#{filter.user_id} -- R:#{filter.range} -- F:#{filter.feature}\n\n"
  end         
end