class SeimtraThor < Thor
	
	desc "new [NAME]", "Create a new module"
	def new name
		error('The module is existing.') if module_exist?(name)
		module_init name

		info 				= {}
		path 				= get_custom_info.first
		res 				= SCFG.load :path => path, :return => true

		info[:name] 		= name
		info[:email] 		= res.include?('email') ? res['email'] : ask("What is the email of your ?")
		info[:author]		= res.include?('author') ? res['author'] : ask("What is your name ?")
		info[:description] 	= ask("The description of the module ?")

		File.open(Dir.pwd + "/modules/#{name}/" + Sbase::Files[:readme], "w+") do | f |
			f.write("## INTRODUCTION\n\n#{info[:description]}")
		end
			
		SCFG.load :path => 'Seimfile'
		SCFG.set 'module_focus', name

		SCFG.load :name => name, :init => true
		info.each do | key, val |
			SCFG.set key, val
		end
	end

	desc 'list', 'List all of the module folders'
	def list
		str = "module list"
		res = {}
		Dir[Dir.pwd + '/modules/*/' + Sbase::Files[:info]].each do | info |
			result = SCFG.load :path => info, :return => true
			if result.include?('name') and result.include?('description')
 				res[result['name']] = "#{result['description']} (#{result['open']})"
			end
		end
		show_info res, str
	end

	desc 'add [NAME]', 'Add a module'
	method_option :remote, :type => :boolean, :aliases => '-r'
	method_option :path, :type => :string
	method_option :bundle, :type => :boolean
	def add *module_names
		error "Please enter the module name you want to install" unless module_names.length > 0
		
		#check the module installation file whether existing
		module_names.each do | name |
			if options.remote?
				#get the module installation packet from remote repository
			end
			path = Dir.pwd + "/modules/#{name}"
			path = options[:path] if options[:path] != nil
			error "No module found at path #{path}" unless module_exist? path, true
		end

		#run the db migration
		module_names.each do | name |
			run "3s db -r --to=#{name}"
		end

		db = Db.new

		#get the modules that had been installed yet
		exist_modules = []
		if db.select(:modules).exists
			db.select(:modules).select(:mid, :module_name).each do | row |
				exist_modules << row[:module_name] unless exist_modules.include? row[:module_name] and row[:module_name] != nil
			end
		end

		#compare the exist_modules and install_modules,
		#delete the existing module if you don't want to install again
		install_modules = []
		module_names.each do | name |
			if exist_modules.empty? or exist_modules.include?(name) == false
				install_modules << name
			else
				isay "The '#{name}' module has been installed."
			end
		end

		#quit if no module to install
		exit if install_modules.empty?

		#mark down the installed module into the database
		install_modules.each do | name |
			path = Dir.pwd + "/modules/#{name}/" + Sbase::Files[:info]
			result = SCFG.load :path => path , :return => true
			unless result.empty?
				module_info_item = Sbase::Module_info.keys
				options = {}
				result.each do | item |
					key, val = item
					options[key.to_sym] = val if module_info_item.include? key.to_sym
				end
				db.insert :modules, options
			end
		end


		#flash the module info with database record
		db_modules = db.select :modules

		#scan various file to database
		install_modules.each do | name |
			mid = db_modules[:module_name => name][:mid]

			#setting file
			path = Dir.pwd + "/modules/#{name}/" + Sbase::Files_install[:setting]
			result = SCFG.load :path => path , :return => true
			unless result.empty?
				result.each do | item |
					key, val = item
					db.insert :setting, :skey => key, :sval => val, :mid => mid, :changed => Time.now
				end
			end

			#block file
			path = Dir.pwd + "/modules/#{name}/"+ Sbase::Files_install[:block]
			result = SCFG.load :path => path , :return => true, :type => :list
 			unless result.empty?
				table_fields = db.select(:block).columns!

				result2 = []
				if result.class.to_s == "Hash"
					result2 << result
				else
					result2 = result
				end

				result2.each do | line |
					options = {}
					line.each do | item |
						key, val = item	
						options[key.to_sym] = val if table_fields.include? key.to_sym
					end
					options[:mid] = mid

					default_num_id = 0
					Sbase::Block.keys.each do | item |
						if options.include? item
							index_id = Sbase::Block[item].index(options[item])
							options[item] = index_id == nil ? default_num_id : index_id
						else
							options[item] = default_num_id
						end
					end
 					db.insert :block, options
				end

			end

			#panel files
			path			= Dir.pwd + "/modules/#{name}/" + Sbase::Files_install[:panel]
			result 			= SCFG.load :path => path , :return => true, :type => :list

 			unless result.empty?
				table_fields = db.select(:panel).columns!

				result2 = []
				if result.class.to_s == "Hash"
					result2 << result
				else
					result2 = result
				end

				result2.each do | line |
					options = {}
					line.each do | item |
						key, val = item	
						options[key.to_sym] = val if table_fields.include? key.to_sym
					end
					options[:mid] = mid unless options.include? :mid
 					db.insert :panel, options
				end
			end

			#bundle install each Gemfile
			if options.bundle?
				path = Dir.pwd + "/modules/#{name}/Gemfile"
				run "bundle install --gemfile=#{path}" if File.exist? path
			end

		end

	end

end
