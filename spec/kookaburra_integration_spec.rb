require 'kookaburra'
require 'rack'
require 'capybara'

describe 'Kookaburra Integration' do
  describe "testing a Rack application" do
    describe "with an HTML interface" do
      describe "with a JSON API" do
        it "runs the tests against the app" do
          # Set up GivenDriver for this test
          my_given_driver_class = Class.new(Kookaburra::GivenDriver) do
            def a_user(name)
            end
          end
          given = my_given_driver_class.new


          given.a_user(:bob)
          pending 'WIP' do
            given.a_widget(:widget_a)
            given.a_widget(:widget_b, :name => 'Foo')

            ui.sign_in(:bob)
            ui.navigate_to :widget_list
            ui.widget_list.widgets.should == [k.widgets[:widget_a], k.widgets[:widget_b]]

            ui.create_new_widget(:widget_c, :name => 'Bar')
            ui.widget_list.widgets.should == [k.widgets[:widget_a], k.widgets[:widget_b], k.widgets[:widget_c]]

            ui.delete_widget(:widget_b)
            ui.widget_list.widgets.should == [k.widgets[:widget_a], k.widgets[:widget_c]]
          end
        end
      end
    end
  end
end
