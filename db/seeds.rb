# Idempotent records required to run the application.
# Load with bin/rails db:seed, or alongside database setup via bin/rails db:setup.

User.find_or_create_by!(email_address: "demo@example.com") do |user|
  user.password = "password"
end
