require 'xcodeproj'

project_path = "ClockSpace.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath(File.join('ClockSpaceApp', 'Resources'), true)
file_reference = group.new_reference('catalog.json')

target.resources_build_phase.add_file_reference(file_reference)

project.save
