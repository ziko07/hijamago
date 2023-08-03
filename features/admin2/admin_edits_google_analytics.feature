@javascript
Feature: Admin edits google analytics page

  Background:
    Given "kassi_testperson1" has admin rights in community "test"
    And I am logged in as "kassi_testperson1"

  Scenario: Admin user can edit google analytics UA-
    When I go to the google analytics admin page
     And I fill in "community_google_analytics_key" with "UA-google-id"
    Then I press submit
     And I wait for 1 seconds
     And I refresh the page
     And I should see "UA-google-id" in the "community_google_analytics_key" input

  Scenario: Admin user can edit google analytics G-
    When I go to the google analytics admin page
     And I fill in "community_google_analytics_key" with "G-google-id"
    Then I press submit
     And I wait for 1 seconds
     And I refresh the page
     And I should see "G-google-id" in the "community_google_analytics_key" input