require 'test_helper'

class TagAliasCorrectionTest < ActiveSupport::TestCase
  context "A tag alias correction" do
    setup do
      @mod = FactoryGirl.create(:moderator_user)
      CurrentUser.user = @mod
      CurrentUser.ip_addr = "127.0.0.1"
      MEMCACHE.flush_all
      Delayed::Worker.delay_jobs = false
      @post = FactoryGirl.create(:post, :tag_string => "aaa")
      @tag_alias = FactoryGirl.create(:tag_alias, :antecedent_name => "aaa", :consequent_name => "bbb")
    end

    teardown do
      MEMCACHE.flush_all
      CurrentUser.user = nil
      CurrentUser.ip_addr = nil
    end

    context "with a bad cache and post counts" do
      setup do
        Cache.put("ta:aaa", "zzz")
        Tag.update_all("post_count = -3", "name = 'aaa'")
        @correction = TagAliasCorrection.new(@tag_alias.id)
      end

      should "have the correct statistics hash" do
        assert_equal("zzz", @correction.statistics_hash["antecedent_cache"])
        assert_equal("bbb", @correction.statistics_hash["consequent_cache"])
        assert_equal(-3, @correction.statistics_hash["antecedent_count"])
        assert_equal(1, @correction.statistics_hash["consequent_count"])
      end

      should "render to json" do
        assert_nothing_raised do
          @correction.to_json
        end

        assert_nothing_raised do
          JSON.parse(@correction.to_json)
        end
      end

      context "that is fixed" do
        setup do
          @correction.fix!
          TagAlias.to_aliased(["aaa"])
        end

        should "now have the correct cache" do
          assert_equal("bbb", Cache.get("ta:aaa"))
        end

        should "now have the correct count" do
          assert_equal(0, Tag.find_by_name("aaa").post_count)
        end
      end
    end
  end
end
