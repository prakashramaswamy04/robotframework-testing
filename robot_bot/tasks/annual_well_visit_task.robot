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
Suite Setup    Log To Console    Starting Annual Well Visit report flow
Suite Teardown    Cleanup After Run

*** Variables ***
${RUN_LOG_DIR}    ${CURDIR}/../logs/annual_well_visit
${KEYWORD_LOG_FILE}    ${CURDIR}/keywords_log.txt

*** Keywords ***
Open Annual Well Visit Report
    [Documentation]    Launches the application, logs in, and navigates to the Annual Well Visit report.
    [Arguments]    ${url}    ${username}    ${password}    ${quarter}    ${timeout}=${DEFAULT_TIMEOUT}
    ${timestamp}=    Evaluate    __import__('datetime').datetime.now().strftime('%Y%m%d_%H%M%S')
    Set Suite Variable    ${TIMESTAMP}    ${timestamp}
    ${run_dir}=    Set Variable    ${RUN_LOG_DIR}/${timestamp}
    Create Directory    ${run_dir}
    Append To File    ${KEYWORD_LOG_FILE}    Annual Well Visit run ${timestamp}\n
    Append To File    ${CURDIR}/../logs/annual_well_visit_run_summary.txt    Annual Well Visit | ${timestamp} | started\n
    Launch Application    ${url}    timeout=${timeout}
    Login To Application    ${username}    ${password}    timeout=${timeout}
    Open Report Flow    ${quarter}    timeout=${timeout}
    Append To File    ${CURDIR}/../logs/annual_well_visit_run_summary.txt    Annual Well Visit | ${timestamp} | completed\n
    Log    Annual Well Visit report flow completed successfully

*** Test Cases ***
Run Annual Well Visit Report Flow
    [Tags]    annual_well_visit
    Open Annual Well Visit Report    ${URL}    ${USERNAME}    ${PASSWORD}    ${QUARTER}
