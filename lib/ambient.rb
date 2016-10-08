unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative 'project_helper'
require_relative 'capabilities_helper'
require_relative 'dsl'

module Ambient
  extend self
  Ambient::ROOT = File.expand_path('.', File.dirname(__FILE__))

  @use_defaults = false
  @project_options = {}
  @shared_target_options = {}
  @target_options = {}
  @scheme_options = {}
  @parents = {}
  @capabilities = {}
  @development_team = nil
  @development_teams = {}
  @development_team_name = nil
  @development_team_names = {}
  @provisioning_style = nil
  @provisioning_styles = {}
  @all_target_options = {}
  @all_target_option_removals = {}

  def configure(&block)
    instance_eval &block
  end

  def project_helper
    @project_helper
  end

  def set_parent_scheme(target: nil, child: nil, parent: nil)
    target = target || :all
    @parents[target] ||= {}
    @parents[target][child] = parent
  end

  def set_all_targets_option(option, value)
    @all_target_options[option] =  value
  end

  def set_all_targets_option_removal(option)
    @all_target_option_removals[option] =  true
  end

  def set_option(option, value, target: nil, scheme: nil, parent: nil)
    value = "YES" if value == true
    value = "NO" if value == false
    value = nil if value == :default

    if target
      if scheme
        @target_options[target] ||= {}
        @target_options[target][scheme] ||= {}
        @target_options[target][scheme][option] = value
      else
        @shared_target_options[target] ||= {}
        @shared_target_options[target][option] = value
      end
    else
      if scheme
        @scheme_options[scheme] ||= {}
        @scheme_options[scheme][option] = value
      else
        @project_options[option] = value
      end
    end
  end

  def set_capability(target_name, capability_name)
    capabilities = @capabilities[target_name] ||= []
    capabilities << capability_name
  end

  def set_development_team(target_name, team_name)
    if target_name
      @development_teams[target_name] = team_name
    else
      @development_team = team_name
    end
  end

  def set_development_team_name(target_name, team_name)
    if target_name
      @development_team_names[target_name] = team_name
    else
      @development_team_name = team_name
    end
  end

  def set_provisioning_style(target_name, style)
    if target_name
      @provisioning_styles[target_name] = style
    else
      @provisioning_style = style
    end
  end

  def setup_project(ambientfile, xcodeproj_glob)
    @project_helper = ProjectHelper.new xcodeproj_glob
    run_ambientfile(ambientfile)
    project_helper.print_info
    reset_project_to_defaults if @use_defaults
    reset_targets_to_defaults if @use_defaults
    reset_capabilites_to_defaults if @use_defaults
    load_in_parent_scheme_values
    process_project_options
    process_scheme_options
    process_all_target_options
    process_all_target_option_removals
    process_shared_target_options
    process_target_options
    process_capabilities
    process_development_teams
    process_provisioning_styles
    project_helper.save_changes
  end

  def reset_project_to_defaults
    puts "resetting project settings to xcode default settings"
    project_helper.reset_project_to_defaults
  end

  def reset_targets_to_defaults
    puts "resetting target settings to xcode default settings"
    project_helper.reset_targets_to_defaults
  end

  def reset_capabilites_to_defaults
    puts "resetting capabilities to xcode default settings"
    project_helper.reset_capabilities_to_defaults
  end

  def process_project_options
    puts "applying ambient project settings"
    project_helper.process_project_options(@project_options)
  end

  def process_all_target_options
    puts "applying all target options"
    project_helper.process_all_target_options(@all_target_options)
  end

  def process_all_target_option_removals
    puts "applying all target options removals"
    project_helper.process_all_target_option_removals(@all_target_option_removals)
  end

  def process_scheme_options
    puts "applying ambient scheme settings"
    project_helper.process_scheme_options(@scheme_options)
  end

  def process_shared_target_options
    puts "applying ambient shared target settings"
    project_helper.process_shared_target_options(@shared_target_options)
  end

  def process_target_options
    puts "applying ambient target settings"
    project_helper.process_target_options(@target_options)
  end

  def process_capabilities
    puts "applying ambient capabilities"
    project_helper.process_capabilities(@capabilities)
  end

  def process_development_teams
    puts "applying ambient development teams"
    project_helper.process_development_teams(@development_teams, @development_team)
    project_helper.process_development_team_names(@development_team_names, @development_team_name)
  end

  def process_provisioning_styles
    puts "applying ambient provisioning styles"
    project_helper.process_provisioning_styles(@provisioning_styles, @provisioning_style)
  end

  def load_in_parent_scheme_values
    @parents.each do |target, parents|
      parents.each do |child, parent|
        if parent
          if target == :all
            puts "Identified #{child} as a child of #{parent}"
            child_options = @scheme_options[child]
            parent_options = @scheme_options[parent]
          else
            target_options = @target_options[target]
            child_options = target_options[child]
            parent_options = target_options[parent]
          end
          child_options.merge!(parent_options) { |_, child, _| child }
        end
      end
    end
  end

  def run_ambientfile(filename)
    puts "Reading settings from #{filename}"
    ambient = File.join(Dir.pwd, filename)
    raise "#{filename} not found in current directory." unless File.exists?(ambient)
    load ambient
  end
end
