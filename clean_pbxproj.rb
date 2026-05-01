require 'xcodeproj'
project_path = 'Qlypx.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Update deployment target
project.build_configurations.each do |config|
  config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '13.0'
  if config.base_configuration_reference && config.base_configuration_reference.path.include?('Pods')
    config.base_configuration_reference = nil
  end
end

project.targets.each do |target|
  target.build_configurations.each do |config|
    config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '13.0'
    if config.base_configuration_reference && config.base_configuration_reference.path.include?('Pods')
      config.base_configuration_reference = nil
    end
  end

  # Remove CocoaPods Build Phases
  target.build_phases.delete_if do |phase|
    phase.respond_to?(:name) && phase.name && phase.name.include?('[CP]')
  end

  # Remove Pods frameworks from Frameworks Build Phase
  frameworks_phase = target.frameworks_build_phase
  if frameworks_phase
    frameworks_phase.files.delete_if do |build_file|
      build_file.file_ref && build_file.file_ref.path && build_file.file_ref.path.include?('Pods_')
    end
  end
end

# Remove Pods group if it exists
pods_group = project.main_group.children.find { |group| group.name == 'Pods' || group.path == 'Pods' }
if pods_group
  pods_group.children.each do |child|
    child.remove_from_project
  end
  pods_group.remove_from_project
end

# Remove any other Pods references
project.files.each do |file|
  if file.path && file.path.include?('Pods_')
    file.remove_from_project
  end
end

project.save
puts "Successfully cleaned project.pbxproj with xcodeproj gem!"
