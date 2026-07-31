*** Settings ***
Resource    ../resources/common/common.robot
Resource    ../keywords/navigation_keywords.resource

*** Variables ***
${LOGIN_USERNAME_FIELD}    id=username
${LOGIN_PASSWORD_FIELD}    id=password
${LOGIN_SUBMIT_BUTTON}    id=login-button

*** Keywords ***
Login To Application
    [Documentation]    Fills the login form and submits it using shared browser helpers.
    [Arguments]    ${username}    ${password}    ${username_locator}=${LOGIN_USERNAME_FIELD}    ${password_locator}=${LOGIN_PASSWORD_FIELD}    ${submit_locator}=${LOGIN_SUBMIT_BUTTON}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait And Input Text    ${username_locator}    ${username}    ${timeout}
    Wait And Input Text    ${password_locator}    ${password}    ${timeout}
    Wait And Click Element    ${submit_locator}    ${timeout}
