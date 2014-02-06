STRIPE = begin
  config = YAML.load(File.open(Rails.root.join('config', 'stripe.yml'))) || {}
  config = config[Rails.env] || {}
  config.to_options
end
