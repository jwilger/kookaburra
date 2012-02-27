describe 'Kookaburra Integration' do
  describe "testing a Rack application" do
    describe "with an HTML interface" do
      describe "with a JSON API" do
        it "runs the tests against the app" do
          pending 'WIP' do
            k = Kookaburra.new(:given_driver => my_given_driver, :ui_driver => my_ui_driver)

            k.given.a_user(:bob)
            k.given.a_widget(:widget_a)
            k.given.a_widget(:widget_b, :name => 'Foo')

            k.ui.sign_in(:bob)
            k.ui.navigate_to :widget_list
            k.ui.widget_list.widgets.should == [k.widgets[:widget_a], k.widgets[:widget_b]]

            k.ui.create_new_widget(:widget_c, :name => 'Bar')
            k.ui.widget_list.widgets.should == [k.widgets[:widget_a], k.widgets[:widget_b], k.widgets[:widget_c]]

            k.ui.delete_widget(:widget_b)
            k.ui.widget_list.widgets.should == [k.widgets[:widget_a], k.widgets[:widget_c]]
          end
        end
      end
    end
  end
end
