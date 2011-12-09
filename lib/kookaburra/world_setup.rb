# Can't use a custom World class, because cucumber-rails is already doing that
module Kookaburra::WorldSetup
  def ui;    @drivers[:ui_driver   ]; end
  def api;   @drivers[:api_driver  ]; end
  def given; @drivers[:given_driver]; end

  def __kookaburra_setup
    @drivers = Kookaburra.drivers
  end
end
