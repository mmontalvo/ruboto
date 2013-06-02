require 'ruboto/base'
require 'ruboto/package'

#######################################################
#
# ruboto/activity.rb
#
# Basic activity set up.
#
#######################################################

#
# Context
#
module Ruboto
  module Context
    def start_ruboto_dialog(remote_variable, theme=Java::android.R.style::Theme_Dialog, &block)
      java_import 'org.ruboto.RubotoDialog'
      start_ruboto_activity(remote_variable, RubotoDialog, theme, &block)
    end

    def start_ruboto_activity(global_variable_name = '$block_based_activity', klass=RubotoActivity, theme=nil, options = nil, &block)
      # FIXME(uwe): Translate old positional signature to new options-based signature.
      # FIXME(uwe): Remove when we stop supporting Ruboto 0.8.0 or older.
      if options.nil?
        if global_variable_name.is_a?(Hash)
          options = global_variable_name
        else
          options = {}
        end
      end

      class_name = options[:class_name] || "#{klass.name.split('::').last}_#{source_descriptor(block)[0].split('/').last.gsub(/[.-]+/, '_')}_#{source_descriptor(block)[1]}"
      if Object.const_defined?(class_name)
        Object.const_get(class_name).class_eval(&block) if block_given?
      else
        Object.const_set(class_name, Class.new(&block))
      end
      i = android.content.Intent.new
      i.setClass self, klass.java_class
      i.putExtra(Ruboto::THEME_KEY, theme) if theme
      i.putExtra(Ruboto::CLASS_NAME_KEY, class_name) if class_name
      i.putExtra(Ruboto::SCRIPT_NAME_KEY, options[:script]) if options[:script]
      startActivity i
      self
    end

    private

    def source_descriptor(proc)
      if md = /^#<Proc:0x[0-9A-Fa-f]+@(.+):(\d+)(?: \(lambda\))?>$/.match(proc.inspect)
        filename, line = md.captures
        return filename, line.to_i
      end
    end

  end

end

java_import 'android.content.Context'
Context.class_eval do
  include Ruboto::Context
end

#
# Basic Activity Setup
#

module Ruboto
  module Activity
    def method_missing(method, *args, &block)
      return @ruboto_java_instance.send(method, *args, &block) if @ruboto_java_instance && @ruboto_java_instance.respond_to?(method)
      super
    end
  end
end

def ruboto_configure_activity(klass)
  klass.class_eval do
    include Ruboto::Activity
  end
end

java_import 'android.app.Activity'
java_import 'org.ruboto.RubotoActivity'
ruboto_configure_activity(RubotoActivity)

