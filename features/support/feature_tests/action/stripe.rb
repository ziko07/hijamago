module FeatureTests
  module Action
    module Stripe
      extend Capybara::DSL
      extend RSpec::Matchers

      module_function

      def connect_marketplace_stripe(min_price: "2.0", commission: "5", min_commission: "0.1")
        topbar = FeatureTests::Section::Topbar
        payment_preferences = FeatureTests::Page::AdminPaypalPreferences
        admin_sidebar = FeatureTests::Section::AdminSidebar

        # Connect Paypal for admin
        topbar.navigate_to_admin
        admin_sidebar.click_payments_link
        admin_sidebar.click_stripe_link
        payment_preferences.connect_stripe_account

        expect(page).to have_content("Stripe enabled")

        payment_preferences.edit_payment_transaction_fee_preferences(commission: commission, min_commission: min_commission)
        payment_preferences.click_button("Save changes")

        expect(page).to have_no_selector('#error_save', visible: true)
      end

      def connect_seller_payment
        topbar = FeatureTests::Section::Topbar
        settings_sidebar = FeatureTests::Section::UserSettingsSidebar
        payment_preferences = FeatureTests::Page::UserSettingsPayments

        # Connect Paypal for seller
        topbar.navigate_home
        topbar.open_user_menu
        topbar.click_settings
        settings_sidebar.click_payments_link
        payment_preferences.connect_stripe_account

        expect(page).to have_content("Bank account details configured successfully")
      end

      def request_listing(title:, expected_price: nil)
        home = FeatureTests::Page::Home
        listing = FeatureTests::Page::Listing
        listing_book = FeatureTests::Page::ListingBook
        topbar = FeatureTests::Section::Topbar

        topbar.click_logo
        home.click_listing(title)
        listing.fill_in_booking_dates
        listing.click_request

        expect(page).to have_content("Buy #{title}")
        listing_book.fill_in_message("Snowman ☃ sells: #{title}")

        if expected_price.present?
          # listing.fill_in_booking_dates always selects a two day period
          # expect(page).to have_content("(2 days)")
          expect(listing_book.total_value).to have_content("$#{expected_price}")
        end

        listing_book.pay_with_stripe

        Delayed::Worker.new(quiet: true).work_off

        expect(page).to have_content("Payment authorized")
        expect(page).to have_content("Snowman ☃ sells: #{title}")
      end

      def accept_listing_request
        topbar = FeatureTests::Section::Topbar

        topbar.click_inbox

        # Inbox
        expect(page).to have_content("Waiting for you to accept the request")
        page.click_link("Payment authorized")

        # Transaction conversation page
        page.click_link("Accept request")

        # Order details page
        page.click_button("Accept")
        expect(page).to have_content("Request accepted")
        expect(page).to have_content("Payment successful")
      end

      def buyer_mark_completed
        topbar = FeatureTests::Section::Topbar

        topbar.click_inbox

        # Transaction conversation page
        expect(page).to have_content("Waiting for you to mark the order completed")
        page.find(:xpath, '//a[contains(., "accepted the request")]').click

        page.click_link("Mark completed")

        choose("Skip feedback")
        page.click_button("Continue")

        expect(page).to have_content(I18n.t("layouts.notifications.offer_confirmed"))
        expect(page).to have_content("Feedback skipped")
      end

      def seller_mark_completed
        topbar = FeatureTests::Section::Topbar

        topbar.click_inbox

        # Transaction conversation page
        expect(page).to have_content("Waiting for you to give feedback")
        page.find(:xpath, '//a[contains(., "marked the order as completed")]').click
        page.click_link("Skip feedback")
        expect(page).to have_content("Feedback skipped")
      end
    end
  end
end
