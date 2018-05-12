require 'zucchini/config'

module Zucchini
  module Package
    def self.name
      return File.basename(ROOT_DIR)
    end

    def self.version
      return Config.instance['application']['package']['version']
    end

    def self.url
      return Config.instance['application']['package']['url']
    end

    def self.full_name
      return "#{name} #{version}"
    end

    def self.to_h
      return {
        name: name,
        version: version,
        url: url,
        full_name: full_name,
      }
    end
  end
end
