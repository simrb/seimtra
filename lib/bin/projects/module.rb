class SeimtraThor < Thor

	# = Generating view 
	#
	# Create the view for module 
	#
	# 	3s v [route_name] [view_type] [argv] [argv1]
	#
	# By default, the route_name is module name if it never be set,
	# the view_type is table
	#
	# == Arguments
	#
	# argv, 		string
	#
	# == Options
	#
	# --to, -t		put the specifying content to specifying module
	#
	# == Examples 
	#
	# create a form for adding the user data
	#
	# 	3s v edit form text:username pawd:password
	#
	# finally, display the fields by list and table
	#
	# 	3s v listuser list username:email
	#	3s v userinfo username:email

	desc "view [ROUTE_NAME] [VIEW_TYPE] [ARGV]", "Generate the view for module"
	method_option :to, :type => :string, :aliases => '-t'
	map 'v' => :view
	def view(*argv)
		doc :view unless argv.length > 0
		generate :view, argv
	end


	# = Generating route
	#
	# Create the route for module 
	#
	# == Arguments
	#
	# argv, 		string
	#
	# == Options
	#
	# --to, -t		put the specifying content to specifying module
	#
	# == Examples 
	#
	# create the routes
	#
	# 	3s route get:login:logout:register post:login:register

	method_option :to, :type => :string, :aliases => '-t'
	desc "route [ARGV]", "Generate the routes for module"
	def route(*argv)
		doc :route unless argv.length > 0
		generate :route, argv
	end


	##
	# = Operating the module
	#
	# create, remove, add, update, packup the module
	#
	#
	# == Arguments
	#
	# opt, string, a operating command
	# argv, array, the parameters
	#
	#
	# == Examples
	#
	# create the new module
	#
	# 	3s m new user
	#
	# show the list of modules
	#
	# 	3s m list
	#
	# show the info with specifying module
	#
	# 	3s m info user
	#
	# modify the module info
	#
	# 	3s m info user name:author_name

	desc "module [OPERATOR] [ARGV]", "The module operation, create, remove, add"
	map 'm' => :module
	def module(opt, *argv) 
		empty_directory(Dir.pwd + '/modules') unless File.exist?(Dir.pwd + '/modules')
		
		#create the new module
		if opt == 'new'
			error('You need a module name, e.g, 3s m new user') unless argv.length > 0
			name = argv[0]
			error('The module is existing.') if module_exist?(name)

			module_init name

			path = get_custom_info.first
			SCFG.load path, true
			info = {}
			info[:name] 		= name
			info[:created] 		= Time.now
			info[:version] 		= '0.0.1'
			info[:email] 		= SCFG.get(:email) ? SCFG.get(:email) : ask("What is the email of your ?")
			info[:author]		= SCFG.get(:author) ? SCFG.get(:author) : ask("What is your name ?")
			info[:website] 		= SCFG::OPTIONS[:website] + "/seimtra-#{name}"
			info[:description] 	= ask("The description of the module ?")

			#set module config
			SCFG.load name
			info.each do |k,v|
				SCFG.set(k,v)
			end

			SCFG.load
			SCFG.set :module_focus, name

		# list the modules
		elsif opt == 'list'
			Dir[Dir.pwd + '/modules/*'].each do | m |
				isay m.split('/').last
			end

		# show/set the module info
		elsif opt == 'info'
			name = SCFG.get :module_focus
			if argv.length > 0
				name = argv.shift if argv[0].index(':') == nil
			end
			error("The module #{name} is not existing") unless module_exist? name 
			show_info(name, argv, "#{name} module info")
		end
	end


	desc 'test [NAME]', 'Make a test, and output the result'
	method_option :with, :type => :string, :aliases => '-w'
	method_option :focus, :type => :boolean, :aliases => '-f'
	map 't' => :test
	def test(func_name = nil, *argv)
		error("Enter your test name likes this, 3s test db") if func_name == nil
		require "seimtra/stest"
		Dir[ROOTPATH + "/test/*"].each do | file |
			require file
		end
		t = Stest.new
		error "The #{func_name} method is not existing." unless t.respond_to?(func_name)

		if argv.empty?
			t.send(func_name)
		else
			t.send(func_name, argv)
		end
	end

end
