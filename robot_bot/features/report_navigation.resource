*** Settings ***
Resource    ../keywords/navigation_keywords.resource

*** Variables ***
${REPORTS_MENU_ITEM}    xpath=//a[contains(., 'Reports') or contains(., 'reports')]
${CONTINUITY_OF_CARE_MENU_ITEM}    xpath=//a[contains(., 'Continuity of Care') or contains(., 'continuity of care')]
${ANNUAL_WELL_VISIT_MENU_ITEM}    xpath=//a[contains(., 'Annual Well Visit') or contains(., 'annual well visit')]

*** Keywords ***
Select Nearest Quarter From Menu
    [Documentation]    Opens the menu and selects the quarter option matching the provided value.
    [Arguments]    ${quarter}    ${menu_locator}=${MENU_BUTTON}    ${timeout}=${DEFAULT_TIMEOUT}
    Click Menu Button    ${menu_locator}    ${timeout}
    Click Quarter From Menu    ${quarter}    ${timeout}

Navigate To Annual Well Visit Report
    [Documentation]    Opens the Reports menu and navigates to the Annual Well Visit report.
    [Arguments]    ${timeout}=${DEFAULT_TIMEOUT}
    Click Reports Menu Item    ${timeout}
    Click Continuity Of Care Menu Item    ${timeout}
    Click Annual Well Visit Menu Item    ${timeout}
