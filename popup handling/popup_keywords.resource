*** Settings ***
Documentation    Popup handling — built entirely with native Robot Framework
...              keywords (SeleniumLibrary, OperatingSystem, Collections,
...              BuiltIn). JSON read/write uses the built-in `Evaluate`
...              keyword (BuiltIn library) since Robot has no core JSON
...              library — that's inline Python via a standard keyword,
...              not a custom library file.
Library          SeleniumLibrary
Library          Collections
Library          OperatingSystem
Library          String
Library          ./ai_xpath_finder.py

*** Variables ***
${POPUPS_JSON}          ${CURDIR}/popups.json
${DISCOVERY_LOG_JSON}   ${CURDIR}/discovered_popups_log.json
${SCREENSHOT_DIR}       ${CURDIR}/popup_screenshots

*** Keywords ***
Handle Known Popups
    [Documentation]    Scans popups.json in priority order (cross > no > close
    ...    > yes) and clicks the first visible match. Repeats up to
    ...    ${max_rounds} times since closing one popup can reveal another.
    ...    Returns the number of popups closed.
    [Arguments]    ${max_rounds}=5
    Create Directory    ${SCREENSHOT_DIR}
    ${popup_data}=    Load Popup Config
    ${popups}=    Get From Dictionary    ${popup_data}    popups
    ${closed_count}=    Set Variable    ${0}

    FOR    ${round}    IN RANGE    ${max_rounds}
        ${closed_this_round}=    Set Variable    ${FALSE}

        FOR    ${popup}    IN    @{popups}
            ${category}=    Get From Dictionary    ${popup}    category
            ${xpaths}=    Get From Dictionary    ${popup}    xpaths
            ${id}=    Get From Dictionary    ${popup}    id

            FOR    ${xpath}    IN    @{xpaths}
                ${visible}=    Run Keyword And Return Status
                ...    Element Should Be Visible    xpath:${xpath}
                IF    ${visible}
                    Click Element    xpath:${xpath}
                    Log    Closed popup '${id}' (category: ${category}) using xpath: ${xpath}
                    Sleep    0.5s
                    ${closed_count}=    Evaluate    ${closed_count} + 1
                    ${closed_this_round}=    Set Variable    ${TRUE}
                    BREAK
                END
            END

            IF    ${closed_this_round}    BREAK
        END

        IF    not ${closed_this_round}    BREAK
    END

    RETURN    ${closed_count}

Handle Unknown Popup
    [Documentation]    Call this when a popup you don't have an xpath for is
    ...    (or might be) on screen. Captures a screenshot + page DOM using
    ...    native SeleniumLibrary/OperatingSystem keywords, and logs an
    ...    "unresolved" entry to discovered_popups_log.json.
    ...    Returns capture_id, screenshot_path, dom_path.
    [Arguments]    ${notes}=${EMPTY}
    Create Directory    ${SCREENSHOT_DIR}

    ${timestamp}=    Get Time    format=%Y%m%d_%H%M%S
    ${capture_id}=    Set Variable    capture_${timestamp}
    ${screenshot_path}=    Set Variable    ${SCREENSHOT_DIR}/unknown_popup_${timestamp}.png
    Capture Page Screenshot    ${screenshot_path}

    ${dom_path}=    Set Variable    ${SCREENSHOT_DIR}/unknown_popup_${timestamp}.html
    ${page_source}=    Get Source
    Create File    ${dom_path}    ${page_source}    encoding=UTF-8

    ${page_url}=    Get Location
    ${found_at}=    Get Time    format=%Y-%m-%dT%H:%M:%S

    ${entry}=    Create Dictionary
    ...    capture_id=${capture_id}    status=unresolved    found_at=${found_at}
    ...    test_name=${TEST NAME}    page_url=${page_url}
    ...    screenshot_path=${screenshot_path}    dom_path=${dom_path}
    ...    notes=${notes}    category=${NONE}    xpath=${NONE}

    Append Discovery Log Entry    ${entry}
    Log    Unknown popup captured (${capture_id}). Screenshot: ${screenshot_path}, DOM: ${dom_path}    WARN
    RETURN    ${capture_id}    ${screenshot_path}    ${dom_path}

