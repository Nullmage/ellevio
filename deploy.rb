class Runner
	def execute
		@dependencies = dependencies
		@changed_projects = changed_projects
		@ignored_projects = ignored_projects

		puts (projects_to_deploy(@changed_projects) - @ignored_projects).sort_by { |e| TOPOLOGICAL_ORDER.index(e) || Float::INFINITY }
	end

	private

	TOPOLOGICAL_ORDER = [
		"network",
		"vmimages",
		"databricks",
		"datalake",
		"vaults",
		"registry",
		"gov-idc",
		"unity-catalog",
		"logging",
		"aks",
		"devops",
		"aks-deployments",
		"auth-aks",
		"auth-ingest",
		"gov-dadc",
		"auth-devops"
	]

	def projects_to_deploy(changed_projects)
		projects_to_deploy = []

		changed_projects.each do |project|
			projects_to_deploy << project
			projects_to_deploy.concat(dependencies[project] || [])
		end

		projects_to_deploy
	end

	def changed_projects
		ARGV.map { |e| File.dirname(e).split("/").first }.select { |e| e != "." }
	end

	def dependencies
		File.read("dependencies")
		.split(";") # Each entry is separated by a ";"
		.map { |e| child, parent = e.split(" -> "); [child.tr('"', ''), parent.tr('"', '')] } # Remove excess quotation marks
		.reduce({}) do |deps, entry| # Build dependency graph
			child, parent = entry
			deps[parent] = deps[parent]&.push(child) || [child]
			deps
		end
	end

	def ignored_projects
		File.read(".deployignore").split("\n")
	end

end

runner = Runner.new
runner.execute
