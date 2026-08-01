*** Settings ***
Library    ../libraries/quarter_utils.py
Resource    ../resources/common/common.resource

*** Variables ***
${MENU_BUTTON}    xpath=//button[contains(@aria-label, 'menu') or contains(@class, 'menu') or contains(@id, 'menu')]
${DROPDOWN_OPTION_TEMPLATE}    xpath=//li[contains(@role, 'option') or contains(@class, 'option') or contains(@role, 'menuitem')][contains(., '{quarter}')]
${REPORTS_MENU_ITEM}    xpath=//a[contains(., 'Reports') or contains(., 'reports')]
${CONTINUITY_OF_CARE_MENU_ITEM}    xpath=//a[contains(., 'Continuity of Care') or contains(., 'continuity of care')]
${ANNUAL_WELL_VISIT_MENU_ITEM}    xpath=//a[contains(., 'Annual Well Visit') or contains(., 'annual well visit')]
${GENERAL_MENU_ITEM}    xpath=//a[contains(., 'General') or contains(., 'general')]
${ER_VISITS_BY_PRACTICE_MENU_ITEM}    xpath=//a[contains(., 'ER Visits By Practice') or contains(., 'ER Visits by Practice') or contains(., 'er visits by practice')]
${IP_ADMISSIONS_BY_PRACTICE_MENU_ITEM}    xpath=//a[contains(., 'IP Admissions By Practice') or contains(., 'IP Admissions by Practice') or contains(., 'ip admissions by practice')]

*** Keywords ***
Click Menu Button
    [Documentation]    Opens the menu by clicking the configured menu button.
    [Arguments]    ${menu_locator}=${MENU_BUTTON}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait And Click Element    ${menu_locator}    ${timeout}

Click Quarter From Menu
    [Documentation]    Selects the requested quarter option from the opened menu.
    [Arguments]    ${quarter}    ${timeout}=${DEFAULT_TIMEOUT}
    ${normalized_quarter}=    Normalize Quarter Value    ${quarter}
    ${option_locator}=    Replace String    ${DROPDOWN_OPTION_TEMPLATE}    {quarter}    ${normalized_quarter}
    Wait And Click Element    ${option_locator}    ${timeout}

Click Reports Menu Item
    [Documentation]    Clicks the Reports menu item.
    [Arguments]    ${timeout}=${DEFAULT_TIMEOUT}
    Wait And Click Element    ${REPORTS_MENU_ITEM}    ${timeout}

Click Continuity Of Care Menu Item
    [Documentation]    Clicks the Continuity of Care menu item.
    [Arguments]    ${timeout}=${DEFAULT_TIMEOUT}
    Wait And Click Element    ${CONTINUITY_OF_CARE_MENU_ITEM}    ${timeout}

Click Annual Well Visit Menu Item
    [Documentation]    Clicks the Annual Well Visit menu item.
    [Arguments]    ${timeout}=${DEFAULT_TIMEOUT}
    Wait And Click Element    ${ANNUAL_WELL_VISIT_MENU_ITEM}    ${timeout}

Click General Menu Item
    [Documentation]    Clicks the General menu item.
    [Arguments]    ${timeout}=${DEFAULT_TIMEOUT}
    Wait And Click Element    ${GENERAL_MENU_ITEM}    ${timeout}

Click ER Visits By Practice Menu Item
    [Documentation]    Clicks the ER Visits By Practice menu item.
    [Arguments]    ${timeout}=${DEFAULT_TIMEOUT}
    Wait And Click Element    ${ER_VISITS_BY_PRACTICE_MENU_ITEM}    ${timeout}

Click IP Admissions By Practice Menu Item
    [Documentation]    Clicks the IP Admissions By Practice menu item.
    [Arguments]    ${timeout}=${DEFAULT_TIMEOUT}
    Wait And Click Element    ${IP_ADMISSIONS_BY_PRACTICE_MENU_ITEM}    ${timeout}

