require 'yaml'
class SCFG
	@@options = {}
	@@changed = false


	class << self

		def install
			@@options['created'] = Time.now
			@@options['changed'] = Time.now
			@@options['version'] = Seimtra::Info::VERSION
			@@options['status'] ||= 'development'
			@@options['log'] = false
			@@options['log_path'] = Dir.pwd + '/log/default'
			@@options['module_repos'] = File.expand_path('../SeimtraRepos', Dir.pwd)
			@@changed = true
		end

		def init
			if File.exist?('./Seimfile')
				@@options = YAML.load_file('./Seimfile')
			else
				false
			end
		end

	def set(key, val)
		@@options[key] = val
		@@changed = true
	end

	def get(key = nil)
		key == nil ? @@options : @@options[key]
	end

	def save
		if @@changed == true and File.exist?('./Seimfile')
			@@options['changed'] = Time.now
			File.open('./Seimfile', 'w+') do |f|
				f.write(YAML::dump(@@options))
			end
		end
	end

	end
end

