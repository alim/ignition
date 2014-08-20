# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# Environment variables (ENV['...']) can be set in the file config/application.yml.
# See http://railsapps.github.io/rails-environment-variables.html
# puts 'ROLES'
# YAML.load(ENV['ROLES']).each do |role|
#  Role.find_or_create_by_name({ :name => role }, :without_protection => true)
#  puts 'role: ' << role
# end
puts 'DEFAULT USERS'
user = User.find_or_create_by first_name: ENV['ADMIN_FIRST_NAME'].dup,
  last_name: ENV['ADMIN_LAST_NAME'].dup, phone: ENV['ADMIN_PHONE'].dup,
	email: ENV['ADMIN_EMAIL'].dup, password: ENV['ADMIN_PASSWORD'].dup,
	password_confirmation: ENV['ADMIN_PASSWORD'].dup, role: User::SERVICE_ADMIN
puts 'user: ' << user.email
# user.add_role :admin
