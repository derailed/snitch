require 'yaml'

# -----------------------------------------------------------------------------
# This controller leverages ZiYa to plot moled features
#
# TODO update ziya plugin...
# -----------------------------------------------------------------------------
class GraphsController < ApplicationController
  include Ziya
                 
  REFRESH_RATE = 5 # 5 secs
    
  before_filter :setup     
    
  layout 'graphs_layout'
 
  # ---------------------------------------------------------------------------
  # Entry point... 
  def index              
    @features = MoleFeature.find( :all, 
                                  :conditions => [ "name != ? and app_name = ?", 
                                                   MoleFeature.all, @app_name ] )
  end     
                           
  # ---------------------------------------------------------------------------
  # Chart a given feature
  def chart_feature                 
    @feature = params[:feature]
    chart = Ziya::Charts::Column.new( @license )                       
    chart.add( :axis_category_text, @date_series )
    chart.add( :series, @feature, MoleLog.compute_series( @feature, @app_name, @min_date, @max_date ) )
    chart.add( :theme, "moles" )           
    chart.add( :user_data, :delay, rand( 10 ) + REFRESH_RATE )
    chart.add( :user_data, :url, "/graphs/update_feature?feature=#{CGI.escape(@feature)}")   
    render :xml => chart.to_xml
  end                        
  
  # ---------------------------------------------------------------------------
  # Update features. This is called via ZiYa chart callback
  def update_feature
    @feature = params[:feature]                       
    @series = MoleLog.compute_series( @feature, @app_name, @min_date, @max_date )    
    @delay  = rand( 10 ) + REFRESH_RATE  
    @title  = @feature
    @url    = "/graphs/update_feature?feature=#{CGI.escape(@feature)}"
    render :template => 'graphs/partial_refresh', :layout => false
  end     
                                                
  # ===========================================================================
  private
                                                                          
  # ---------------------------------------------------------------------------
  # General graph and date setup           
  def setup
    host        = request.env['HTTP_HOST']
    @license    = nil
    @min_date   = DateTime.now - 7
    @max_date   = DateTime.now + 1
    date_series     
    @app_name   = session[:app_name]
    true 
  end
     
  # ---------------------------------------------------------------------------
  # Formulate date series      
  def date_series
    @date_series = []
    calc_date    = @min_date
    while calc_date <= @max_date do   
     @date_series << "#{calc_date.strftime( "%m/%d")}"
     calc_date += 1
    end
  end     
end