class Db

	attr_accessor :msg, :error

	def initialize(path = './environment.rb')
		@msg 	= ''
		@error 	= false
		epath = File.expand_path(path)
		if File.exist?(epath)
			require epath
		else
			@error 	= true
			@msg	= 'No such the file ' + epath
		end
	end
	
	#@name symbol
	def check_column(name)
		columns = get_columns
		columns.include?(name) ? true : false
	end

	#@name string, the table name
	#@argv array, such as ['String:title', 'text:body']
	def autocomplete(name, argv)
		#match a id
		i = 1
		while i > 0 do
			id = ''
			i.times do |j| id += name[j] end
			i = check_column(id.to_sym) ? (i + 1) : 0
		end
		id += 'id'
		argv.unshift("primary_key:#{id}")

		#match time field
		argv << 'Time:created'
		argv << 'Time:changed'
		argv
	end

	def get_tables
		DB.tables
	end

	def get_scheme
		DB.class.adapter_scheme.to_s
	end

	def get_schema(table)
		DB.schema(table)
	end

	def get_columns(table = nil)
		if table == nil
			argv = []
			get_tables.each do | table |
				argv << DB[table.to_sym].columns!
			end
			argv
		else
			DB[table.to_sym].columns!
		end
	end
end
