ENV['RACK_ENV'] = 'test'

require 'init'

require 'test/unit'
require 'shoulda'
require 'mocha'
require 'fakeweb'

class UserTest < Test::Unit::TestCase
  context "A user" do
    context "who is an admin" do
      should "have admin rights" do
        user = User.create(:name => "testuser")
        assert user.admin?
      end
    end

    context "who is not an admin" do
      should "not have admin rights" do
        user = User.create(:name => "not_an_admin")
        assert !user.admin?
      end
    end

    context "with an authorized device" do
      setup do
        @user = User.create(:name => "chris")
        device1 = Device.create(:token => "ABC")
        device2 = Device.create(:token => "EFG")
        device1.stubs(:authorized?).returns(true)
        device2.stubs(:authorized?).returns(false)
        @user.devices << device1
        @user.devices << device2
      end

      should "have authorized devices" do
        assert @user.has_authorized_devices?
      end
    end

    context "with no authorized devices" do
      setup do
        @user = User.create(:name => "chris")
        device1 = Device.create(:token => "ABC")
        device2 = Device.create(:token => "EFG")
        device1.stubs(:authorized?).returns(false)
        device2.stubs(:authorized?).returns(false)
        @user.devices << device1
        @user.devices << device2
      end

      should "have authorized devices" do
        assert !@user.has_authorized_devices?
      end
    end
  end
end

class DeviceTest < Test::Unit::TestCase
  context "A device" do
    should "be authorized when a token exists in the authservice" do
      FakeWeb.register_uri(:get, "http://authservice.test/auth?token=ABC",
                           :status => ["200", "OK"])

      device = Device.create(:token => 'ABC')
      assert device.authorized?
    end

    should "not be authorized when no token exists in the authservice" do
      FakeWeb.register_uri(:get, "http://authservice.test/auth?token=ABC",
                           :status => ["404", "Not found"])

      device = Device.create(:token => 'ABC')
      assert !device.authorized?
    end

    should "support deauthorizing" do
      FakeWeb.register_uri(:post, "http://authservice.test/assoc",
                           :params => {:token => 'ABC', :_method => 'DELETE'},
                           :status => ["204", "Destroyed"])

      device = Device.create(:token => 'ABC')
      assert device.deauthorize!
    end
  end
end
