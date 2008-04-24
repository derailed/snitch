module SnitchHelper                      
  # Time ranges
  TIME_RANGE = [ ['Last Half Hour', 30], 
                 ['Last Hour'     , 60], 
                 ['Last 2 Hours'  , 2*60],
                 ['Last 4 Hours'  , 4*60],
                 ['Last 6 Hours'  , 6*60],
                 ['Last 12 Hours' , 12*60], 
                 ['Last Day'      , 24*60], 
                 ['Last 2 Days'   , 2*24*60],
                 ['Last 3 Days'   , 3*24*60],
                 ['Last 4 Days'   , 4*24*60], 
                 ['Last Week'     , 5*24*60 ] ]     
                       
  # ---------------------------------------------------------------------------
  # Fetch mole log parameters to display in console
  def format_params( params )  
    buff   = []
    values = YAML.load( params ) 
    return values if values.is_a? String   
    values.keys.sort { |a,b| a.to_s <=> b.to_s }.each { |k| buff << "<span>#{k}: #{values[k]}</span>" }
    buff.join( " " )
  end  
                               
  # ----------------------------------------------------------------------------
  # Fetch mole log parameters to diplay in widget
  def format_flat_params( params )  
    buff   = []
    values = YAML.load( params ) 
    return values if values.is_a? String   
    values.keys.sort { |a,b| a.to_s <=> b.to_s }.each { |k| buff << "#{k}: #{values[k]}" }
    buff.join( "\r" )
  end              
         
  # ---------------------------------------------------------------------------
  # Toggle list or expanded view
  def toggle_details               
    criteria = session[:toggle_details] ? "Expanded" : "List"
    link_to_function( "#{criteria} view", "toggle_details()", :id => 'toggle_details' )
	end
	                                                   
  # ---------------------------------------------------------------------------
  # Colorizes moled features on the console
  def log_color( log )
    color = case log.mole_feature.name
      when MoleFeature.performance : "056251"
      when MoleFeature.exception   : "993366"
      else "4c4d4d"
    end     
    "##{color}"
  end   
           
  # ---------------------------------------------------------------------------
  # Fetch browser image 
  def browser_img( log )
    img_name = log.browser_kind
    img_name = "unknown_browser" if img_name.nil?
    image_tag "#{img_name.to_s.downcase.gsub( /\\/, '')}.png", :class => "image_tag"     
  end   
                                                       
  # ---------------------------------------------------------------------------
  # Tags mole log with an image
  def tag_img( log )  
    img = case log.mole_feature.name
      when MoleFeature.performance : "clock"
      when MoleFeature.exception   : "bomb"
      else "item"
    end  
    image_tag "#{img}.gif", :class => "image_tag" 
  end     

  # ---------------------------------------------------------------------------
  # Format user column     
  def format_user( user ) 
    user.nil? ? "N/A" : truncate( user.mole_display_name, 25 )    
  end

  # ---------------------------------------------------------------------------
  # Format feature column        
  def format_feature_name( name )
    return "N/A" if name.nil?    
    name.gsub( /Controller/, '')
  end             
  
  # ---------------------------------------------------------------------------
  # Formats console timestamp
  def format_time( time, now )                    
    return time.strftime( "%H:%M:%S" ) if time.yday == now.yday
    time.strftime( "%m/%d %H:%M:%S" )
  end
end