Add Popup Xpath
    [Documentation]    Appends a newly discovered xpath into popups.json under
    ...    ${category} (cross / no / close / yes) so `Handle Known Popups`
    ...    picks it up automatically. Also logs a "resolved" entry to
    ...    discovered_popups_log.json. Pass the ${capture_id} from
    ...    `Handle Unknown Popup` to link the two entries together.
    [Arguments]    ${category}    ${xpath}    ${popup_id}=${NONE}
    ...    ${capture_id}=${NONE}    ${source}=manual    ${notes}=${EMPTY}
    ${category}=    Convert To Lower Case    ${category}

    IF    "${popup_id}" == "None"
        ${epoch}=    Evaluate    int(time.time())    time
        ${popup_id}=    Set Variable    ${category}_${epoch}
    END

    ${data}=    Evaluate    json.load(open(r'''${POPUPS_JSON}''', encoding='utf-8'))    json
    ${popups}=    Get From Dictionary    ${data}    popups
    ${found}=    Set Variable    ${FALSE}

    FOR    ${popup}    IN    @{popups}
        ${existing_id}=    Get From Dictionary    ${popup}    id
        IF    "${existing_id}" == "${popup_id}"
            ${existing_xpaths}=    Get From Dictionary    ${popup}    xpaths
            ${already_there}=    Evaluate    "${xpath}" in $existing_xpaths
            IF    not ${already_there}
                Append To List    ${existing_xpaths}    ${xpath}
            END
            ${found}=    Set Variable    ${TRUE}
            BREAK
        END
    END

    IF    not ${found}
        ${new_xpaths}=    Create List    ${xpath}
        ${new_popup}=    Create Dictionary    id=${popup_id}    category=${category}    xpaths=${new_xpaths}
        Append To List    ${popups}    ${new_popup}
    END

    Evaluate    json.dump($data, open(r'''${POPUPS_JSON}''', 'w', encoding='utf-8'), indent=2)    json

    ${found_at}=    Get Time    format=%Y-%m-%dT%H:%M:%S
    ${entry}=    Create Dictionary
    ...    capture_id=${capture_id}    status=resolved    found_at=${found_at}
    ...    popup_id=${popup_id}    category=${category}    xpath=${xpath}
    ...    source=${source}    notes=${notes}
    Append Discovery Log Entry    ${entry}

    Log    Added new popup xpath '${xpath}' under category '${category}'

Handle Unknown Popup With AI Fallback
    [Documentation]    Captures the current unknown popup, asks the AI for a
    ...    suggested category + xpath, CLICKS it right now to actually
    ...    dismiss the popup, and — only if that click succeeded — registers
    ...    the xpath into popups.json so future runs handle it via
    ...    `Handle Known Popups` without needing the AI again.
    ...    Returns ${TRUE} if the popup was dismissed, ${FALSE} otherwise.
    [Arguments]    ${notes}=${EMPTY}
    ${capture_id}    ${screenshot}    ${dom}=    Handle Unknown Popup    notes=${notes}

    ${category}    ${xpath}    ${confidence}    ${reasoning}=
    ...    Get Xpath Suggestion From AI    ${screenshot}    ${dom}    notes=${notes}

    IF    "${confidence}" == "error"
        Log    AI suggestion failed: ${reasoning}    WARN
        RETURN    ${FALSE}
    END

    Log    AI suggested category='${category}' xpath='${xpath}' (confidence=${confidence}): ${reasoning}

    ${clicked}=    Run Keyword And Return Status    Click Element    xpath:${xpath}

    IF    ${clicked}
        Log    Clicked AI-suggested popup button and dismissed it: ${xpath}
        Add Popup Xpath    ${category}    ${xpath}
        ...    capture_id=${capture_id}    source=ai_suggested    notes=${reasoning}
        RETURN    ${TRUE}
    ELSE
        Log    AI-suggested xpath could not be clicked (not found/visible) — NOT registering it.    WARN
        RETURN    ${FALSE}
    END

Load Popup Config
    [Documentation]    Reads popups.json and returns it as a Robot dictionary,
    ...    with the popups list sorted by category priority
    ...    (cross=0, no=1, close=2, yes=3).
    ${data}=    Evaluate    json.load(open(r'''${POPUPS_JSON}''', encoding='utf-8'))    json
    ${priority}=    Create Dictionary    cross=${0}    no=${1}    close=${2}    yes=${3}
    ${popups}=    Get From Dictionary    ${data}    popups
    ${sorted_popups}=    Evaluate    sorted($popups, key=lambda p: $priority.get(p.get('category'), 99))
    Set To Dictionary    ${data}    popups=${sorted_popups}
    RETURN    ${data}

Append Discovery Log Entry
    [Documentation]    Internal helper: appends one entry to
    ...    discovered_popups_log.json. The only reason this touches JSON via
    ...    Evaluate instead of a plain keyword is that Robot has no core
    ...    library for reading/writing JSON files.
    [Arguments]    ${entry}
    ${log_data}=    Evaluate
    ...    json.load(open(r'''${DISCOVERY_LOG_JSON}''', encoding='utf-8')) if os.path.exists(r'''${DISCOVERY_LOG_JSON}''') else {'discoveries': []}
    ...    json, os
    ${discoveries}=    Get From Dictionary    ${log_data}    discoveries
    Append To List    ${discoveries}    ${entry}
    Set To Dictionary    ${log_data}    discoveries=${discoveries}
    Evaluate    json.dump($log_data, open(r'''${DISCOVERY_LOG_JSON}''', 'w', encoding='utf-8'), indent=2)    json
