require 'xcodeproj'

class ProjectHelper


  def initialize(xcodeproj_glob)
    projects = Dir.glob(xcodeproj_glob)
    @project = Xcodeproj::Project.open(projects.first)
  end

  def reset_project_to_defaults
    @project.build_configurations.each do |configuration|
      build_settings = configuration.build_settings
      build_settings.each { |k, _| build_settings.delete(k) }
    end
  end

  def reset_targets_to_defaults
    @project.targets.each do |target|
      @project.build_configurations.each do |configuration|
        build_settings = target.build_configuration_list.build_settings(configuration.to_s)
        build_settings.each { |k, _| build_settings.delete(k) }
      end
    end
  end

  def reset_capabilities_to_defaults
    @project.targets.each do |target|
      CapabilitiesHelper.new(@project, target).clear_capabilities
    end
  end

  def process_project_options(options)
    @project.build_configurations.each do |configuration|
      options.each do |key, value|
        configuration.build_settings[key] = value
        configuration.build_settings.delete(key) if value == nil
      end
    end
  end

  def process_shared_target_options(shared_target_options)
    @project.targets.each do |target|
      options = shared_target_options[target.to_s]
      if options
        @project.build_configurations.each do |configuration|
          options.each do |key, value|
            target.build_configuration_list.build_settings(configuration.to_s)[key] = value
            target.build_configuration_list.build_settings(configuration.to_s).delete(key) if value == nil
          end
        end
      end
    end
  end

  def process_all_target_options(all_target_options)
    @project.targets.each do |target|
      @project.build_configurations.each do |configuration|
        target.build_configuration_list.build_settings(configuration.to_s).merge!(all_target_options)
      end
    end
  end

  def process_all_target_option_removals(all_target_option_removals)
    @project.targets.each do |target|
      @project.build_configurations.each do |configuration|
        all_target_option_removals.each do |option_to_remove, value|
          target.build_configuration_list.build_settings(configuration.to_s).delete(option_to_remove)
        end
      end
    end
  end

  def process_target_options(target_options)
    @project.targets.each do |target|
      options = target_options[target.to_s]
      if options
        @project.build_configurations.each do |configuration|
          scheme_options = options[configuration.to_s]
          if scheme_options
            target.build_configuration_list.build_settings(configuration.to_s).merge!(scheme_options)
          end
        end
      end
    end
  end

  def process_target_shell_script_build_phases(target_shell_script_build_phases)
    @project.targets.each do |target|
      shell_script_build_phases = target_shell_script_build_phases[target.to_s]
      if shell_script_build_phases
        target.new_shell_script_build_phase(shell_script_build_phases["name"])
        target.shell_script_build_phases.last.shell_script = shell_script_build_phases["script"]
      end
    end
  end

  def process_capabilities(capabilities_hash)
    capabilities_hash.each do |target_name, capabilities|
      @project.targets.each do |target|
        if target_name == target.to_s
          helper = CapabilitiesHelper.new(@project, target)
          capabilities.each { |c| helper.enable_capability(c) }
        end
      end
    end
  end

  def process_scheme_options(options)
    @project.build_configurations.each do |configuration|
      scheme_options = options[configuration.to_s] || {}
      scheme_options.each do |key, value|
        configuration.build_settings[key] = value
        configuration.build_settings.delete(key) if value == nil
      end
    end
  end

  def process_development_teams(development_teams, default_development_team)
    @project.targets.each do |target|
      if default_development_team
        helper = CapabilitiesHelper.new(@project, target)
        helper.set_development_team(default_development_team)
      end

      development_teams.each do |target_name, development_team|
        if target_name == target.to_s
          helper = CapabilitiesHelper.new(@project, target)
          helper.set_development_team(development_team)
        end
      end
    end
  end

  def process_development_team_names(development_team_names, default_development_team_name)
    @project.targets.each do |target|

      if default_development_team_name
        helper = CapabilitiesHelper.new(@project, target)
        helper.set_development_team_name(default_development_team_name)
      end

      development_team_names.each do |target_name, development_team_name|
        if target_name == target.to_s
          helper = CapabilitiesHelper.new(@project, target)
          helper.set_development_team_name(development_team_name)
        end
      end
    end
  end

  def process_provisioning_styles(provisioning_styles, default_provisioning_style)
    @project.targets.each do |target|
      if default_provisioning_style
          helper = CapabilitiesHelper.new(@project, target)
          helper.set_provisioning_style(default_provisioning_style)
      end
      provisioning_styles.each do |target_name, style|
        if target_name == target.to_s
          helper = CapabilitiesHelper.new(@project, target)
          helper.set_provisioning_style(style)
        end
      end
    end
  end

  def print_info
    puts "Targets:"
    @project.targets.each { |t| puts "- #{t.to_s}" }
    puts ""
    puts "Build configurations:"
    @project.build_configurations.each { |c| puts "- #{c.to_s}" }
    puts ""
  end

  def save_changes
    @project.save
  end

end
