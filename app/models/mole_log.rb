require 'mole/models/mole_log'

class MoleLog < ActiveRecord::Base
  belongs_to :mole_user, :foreign_key => 'user_id', :class_name => 'MoleUser'
  
  # belongs_to :mole_feature 

  BROWSER_TYPES = [ 'Firefox', 'Safari', 'MSIE 7\.0', 'MSIE 6\.0', 'Opera' ]
    
  # Setup readonly access
  @readonly = true       
                     
  # Top items limit        
  TOP = 50         
  
  # Limit logs to the last 100
  MAX_LOGS = 100        

  # ---------------------------------------------------------------------------
  # Determine browser type  
  def browser_kind
    BROWSER_TYPES.each do |b|
      return b unless Regexp.new( ".*?#{b}.*?" ).match( self.browser_type ).nil?
    end
    nil
  end    
       
  class << self                                    
    # ---------------------------------------------------------------------------
    # Fetch mole logs for a given time range and given feature
    def compute_series( feature, app_name, min_date, max_date )
      feature = MoleFeature.find_by_name_and_app_name( feature, app_name )
      return [0] if feature.nil?
      cltn = find( :all, 
        :select     => "DATE_FORMAT( created_at, '%m/%d') as date, count( user_id ) as count",
        :conditions => [ "mole_feature_id = ? and created_at > ?", feature.id, min_date], 
        :group      => "DATE_FORMAT( created_at, '%Y-%m-%d')"  ) || []    
      
      series    = []
      calc_date = min_date
      while calc_date <= max_date do   
        series << find_per_date( calc_date.strftime( "%m/%d"), cltn )
        calc_date += 1
      end
      series      
    end                      
  
    # ---------------------------------------------------------------------------
    # Find the lastest x logs                              
    def find_latest_logs( app_name, limit )
      find( :all,    
            :conditions => ['mole_features.app_name = ?', app_name],
            :include    => [:mole_feature,:mole_user],
            :order      => 'mole_logs.created_at desc',
            :limit      => limit )      
    end       
    
    # ---------------------------------------------------------------------------
    # Fetch mole logs for given time range and filter                                         
    def find_logs( filter, app_name, timestamp, limit=MAX_LOGS )
      conds = prepare_logs_cond( filter, app_name, timestamp )                
      find( :all, 
        :conditions => conds,
        :include    => [:mole_feature,:mole_user],
        :order      => 'mole_logs.created_at desc', 
        :limit      => limit )               
    end       
    
    # ---------------------------------------------------------------------------
    # Fetch top users
    def find_top_users( filter, app_name, timestamp, limit=TOP )                                                        
      conds = prepare_cond( filter, app_name, timestamp )               
      find( :all,                          
        :conditions => conds,
        :select     => "user_id, count(user_id) as count, #{MoleUser.table_name}.#{MoleUser::MOLE_USER_DISPLAY_COL} as name",
        :include    => [:mole_user, :mole_feature],
        :group      => "#{MoleUser.table_name}.id", 
        :order      => 'count desc',
        :limit      => limit )                                   
    end   
  
    # ---------------------------------------------------------------------------
    # Fetch live users
    def find_live_users( filter, app_name, timestamp ) 
      conds = prepare_cond( filter, app_name, timestamp )      
      find( :all,                          
        :conditions => conds,
        :select     => "distinct(#{MoleUser.table_name}.#{MoleUser::MOLE_USER_DISPLAY_COL}) as name",
        :include    => [:mole_user, :mole_feature],
        :group      => "#{MoleUser.table_name}.id", 
        :order      => 'name asc' )
    end      
                 
    # ---------------------------------------------------------------------------
    # Fetch top features
    def find_top_features( filter, app_name, timestamp, limit=TOP )  
      conds = prepare_cond( filter, app_name, timestamp, "f" )
      find( :all,                          
        :conditions => conds,
        :select     => "mole_feature_id, count(mole_feature_id) as count, f.name as name, f.context as context",
        # :include    => [:mole_feature],
        :joins      => "join mole_features f on f.id = mole_feature_id",
        :group      => 'mole_feature_id', 
        :order      => 'count desc',
        :limit      => limit )                         
    end     
                 
    # ===========================================================================
    private
      
    # ---------------------------------------------------------------------------
    # Prepare condition
    def prepare_cond( filter, app_name, timestamp, table_alias="mole_features" )      
      conds       = nil
      all_feature = MoleFeature.find_all_feature( app_name )   
      if ( all_feature.nil? or filter.feature == all_feature.id )        
        conds = ["mole_logs.created_at > ? and #{table_alias}.app_name = ?", timestamp, app_name] 
      else
        conds = ["mole_logs.created_at > ? and mole_feature_id = ? and #{table_alias}.app_name = ?", 
                 timestamp, filter.feature, app_name]
      end
      
      if filter.user_id != 0           
        conds[0] << " and user_id = ?"
        conds << filter.user_id
      end             
      conds
    end             
   
    # ---------------------------------------------------------------------------
    # Prepare condition    
    def prepare_logs_cond( filter, app_name, timestamp )
      date_cond   = "mole_logs.created_at > ? and mole_features.app_name = ?"
      conds       = [date_cond, timestamp, app_name]                               
    
      if filter.feature != MoleFeature.find_all_feature( app_name ).id
        conds = ["#{date_cond} and mole_feature_id = ? ", timestamp, app_name, filter.feature]
      end          
      if filter.user_id != 0           
        conds[0] << " and user_id = ?"
        conds << filter.user_id
      end 
      conds      
    end  
  
    # ---------------------------------------------------------------------------
    # Find indexes per date
    def find_per_date( date, cltn )      
      count = 0      
      cltn.each do |a|         
        return a.count if a[:date] == date
      end
      count
   end        
 end
end