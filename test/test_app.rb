ENV['RACK_ENV'] = 'test'

require 'init'

require 'test/unit'
require 'shoulda'
require 'mocha'
require 'pp'
require 'capybara'
require 'capybara/dsl'
require 'fakeweb'

module Helpers
  require 'ostruct'

  def log_in_with(username, password)
    visit '/'
    fill_in 'name', :with => username
    fill_in 'password', :with => password
    click_on 'Sign in'
  end

  def assert_page_contains(text)
    assert page.has_content?(text), "Expected #{page.body} to contain '#{text}'"
  end

  def assert_page_does_not_contain(text)
    assert !page.has_content?(text), "Did not expect #{page.body} to contain '#{text}'"
  end

  def register_a_device(name)
    FakeWeb.register_uri(:post, "http://authservice.test/assoc",
                         :body => {:pin => 8888}.to_json,
                         :status => ["201", "Created"])

    visit '/devices'
    fill_in 'registration_key', :with => GenerateID.rand_hex
    click_on 'Next'
    fill_in 'name', :with => name
    click_on 'Next'
    click_link 'OK'
  end
end

class RadioTAGTest < Test::Unit::TestCase
  include Capybara
  include Helpers

  Capybara.app = RadioTagOmniAuth
  FakeWeb.allow_net_connect = false

  context "A log-in attempt" do
    setup do
      User.create :name => 'testuser', :password => 'test'
      Capybara.reset_sessions!
    end

    should "fail with an empty password" do
      log_in_with('testuser', '')
      assert_page_contains 'Please check your details'
    end

    should "fail with an incorrect password" do
      log_in_with('testuser', 'wrong')
      assert_page_contains 'Please check your details'
    end

    should "succeed with a correct password" do
      log_in_with('testuser', 'test')
      assert_page_contains 'Hello Testuser'
    end
  end

  context "visiting the home page" do
    context "with no authorized devices" do
      setup do
        user = User.create(:name => "test", :password => "test")
        User.stubs(:get).returns(user)
        user.stubs(:has_authorized_devices?).returns(false)
      end

      should "be redirected to the devices page" do
        Capybara.reset_sessions!
        log_in_with('test', 'test')
        assert_equal '/device', current_path
      end
    end

    context "with authorized devices" do
      setup do
        user = User.create(:name => "test1", :password => "test1")
        User.stubs(:get).returns(user)
        user.stubs(:has_authorized_devices?).returns(true)
      end

      should "be redirected to the tags page" do
        Capybara.reset_sessions!
        log_in_with('test1', 'test1')
        assert_equal '/bookmarks', current_path
      end
    end
  end

  context "An admin user" do
    setup do
      Capybara.reset_sessions!
      # admin users for test env are defined in config/admin.yml
      user = User.create :name => 'testuser', :password => 'test'
    end

    should "be able to see the admin pages" do
      log_in_with('testuser', 'test')
      visit '/admin'
      assert_page_contains 'Admin'
    end
  end

  context "A non-admin user" do
    setup do
      Capybara.reset_sessions!
      # admin users for test env are defined in config/admin.yml
      user = User.create :name => 'nonadminuser', :password => 'test'
    end

    should "be able to see the admin pages" do
      log_in_with('nonadminuser', 'test')
      visit '/admin'
      assert_page_does_not_contain 'Admin'
    end
  end

  context "A logged in user" do
    setup do
      user = User.create :name => 'bob', :password => 'test'
      User.stubs(:get).returns(user)
      user.stubs(:has_authorized_devices?).returns(false)

      Capybara.reset_sessions!
    end

    context "adding a device" do
      should "receive a PIN if the registration details are correct" do
        FakeWeb.register_uri(:post, "http://authservice.test/assoc",
                             :body => {:pin => 8888}.to_json,
                             :status => ["201", "Created"])

        log_in_with('testuser', 'test')

        # Step 1 - Get your radio code
        click_on 'Next'

        # Step 2 - Enter your radio code
        fill_in 'registration_key', :with => "5c949659"
        click_on 'Check'

        # Step 3 - Test
        assert_page_contains '8888'
        click_on 'Test'

        # Step 4 - Done
        assert_page_contains 'View Tags'
      end
    end
  end
end
