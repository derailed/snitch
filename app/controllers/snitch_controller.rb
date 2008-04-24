require 'ostruct' 
require 'mole_user'    
require 'mole_feature'
require 'mole_log'

class SnitchController < ActionController::Base       
  layout 'mole_layout'                            
                                                             
  # Setup filters and such                                                  
  before_filter :setup
  
  # Setup widget callbacl
  before_filter :widget_setup, :only => [ :events_xml, :top_features_xml, :top_users_xml]
         
  # ---------------------------------------------------------------------------  
  # Point of entry...
  def index    
    session[:last_pull]  = @filter.range.minutes.ago.utc        
    find_logs( session[:last_pull] )                   
    session[:start_pull] = session[:last_pull]    
    session[:counts]     = @logs.size  
  end       
     
  # ---------------------------------------------------------------------------
  # Filter logs - callback from filter form  
  def filter                                                               
    filters            = params[:filter]
    filters[:app_name] = @app_name
    @filter = SnitchFilter.create_filter( filters )   
    filter_logs( @filter.range.minutes.ago.utc )           
    session[:counts] = @logs.size
    
    render :update do |page|                                                                       
      page.call 'refresh_off'
      page.replace_html( 'filter_panel', :partial => 'filter_form' )
      page.replace_html( 'top_panel', :partial => 'tops' )
      unless @logs.empty?     
        page.hide( 'no_result' )
        page.replace_html( 'counts', :partial => 'counts' )
        page.show( 'counts' )
        page.replace_html( 'logs', :partial => 'log', :collection => @logs ) 
      else
        page.hide( 'counts' )
        page.replace_html( 'logs', :partial => 'no_results' ) 
      end
    end  
  end
  
  # ---------------------------------------------------------------------------
  # Call from periodical refresh          
  def refresh   
    timestamp = session[:last_pull]
    timestamp = @filter.range.minutes.ago.utc if timestamp.nil?
               
    find_logs( timestamp )  

    # Update counts...    
    if session[:counts].nil?
      session[:counts] = @logs.size        
    else
      session[:counts] += @logs.size        
    end
    
    render :update do |page|                                        
      page.replace_html( 'top_panel', :partial => 'tops' )
      page.replace_html( 'counts', :partial => 'counts' )      
      unless @logs.empty?
        page.show( 'counts' )
        page.insert_html( :top, 'logs', :partial => 'log', :collection => @logs ) 
        @logs.each do |l| 
          page["log_#{l.id}"].visual_effect( :highlight, 
                                             :duration   => 3, 
                                             :startcolor => "#89E21B", 
                                             :endcolor   => "#{log_color @logs.first}" )
        end   
      end      
    end
  end
        
  # ---------------------------------------------------------------------------
  # Widget event callback. Spit out xml to feed the widget 
  def events_xml  
    if ( session[:last_pull].nil? )
      find_latest_logs( @limit )
    else 
      session[:last_pull] = @filter.range.minutes.ago.utc if session[:last_pull].nil?        
      find_logs( @app_name, session[:last_pull], @limit )                                        
      session[:start_pull] = session[:last_pull]    
    end
    render :layout => false  
  end
           
  # ---------------------------------------------------------------------------
  # Widget top features callback. Spit out xml to feed the widget 
  def top_features_xml  
    @tops       = MoleLog.find_top_features( @filter, @app_name, @timestamp, @limit )       
    @live_users = MoleLog.find_live_users( @filter, @app_name, @timestamp )
    render :layout => false  
  end    
  
  # ---------------------------------------------------------------------------
  # Widget top users callback. Spit out xml to feed the widget 
  def top_users_xml  
    @tops       = MoleLog.find_top_users( @filter, @app_name, @timestamp, @limit )       
    @live_users = MoleLog.find_live_users( @filter, @app_name, @timestamp )
    render :layout => false  
  end      
    
  # ===========================================================================
  private
                                
  # ---------------------------------------------------------------------------
  # Prepare for widget callback
  def widget_setup
    @limit    = params[:max] || 10
    ids       = params[:ids] || ""    
    @ids      = ids.split( "," )      
    counts    = params[:counts] || ""
    @counts   = counts.split( "," )  
    @app_name = params[:app_name] || MoleFeature::DEFAULT_APP_NAME
    @timestamp = Time.now
    @timestamp = Time.mktime( @timestamp.year, @timestamp.month, @timestamp.day, 0, 0, 0 )    
    @data  = {} 
    @ids.each_index { |i| @data[@ids[i]] = counts[i].to_i }    
  end
                     
  # ---------------------------------------------------------------------------
  # Setup controller  
  def setup    
    @now = Time.now                                    
    
    # Pickup app name for either url or check for Moled apps in the db
    if params[:app_name]
      @app_name = params[:app_name]
    else                                                                                 
      moled_apps = MoleFeature.find_moled_application_names
      # If more than one moled app then pick the first one by default
      # If no moled apps are found then use the "Default" application name
      unless moled_apps.empty?
        moled_app = moled_apps.first
      else    
        moled_app = "Default"
      end
      @app_name = session[:app_name] ? session[:app_name] : moled_app
    end
    session[:app_name] = @app_name
    
    # Builds form filter
    @filter = session[:filter]
    @filter = SnitchFilter.create_filter( :app_name => @app_name ) if @filter.nil?
    
    # Build feature list
    features  = MoleFeature.find_features( @app_name )
    @features = features.map { |f| [ feature_name( f.name, f.context ), f.id] } 
    @features.sort! { |a,b| a <=> b }
    
    # Build user list
    users = MoleUser.find( :all, 
                           :select => "id,#{MoleUser::MOLE_USER_DISPLAY_COL}", 
                           :order  => "#{MoleUser::MOLE_USER_DISPLAY_COL} asc" )
    @users = users.map { |u| [u.mole_display_name, u.id] }                  
  end                                     
     
  # ---------------------------------------------------------------------------
  # Compose viewable feature name      
  def feature_name( name, context )                                 
    return name if context.nil? or context.empty?
    "#{context.gsub( /Controller/, '')}/#{name}".downcase
  end                            
  
  # ---------------------------------------------------------------------------
  def find_latest_logs( limit=10 )
    @logs               = MoleLog.find_latest_logs( @app_name, limit )                                     
    session[:last_pull] = @logs.first.created_at unless @logs.empty?      
    session[:last_pull] = @timestamp if @logs.empty?                  
    timerange           = @filter.range.minutes.ago( session[:last_pull] )
    @live_users         = MoleLog.find_live_users( @filter, @app_name, timerange )       
  end  
                                                                         
  # ---------------------------------------------------------------------------
  # Fetch mole events for given time range
  def find_logs( timestamp, limit=500 )    
    session[:filter]     = @filter 
    @logs                = MoleLog.find_logs( @filter, @app_name, timestamp, limit ) 
    unless @logs.empty?               
