require 'rake'
require 'rake/testtask'

task :default => [:test]

desc "Run tests"
Rake::TestTask.new("test") { |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.pattern = FileList['test/*.rb']
}

desc "Add initial users from a YAML file"
task :add_initial_users do
  require 'yaml'
  require './lib/load_path.rb'
  require './lib/init.rb'

  initial_users = YAML::load(File.open('config/initial_users.yaml'))

  initial_users.each do |user_data|
    user = User.first_or_create :name => user_data[:username]
    user.password = user_data[:password]
    user.save!
    puts "Created: #{user.name}"
  end
end

desc "Create some dummy tags"
task :add_tags do
  $: << File.join(File.dirname(__FILE__), 'lib')
  require 'init.rb'

  puts "Generate 20 tags for which user?"
  name = STDIN.gets.chomp

  user = User.first :name => name
  device = Device.first_or_create(:name => "Test Radio", :user_id => user.id)
  user.save
  device.tags.all.destroy

  20.times do |t|
    tag_time = Time.now.utc.to_i - rand(604800)
    tag_station = ['0.c22a.ce15.ce1.dab',
                   '0.c236.ce15.ce1.dab',
                   '0.c221.ce15.ce1.dab',
                   '0.c222.ce15.ce1.dab',
                   '0.c223.ce15.ce1.dab',
                   '0.c224.ce15.ce1.dab',
                   '0.c22c.ce15.ce1.dab',
                   '0.c225.ce15.ce1.dab',
                   '0.c228.ce15.ce1.dab',
                   '0.c22b.ce15.ce1.dab',
                   '0.c238.ce15.ce1.dab'].sort_by{ rand }.first

    tag = Tag.create :station => tag_station, :time => tag_time
    device.tags << tag
  end
  device.save
end
