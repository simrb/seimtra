class SeimtraThor < Thor

	# = Database operation 
	#
	# Create and implement the migration to database,
	# output/dump the schema/migration from database
	#
	# == Arguments
	#
	# operator, 	string, e.g. , create, alter, rename, drop
	# argv, 		array, e.g. , ["table_name", "String:name","String:password"]
	#
	# == Options
	#
	# --autocomplete, -a completing the fileds with primary_key, and timestamp, automatically
	# --run, -r		run the migrations
	# --to, -t		specify a module for implementing the migrating action
	# --version, -v	specify a version for migrating record
	# --dump, -d	dump the database schema to a migration file
	# --output, -o	output the schema of database
	# --details 	output with the details
	# --schema		implement a global database schema
	#
	# == Examples
	#
	# dropdown/rename the table
	#
	#	3s db drop :table1,:table2,:table3
	#	3s db rename :old_table,:new_table
	#
	# create/alter the table,
	#
	#	3s db create table_name primary_key:uid String:name String:pawd
	#
	#	3s db alter table_name drop_column:column_name
	#	3s db alter table_name rename_column:old_column_name,:new_column_name
	#
	# create and auto complete the fileds, primary id, created time,  
	# then run the migration records
	#
	# 	3s db create table_name String:title text:body -a -r
	#
	# dump the current db schema to a migration file (the default path as db/migrations)
	#
	#	3s db --dump=D
	#
	# implement a db schema using the default file at db/migrations
	#
	#	3s db -r --schema
	#
	# output the schema of current database
	#
	#	3s db -o
	#	3s db -o --details

	method_option :autocomplete, :type => :boolean, :aliases => '-a'
	method_option :run, :type => :boolean, :aliases => '-r' 
	method_option :to, :type => :string, :aliases => '-t' 
	method_option :version, :type => :numeric, :aliases => '-v' 
	method_option :dump, :type => :string
	method_option :output, :type => :boolean, :aliases => '-o'
	method_option :details, :type => :boolean
	method_option :schema, :type => :boolean
	desc "db [OPERATOR] [ARGV]", "Create/Run the migrations, and output schema/migration of database"
	def db(operator = nil, *argv)

		#initialize data
		db 				= Db.new
		error(db.msg) if db.error

		module_current	= options[:to] == nil ? SCFG.get(:module_focus) : options[:to]
		path 			= "/modules/#{module_current}/migrations"
		mpath 			= Dir.pwd + path
		gpath 			= Dir.pwd + "/db/migrations"
		doperator		= [:create, :alter, :drop, :rename]
		dbcont 			= "'#{settings.db_connect}'"
		version			= options[:version] == nil ? '' : "-M #{options[:version]}"

		empty_directory(gpath) unless File.exist?(gpath)
		empty_directory(mpath) unless File.directory?(mpath)

		#create a migration record
 		if operator != nil and argv.count > 0

			unless doperator.include? operator.to_sym
				error("The #{operator} is a error operator, you allow to use create, \
				alter, rename and drop as the operator")
			end

			if [:create, :alter].include? operator.to_sym
				table = argv.shift
			else
				table = ''
			end

			file = mpath + "/#{Time.now.strftime("%Y%m%d%H%M%S")}_#{operator}_#{table}.rb"

			#auto add the primary_key and time to migrating record
			if options.autocomplete?
				error db.msg if db.error
				argv = db.autocomplete(table, argv) if operator == 'create'
			end
	
			create_file file do
				content = "Sequel.migration do\n"
				content << "\tchange do\n"

				if operator == "drop" or operator == "rename"
					content << "\t\t#{operator}_table(#{argv.to_s.gsub(",", ", ")})\n"
				else
					content << "\t\t#{operator}_table(:#{table}) do\n"
					argv.each do |item|
						content << "\t\t\t#{item.sub(":", " :").gsub(",", ", ")}\n"
					end
					content << "\t\tend\n"
				end

				content << "\tend\n"
				content << "end\n"
			end
		end

		#implement the migrations
		if options.run? 
			path = mpath
			path = Dir[gpath + "/*"].sort.last if options.schema?

			error("No schema at #{path}") unless File.exist?(path)
			run("sequel -m #{path} #{version} #{dbcont}")
			isay "Implementing complete"
		end

		#dump the database schema to a mrgration file
		if options[:dump] != nil
			dump = options[:dump] == 'D' ? '-D' : '-d'
			run("sequel #{dump} #{dbcont} > #{gpath}/#{Time.now.strftime('%Y%m%d%H%M%S')}.rb")
		end

		#output the schema/migration
		if options.output?
			isay "The adapter is :  #{db.get_scheme}."
			isay "The schema as the following."
			puts "\n"

			#puts the tables of database to array of hash
			if options.details?
				print db.dump_schema_migration
			else
				db.get_tables.each do |table|
					print table.to_s.ljust(20, ' ')
					print db.get_columns(table)
					print "\n"
				end
			end
			puts "\n"
		end

	end

end
