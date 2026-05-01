require 'xcodeproj'
project_path = 'Qlypx.xcodeproj'
project = Xcodeproj::Project.open(project_path)

project.targets.each do |target|
  target.build_phases.delete_if do |phase|
    if phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
      script = phase.shell_script
      if script.include?('PODS_ROOT') || script.include?('SwiftLint') || script.include?('SwiftGen') || script.include?('BartyCrouch')
        puts "Removing script phase: #{phase.name || 'Unnamed'}"
        true
      else
        false
      end
    else
      false
    end
  end
end

project.save
puts "Successfully removed broken build phases!"
