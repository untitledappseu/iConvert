#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'iConvert.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the target
target_name = 'iConvert Finder Extension'
target = project.targets.find { |t| t.name == target_name }

if target.nil?
  puts "Target '#{target_name}' not found"
  exit 1
end

# Find the group for the converters
finder_extension_group = project.main_group.find_subpath('iConvert Finder Extension')
converters_group = finder_extension_group.find_subpath('Converters')

if converters_group.nil?
  puts "Converters group not found"
  exit 1
end

# Add the files
files_to_add = [
  'iConvert Finder Extension/Converters/webptojpg.swift',
  'iConvert Finder Extension/Converters/webptopng.swift',
  'iConvert Finder Extension/Converters/heictowebp.swift'
]

files_to_add.each do |file_path|
  file_ref = converters_group.new_file(File.basename(file_path))
  target.add_file_references([file_ref])
  puts "Added #{file_path} to project"
end

# Save the project
project.save
puts "Project saved"