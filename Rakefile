# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'     

USER_TPL = "class MoleUser < ActiveRecord::Base\n" +
           "  # Point to user table\n" +
           "  set_table_name  '%s'\n\n" +                       
           "  # Setup readonly access\n" +
           "  @readonly = true\n\n" +
           "  # Specify which col to use for user display purpose\n" +
           "  MOLE_USER_DISPLAY_COL = '%s'\n\n" +     
           "  # Setup display accessor\n" +
           "  def mole_display_name\n" +
           "    self.send( MOLE_USER_DISPLAY_COL )\n" +
           "  end\n" +
           "end"
 
desc 'Setup mole user to use specific table name and display col name'         
task :setup do
  questions = [ ["Enter your users table name (%s)?", :user_table_name, 'users'],
                ["Enter the column name that holds the display user name (%s)?", :display_name, 'display_name']]
                
  answers = questions.inject({}) do |answers, qv|
    question, value, default = qv            
    print "#{question % default} : "
    answers[value] = STDIN.gets.chomp 
    answers[value] = default if answers.nil? or answers[value].empty?
    answers      
  end                                            
  puts answers.inspect
  tpl = USER_TPL % [answers[:user_table_name], answers[:display_name]]
 
  user_model = "#{RAILS_ROOT}/app/models/mole_user.rb"
puts "Writing user model to #{user_model}"  
  File.delete( user_model ) if File.exists? user_model   
  open( user_model, "w" ) { |f| f << tpl }
end     

desc "Cleanup build artifacts"
task :clean do
  rcov_artifacts = File.join( File.dirname( __FILE__ ), "coverage" )
  FileUtils.rm_rf rcov_artifacts if File.exists? rcov_artifacts
  rdoc_artifacts = File.join( File.dirname( __FILE__ ), "docs" )
  FileUtils.rm_rf rdoc_artifacts if File.exists? rdoc_artifacts    
end
                                                               