logger.info "---- Setting time stamp to first one #{@logs.first.created_at.utc}"      
      session[:last_pull]  = @logs.first.created_at
    else                                                                              
logger.info "---- Setting time stamp to current #{timestamp}"            
      session[:last_pull]  = timestamp
    end
    session[:start_pull] = session[:last_pull] if session[:start_pull].nil?                 
    timerange            = @filter.range.minutes.ago( session[:start_pull] )
    find_tops( timerange )
  end     
  
  # ---------------------------------------------------------------------------
  # Filter mole events for given time range
  def filter_logs( timestamp )    
    session[:filter]    = @filter 
    @logs               = MoleLog.find_logs( @filter, @app_name, timestamp )
    session[:last_pull] = @logs.first.created_at unless @logs.empty?
    session[:last_pull] = timestamp if @logs.empty?
    find_tops( timestamp )
  end    
  
  # ---------------------------------------------------------------------------
  # Fetch top stats
  def find_tops( timestamp ) 
    @top_users    = MoleLog.find_top_users( @filter, @app_name, timestamp )
    @top_features = MoleLog.find_top_features( @filter, @app_name, timestamp )
logger.info "!!!! TOP FEATURES #{@top_features.size}"      
@top_features.each { |f| logger.info f.inspect }

    @live_users   = MoleLog.find_live_users( @filter, @app_name, timestamp )
  end
    
end