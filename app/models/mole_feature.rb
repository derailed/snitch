require 'mole/models/mole_feature'
                                        
# Feature model - Tracks the various application features in the db.
class MoleFeature < ActiveRecord::Base
  # Setup readonly access
  @readonly = true       

  # has_many :mole_logs    
  #       
  # class << self     
  #   # famous constants...  
  #   def all()         "ALL"        ; end
  #   def exception()   "Exception"  ; end
  #   def performance() "Performance"; end  
  #       
  #   def default_app_name
  #     "Default"
  #   end
  #                                
  #   # find performance feature
  #   def find_performance_feature( app_name )
  #     find_or_create_feature( performance, app_name )
  #   end
  #                                
  #   # find exception feature
  #   def find_exception_feature( app_name )
  #     find_or_create_feature( exception, app_name )
  #   end
  #   
  #   def find_all_feature( app_name )
  #     find_or_create_feature( all, app_name )
  #   end
  #                   
  #   # Finds all the features available for a given application
  #   # Creates the all feature if necessary    
  #   def find_all_the_features( app_name ) 
  #     find_all_feature( app_name )
  #     MoleFeature.find( :all, 
  #                       :conditions => ["app_name = ?", app_name], 
  #                       :select     => "id, name, context", 
  #                       :order      => "name asc" )      
  #   end
  #     
  #   # locates an existing feature or create a new one if it does not exists
  #   def find_or_create_feature( name, app_name, ctx_name=nil )
  #     if name.nil? or name.empty? 
  #       ::Mole.logger.error( "--- MOLE ERROR - Invalid feature. Empty or nil" ) 
  #       return nil
  #     end                                
  #     find_by_name_and_context_and_app_name( name, ctx_name, app_name ) ||     
  #     create(:name => name,:context => ctx_name, :app_name => app_name )
  #   end       
  # end
end               
