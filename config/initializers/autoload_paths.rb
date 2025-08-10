# Autoload custom app directories
Rails.application.config.autoload_paths += %W[
  #{Rails.root}/app/repositories
  #{Rails.root}/app/services
]
