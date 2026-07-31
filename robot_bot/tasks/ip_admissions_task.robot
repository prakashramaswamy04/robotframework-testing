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
Suite Setup    Log To Console    Starting IP Admissions report flow
Suite Teardown    Cleanup After Run

*** Variables ***
${RUN_LOG_DIR}    ${CURDIR}/../logs/ip_admissions
${KEYWORD_LOG_FILE}    ${CURDIR}/keywords_log.txt

*** Keywords ***
Open IP Admissions Report
    [Documentation]    Launches the application, logs in, and navigates to the IP Admissions report.
    [Arguments]    ${url}    ${username}    ${password}    ${quarter}    ${timeout}=${DEFAULT_TIMEOUT}
    ${timestamp}=    Evaluate    __import__('datetime').datetime.now().strftime('%Y%m%d_%H%M%S')
    Set Suite Variable    ${TIMESTAMP}    ${timestamp}
    ${run_dir}=    Set Variable    ${RUN_LOG_DIR}/${timestamp}
    Create Directory    ${run_dir}
    Append To File    ${KEYWORD_LOG_FILE}    IP Admissions run ${timestamp}\n
    Append To File    ${CURDIR}/../logs/ip_admissions_run_summary.txt    IP Admissions | ${timestamp} | started\n
    Launch Application    ${url}    timeout=${timeout}
    Login To Application    ${username}    ${password}    timeout=${timeout}
    Open IP Admissions Report Flow    ${quarter}    timeout=${timeout}
    Append To File    ${CURDIR}/../logs/ip_admissions_run_summary.txt    IP Admissions | ${timestamp} | completed\n
    Log    IP Admissions report flow completed successfully

*** Test Cases ***
Run IP Admissions Report Flow
    [Tags]    ip_admissions
    Open IP Admissions Report    ${URL}    ${USERNAME}    ${PASSWORD}    ${QUARTER}
