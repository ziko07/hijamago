Feature: Admin edits info pages
  In order to have custom detail texts tailored specifically for my community
  As an admin
  I want to be able to edit the community details

  Background:
    Given "kassi_testperson1" has admin rights in community "test"
    And I am logged in as "kassi_testperson1"

  @javascript
  Scenario: Admin user can edit community details
    When I go to the admin2 general essential community "test"

    And I fill in "community_customizations[en][name]" with "Custom name"
    And I fill in "community_customizations[en][slogan]" with "Custom slogan"
    And I fill in "community_customizations[en][description]" with "This is a custom description"
    And I press submit
    And I wait for 1 seconds
    When I go to the big cover photo home page
    Then I should see "Custom slogan"
    And I should see "This is a custom description"

  @javascript
  Scenario: Admin user can hide community slogan or description
    When I go to the admin2 general essential community "test"
    And I should see "Display slogan on the homepage"
    And I should see "Display description on the homepage"
    And I uncheck "Display slogan on the homepage"
    And I uncheck "Display description on the homepage"
    And I fill in "community_customizations[en][slogan]" with "Custom slogan"
    And I fill in "community_customizations[en][description]" with "This is a custom description"
    And I press submit
    And I wait for 1 seconds
    When I go to the big cover photo home page
    Then I should not see "Custom slogan"
    And I should not see "This is a custom description"

    When I go to the admin2 general essential community "test"
    And I check "Display slogan on the homepage"
    And I check "Display description on the homepage"
    And I press submit
    And I wait for 1 seconds
    When I go to the big cover photo home page
    Then I should see "Custom slogan"
    And I should see "This is a custom description"

    When I go to the admin2 general essential community "test"
    And I check "Display slogan on the homepage"
    And I uncheck "Display description on the homepage"
    And I press submit
    And I wait for 1 seconds
    When I go to the big cover photo home page
    Then I should see "Custom slogan"
    And I should not see "This is a custom description"

    When I go to the admin2 general essential community "test"
    And I uncheck "Display slogan on the homepage"
    And I check "Display description on the homepage"
    And I press submit
    And I wait for 1 seconds
    When I go to the big cover photo home page
    Then I should not see "Custom slogan"
    And I should see "This is a custom description"
