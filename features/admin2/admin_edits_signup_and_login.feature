@javascript
Feature: Admin edits general privacy page

  Background:
    Given "kassi_testperson1" has admin rights in community "test"
    And I am logged in as "kassi_testperson1"
    And I go to the admin2 users signup and login community "test"

  Scenario: Admin user can set join only with an invite from a registered user
    When I check "Make marketplace invite-only (new users need an invitation from a registered user to sign up)"
     And I uncheck "community_facebook_connect_enabled"
     And I uncheck "community_google_connect_enabled"
     And I uncheck "community_linkedin_connect_enabled"
     And I press submit
    Then I log out
     And I go to the signup page
     And I should see "Invitation code"

  Scenario: Admin user can edit privacy settings
    Then I should see "Signup information text"
    When I follow "Open in editor"
     And I change the contents of "signup_info_content" to "Custom signup info"
     And I click save on the editor
     And I uncheck "community_facebook_connect_enabled"
     And I uncheck "community_google_connect_enabled"
     And I check "community_linkedin_connect_enabled"
    Then I fill in "community_linkedin_connect_id" with "12345678"
     And I fill in "community_linkedin_connect_secret" with "12345678"
     And I press submit
    Then I should see "Signup information text"
     And I should see "Custom signup info"
    Then I log out
     And I follow "Log in"
     And I follow "Create a new account"
    Then I should see "Custom signup info"
     And I should see "Sign up with LinkedIn"
     And I should not see "Sign up with Google"
     And I should not see "Sign up with Facebook"
