Feature: User views terms
  In order to check what terms I am accepting when I register to Sharetribe
  As a user
  I want to be able to 

  @javascript
  Scenario: User views terms in community Test
    Given I am not logged in
    And I am on the signup page
    When I follow "Terms of Service"
    Then I should see "get started with creating your Terms of Service"
  
  
  
  
  
