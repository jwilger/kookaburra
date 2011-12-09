module Kookaburra
  class UIDriver
    module HasFields
      module ClassMethods
        def submit_button_locator(locator)
          define_method(:submit_button_locator) { locator }
        end

        def has_radio_button_for(*names)
          names.each do |n|
            input_xpath_builder_names[n] = :build_radio_input_xpath
          end
        end

        def has_select_for(*names)
          names.each do |n|
            input_xpath_builder_names[n] = :build_select_input_xpath
          end
        end

        def input_xpath_builder_names
          # Inputs without a type attribute, or with a custom or unknown type are
          # textual, so we need to exclude the types that we don't want.
          @input_xpath_builder_names ||= HashWithIndifferentAccess.new(:build_textual_input_xpath)
        end

        def is_select?(name)
          input_xpath_builder_names[name] == :build_select_input_xpath
        end
      end

      module InstanceMethods
        def build_textual_input_xpath(attribute, value=nil)
          # Since the type attribute might not be present or might contain
          # just about any value, check for and exclude nodes with type
          # containing a non-textual value.
          "(" +
            "(.//textarea)|" +
            "(.//input[" +
              "(not(@type='button')) and (not(@type='checkbox')) and (not(@type='radio')) and " +
              "(not(@type='reset')) and (not(@type='submit'))" +
            "])" +
          ")[" +
            "substring(@id,string-length(@id)-#{attribute.length-1},#{attribute.length})='#{attribute}'" +
          "]"
        end

        def build_radio_input_xpath(attribute, value=nil)
          # The id will be the attribute suffixed by something representative of
          # the button value, with an underscore in between, but we don't necessarily
          # know the correct suffix, so ensure that the "_" is in the id, and then
          # find the correct match using the value attribute.
          xpath = ".//input[@type='radio'][contains(@id, #{attribute}_)]"
          xpath = "(#{xpath})[@value='#{value}']"
        end

        def build_select_input_xpath(attribute, value=nil)
          xpath = ".//select[contains(@id, #{attribute})]/option[@value='#{value}']"
        end

        # Find the specified input by its field name.  The value argument is
        # used to find the correct input if (as in the case of a radio button)
        # there might be a separate input element for each value the field might
        # contain.  Otherwise, it is ignored.  When the name value will be used,
        # its #to_s value must be valid as an xpath string body expression.
        def find_input(attribute, value=nil, nth=1, msg=nil)
          method = self.class.input_xpath_builder_names[attribute]
          #TODO: Build a qualified attribute name, and pass that to the xpath builder
          #      to handle forms with multiple models that may have common attribute
          #      names.
          xpath = send(method, attribute.to_s, value.to_s)
          xpath = "(#{xpath})[#{nth}]" if nth > 1
          browser.find(:xpath, xpath, :message => msg)
        end

        def has_validation_errors?
          in_component { browser.has_css?('.inline-errors') }
        end

        def submit_button_locator
          raise "Subclass responsibility!"
        end

        def submit!
          click_on submit_button_locator
          no_500_error!
        end

        def fill_in_fields(hash, idx = 0, opts = {})
          @body = nil

          # If not explicitly ordered, then we must think the fill-in order doesn't
          # matter, so make the order more assuredly arbitrary to find out sooner
          # if that's not a correct thought.
          hash = hash.map.shuffle if Hash === hash && ! ActiveSupport::OrderedHash === hash

          hash.each do |field, value|
            fill_in_form_element(field, value, idx, opts)
          end
        end

        def values_in_fields_match_hash?(hash = {}, opts = {})
          @body = nil
          hash.all? { |field, value| form_element_has_value?(field, value, opts) }
        end

        def read_only_values_match_hash?(hash = {}, opts = {})
          hash.all? do |field, expected_value|
            is_money = opts[:money] && opts[:money].include?(field)
            read_only_value_matches?(expected_value, field, :is_money => is_money)
          end
        end

        def read_only_value_matches?(expected_value, field, opts = {})
          actual_value = read_only_value(field, opts)
          (actual_value == expected_value).tap do |same|
            puts <<-EOF unless same
Read-only value mismatch in #{field}:
  Expected: #{expected_value}
  Actual:   #{actual_value}
            EOF
          end
        end

        def read_only_value(field, opts = {})
          browser.find(:css, ".#{field}").text.tap do |value|
            value.gsub!(/^.*:\s/, '')
            value.gsub!(/[\$,]/, '') if opts[:is_money]
          end
        end

        def tag_visible?(css)
          browser.find(:css, css).visible?
        rescue
          false
        end

        private

        def fill_in_form_element(attribute, value, idx = 0, opts = {})
          msg = "cannot find the field for '#{attribute}' to fill it in."
          input = find_input(attribute, value, idx+1, msg)
          set_value(input, value, attribute)
        end

        def set_value(input, value, attribute)
          if self.class.is_select?(attribute)
            input.select_option
          else
            input.set value
          end
        end

        def form_element_has_value?(attribute, value, idx = 0, opts = {})
          msg = "can't find a field for '#{attribute}' to check its value."
          input = find_input(attribute, value, idx+1, msg)
          # <select> elements are not currently handled.
          if input[:type] == 'radio'
            input.checked?
          else
            input.value == value
          end
        end

      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    end
  end
end
