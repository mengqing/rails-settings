module RailsSettings
  module Base
    def self.included(base)
      base.class_eval do
        has_many :setting_objects,
                 :as         => :target,
                 :autosave   => true,
                 :dependent  => :delete_all,
                 :class_name => self.setting_object_class_name

        def settings(var, postfix=nil)
          raise ArgumentError unless var.is_a?(Symbol)
          raise ArgumentError.new("Unknown key: #{var}") unless self.class.default_settings[var]

          var = _amend_postfix(var, postfix)

          if defined?(ProtectedAttributes)
            setting_objects.detect { |s| s.var == var.to_s } || setting_objects.build({ :var => var.to_s }, :without_protection => true)
          else
            setting_objects.detect { |s| s.var == var.to_s } || setting_objects.build(:var => var.to_s, :target => self)
          end
        end

        def settings=(value)
          if value.nil?
            setting_objects.each(&:mark_for_destruction)
          else
            raise ArgumentError
          end
        end

        def settings?(var=nil)
          if var.nil?
            setting_objects.any? { |setting_object| !setting_object.marked_for_destruction? && setting_object.value.present? }
          else
            settings(var).value.present?
          end
        end

        def to_settings_hash
          settings_hash = self.class.default_settings.dup
          settings_hash.each do |var, vals|
            settings_hash[var] = settings_hash[var].merge(settings(var.to_sym).value)
          end
          settings_hash
        end

        private

        def _amend_postfix(var, postfix)
          unless postfix.nil?
            if postfix.is_a?(Class)
              var = [var.to_s,postfix.to_s.downcase].join(':').to_sym
            elsif postfix.respond_to?(:id) && postfix.try(:id)
              postfix = [postfix.class.to_s.downcase, postfix.id].join('_')
              var = [var.to_s,postfix].join(':').to_sym
            else
              raise ArgumentError unless postfix.is_a?(Symbol)
              var = [var.to_s,postfix.to_s].join(':').to_sym
            end
          end
          var
        end
      end
    end
  end
end
