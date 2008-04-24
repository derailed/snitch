namespace :test do
  task :coverage do
    rm_f "coverage"
    rm_f "coverage.data"
    rcov = "rcov --rails --aggregate coverage.data --text-summary -Ilib -x test_rig.rb"
    system("#{rcov} --no-html test/unit/*_test.rb")
    system("#{rcov} --no-html test/functional/*_test.rb")
    system("#{rcov} --html test/integration/*_test.rb")
    system("open coverage/index.html") if PLATFORM['darwin']
  end
end   