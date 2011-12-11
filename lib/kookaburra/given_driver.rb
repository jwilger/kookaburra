class Kookaburra::GivenDriver
  def initialize(opts)
    @api = opts.fetch(:api_driver)
  end
end
