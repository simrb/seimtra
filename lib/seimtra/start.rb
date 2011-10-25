
ROOTPATH = File.expand_path('../../../', __FILE__)
SCONFIGS = '/configs/Seimfile'

require 'thor'
require 'seimtra/scfg'

SCFG.init

class SeimtraThor < Thor
	def self.source_root
		ROOTPATH
	end
end

Dir[ROOTPATH + '/lib/bin/*.rb'].each do |file|
	require file
end
SeimtraThor.start
SCFG.save
