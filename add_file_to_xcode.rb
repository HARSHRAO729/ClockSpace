require 'xcodeproj'

project_path = '/Users/harshrao/ClockSpace/ClockSpace.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the target (assuming it's the main app target)
target = project.targets.first

# Check if the file is already in the project
file_path = 'ClockSpaceApp/Resources/catalog.json'

# Find or create the Resources group
main_group = project.main_group
group = main_group.find_subpath('ClockSpaceApp/Resources', true)
group.set_source_tree('<group>')
group.set_path('ClockSpaceApp/Resources')

# Check if file reference already exists
file_ref = group.files.find { |f| f.path == 'catalog.json' || f.path.end_with?('catalog.json') }
if file_ref.nil?
  puts "Adding file reference for catalog.json"
  file_ref = group.new_file('catalog.json')
end

# Check if it's already in the Resources build phase
resources_build_phase = target.resources_build_phase
build_file = resources_build_phase.files.find { |f| f.file_ref == file_ref }

if build_file.nil?
  puts "Adding catalog.json to resources build phase"
  resources_build_phase.add_file_reference(file_ref)
  project.save
  puts "Successfully added and saved project!"
else
  puts "catalog.json is already in the resources build phase."
end
