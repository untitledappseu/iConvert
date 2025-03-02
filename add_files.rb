#!/usr/bin/env ruby

require 'xcodeproj'

# Open the Xcode project
project_path = 'iConvert.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the target
target_name = 'iConvert Finder Extension'
target = project.targets.find { |t| t.name == target_name }

if target.nil?
  puts "Target '#{target_name}' not found"
  exit 1
end

# Find the Converters group
finder_extension_group = project.main_group.find_subpath('iConvert Finder Extension')
converters_group = finder_extension_group.find_subpath('Converters')

if converters_group.nil?
  puts "Converters group not found"
  exit 1
end

# List of files to add
files_to_add = [
  'iConvert Finder Extension/Converters/webptojpg.swift',
  'iConvert Finder Extension/Converters/webptopng.swift',
  'iConvert Finder Extension/Converters/heictowebp.swift',
  'iConvert Finder Extension/Converters/mp4tomov.swift',
  'iConvert Finder Extension/Converters/mp4togif.swift',
  'iConvert Finder Extension/Converters/movtomp4.swift',
  'iConvert Finder Extension/Converters/avitomp4.swift',
  'iConvert Finder Extension/Converters/mp4towebm.swift',
  'iConvert Finder Extension/Converters/pngtoheic.swift',
  'iConvert Finder Extension/Converters/jpgtoheic.swift',
  'iConvert Finder Extension/Converters/mp3towav.swift',
  'iConvert Finder Extension/Converters/wavtomp3.swift',
  'iConvert Finder Extension/Converters/m4atomp3.swift',
  'iConvert Finder Extension/Converters/mp3tom4a.swift',
  'iConvert Finder Extension/Converters/wavtoflac.swift',
  'iConvert Finder Extension/Converters/flactowav.swift'
]

# Add each file to the project
files_to_add.each do |file_path|
  file_ref = converters_group.new_file(File.basename(file_path))
  target.add_file_references([file_ref])
  puts "Added #{file_path} to project"
end

# Save the project
project.save
puts "Project saved"