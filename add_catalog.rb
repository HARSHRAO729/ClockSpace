require 'xcodeproj'

project_path = 'ClockSpace.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'ClockSpace' }

file_path = 'ClockSpaceApp/Resources/catalog.json'

# Add the file to the project group hierarchy
resources_group = project.main_group.find_subpath(File.dirname(file_path), true)
resources_group.set_source_tree('SOURCE_ROOT')
file_ref = resources_group.new_file(File.basename(file_path))

# Add the file reference to the target's resources build phase
target.resources_build_phase.add_file_reference(file_ref)

project.save
puts "Added #{file_path} to ClockSpace target resources"
