*** Settings ***
Library    SeleniumLibrary
Library    DateTime
Library    Collections
Library    OperatingSystem
Library    String
Library    ../libraries/launch_utils.py
Resource    ../pages/login_page.resource
Resource    ../features/report_flow.resource
Resource    ../resources/common/common.resource
Resource    ../variables/task_variables.resource
Suite Setup    Log To Console    Starting ER Visits report flow
Suite Teardown    Cleanup After Run

*** Variables ***
${RUN_LOG_DIR}    ${CURDIR}/../logs/er_visits
${KEYWORD_LOG_FILE}    ${CURDIR}/keywords_log.txt

*** Keywords ***
Open ER Visits Report
    [Documentation]    Launches the application, logs in, and navigates to the ER Visits report.
    [Arguments]    ${url}    ${username}    ${password}    ${quarter}    ${timeout}=${DEFAULT_TIMEOUT}
    ${timestamp}=    Evaluate    __import__('datetime').datetime.now().strftime('%Y%m%d_%H%M%S')
    Set Suite Variable    ${TIMESTAMP}    ${timestamp}
    ${run_dir}=    Set Variable    ${RUN_LOG_DIR}/${timestamp}
    Create Directory    ${run_dir}
    Append To File    ${KEYWORD_LOG_FILE}    ER Visits run ${timestamp}\n
    Append To File    ${CURDIR}/../logs/er_visits_run_summary.txt    ER Visits | ${timestamp} | started\n
    Launch Application    ${url}    timeout=${timeout}
    Login To Application    ${username}    ${password}    timeout=${timeout}
    Open ER Visits Report Flow    ${quarter}    timeout=${timeout}
    Append To File    ${CURDIR}/../logs/er_visits_run_summary.txt    ER Visits | ${timestamp} | completed\n
    Log    ER Visits report flow completed successfully

*** Test Cases ***
Run ER Visits Report Flow
    [Tags]    er_visits
    Open ER Visits Report    ${URL}    ${USERNAME}    ${PASSWORD}    ${QUARTER}
