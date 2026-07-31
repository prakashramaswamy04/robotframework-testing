*** Settings ***
Resource    ../features/report_navigation.resource
Resource    ../keywords/navigation_keywords.resource

*** Keywords ***
Open Report Flow
    [Documentation]    Executes the full report navigation flow end to end.
    [Arguments]    ${quarter}    ${menu_locator}=${MENU_BUTTON}    ${timeout}=${DEFAULT_TIMEOUT}
    Click Menu Button    ${menu_locator}    ${timeout}
    Click Quarter From Menu    ${quarter}    ${timeout}
    Click Reports Menu Item    ${timeout}
    Click Continuity Of Care Menu Item    ${timeout}
    Click Annual Well Visit Menu Item    ${timeout}

Open ER Visits Report Flow
    [Documentation]    Opens the ER Visits report from the Reports menu.
    [Arguments]    ${quarter}    ${menu_locator}=${MENU_BUTTON}    ${timeout}=${DEFAULT_TIMEOUT}
    Click Menu Button    ${menu_locator}    ${timeout}
    Click Quarter From Menu    ${quarter}    ${timeout}
    Click Reports Menu Item    ${timeout}
    Click General Menu Item    ${timeout}
    Click ER Visits By Practice Menu Item    ${timeout}

Open IP Admissions Report Flow
    [Documentation]    Opens the IP Admissions report from the Reports menu.
    [Arguments]    ${quarter}    ${menu_locator}=${MENU_BUTTON}    ${timeout}=${DEFAULT_TIMEOUT}
    Click Menu Button    ${menu_locator}    ${timeout}
    Click Quarter From Menu    ${quarter}    ${timeout}
    Click Reports Menu Item    ${timeout}
    Click General Menu Item    ${timeout}
    Click IP Admissions By Practice Menu Item    ${timeout}
