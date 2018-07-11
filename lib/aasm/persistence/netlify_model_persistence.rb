require 'aasm/persistence/orm'
module AASM
  module Persistence
    module NetlifyModelPersistence
      # This method:
      #
      # * extends the model with ClassMethods
      # * includes InstanceMethods
      #
      # Adds
      #
      #   before_validation :aasm_ensure_initial_state
      #
      # As a result, it doesn't matter when you define your methods - the following 2 are equivalent
      #
      #   class Foo < Model
      #     def aasm_write_state(state)
      #       "bar"
      #     end
      #     include AASM
      #   end
      #
      #   class Foo < Model
      #     include AASM
      #     def aasm_write_state(state)
      #       "bar"
      #     end
      #   end
      #
      def self.included(base)
        base.send(:include, AASM::Persistence::Base)
        base.send(:include, AASM::Persistence::ORM)
        base.send(:include, AASM::Persistence::NetlifyModelPersistence::InstanceMethods)

        base.before_validation :aasm_ensure_initial_state
      end

      module InstanceMethods

        private

        def aasm_save
          self.save
        end

        def aasm_raise_invalid_record
          raise RecordInvalid.new(self)
        end

        def aasm_supports_transactions?
          false
        end

        def aasm_update_column(attribute_name, value)
          update_attributes({ attribute_name => value })
        end

        def aasm_read_attribute(name)
          send(name)
        end

        def aasm_write_attribute(name, value)
          send("#{name}=", value)
        end

        # Ensures that if the aasm_state column is nil and the record is new
        # that the initial state gets populated before validation on create
        #
        #   foo = Foo.new
        #   foo.aasm_state # => nil
        #   foo.valid?
        #   foo.aasm_state # => "open" (where :open is the initial state)
        #
        #
        #   foo = Foo.find(:first)
        #   foo.aasm_state # => 1
        #   foo.aasm_state = nil
        #   foo.valid?
        #   foo.aasm_state # => nil
        #
        def aasm_ensure_initial_state
          AASM::StateMachineStore.fetch(self.class, true).machine_names.each do |name|
            aasm_column = self.class.aasm(name).attribute_name
            aasm(name).enter_initial_state if send(aasm_column).blank?
          end
        end
      end # InstanceMethods
    end
  end # Persistence
end # AASM
