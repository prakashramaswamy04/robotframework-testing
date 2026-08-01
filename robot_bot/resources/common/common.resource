*** Settings ***
Library    SeleniumLibrary
Library    DateTime
Library    ../../libraries/launch_utils.py
Resource    ../../variables/common_variables.resource


*** Keywords ***
Wait And Click Element
    [Documentation]    Waits until the element is visible and enabled, then attempts the click with a capped retry window.
    [Arguments]    ${locator}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Until Element Is Visible    ${locator}    timeout=${timeout}
    Wait Until Element Is Enabled    ${locator}    timeout=${timeout}
    Scroll Element Into View Safely    ${locator}
    Element Should Be Clickable    ${locator}
    ${seconds}=    Convert Time    ${timeout}    result_format=number
    ${max_seconds}=    Convert Time    ${MAX_CLICKABLE_TIMEOUT}    result_format=number
    ${capped}=    Set Variable If    ${seconds} < ${max_seconds}    ${seconds}    ${max_seconds}
    ${retry_interval_seconds}=    Convert Time    ${RETRY_INTERVAL}    result_format=number
    ${attempts}=    Evaluate    int(${capped}/${retry_interval_seconds}) + 1
    ${range_end}=    Evaluate    ${attempts} + 1
    ${attempt_count}=    Set Variable    0
    FOR    ${index}    IN RANGE    1    ${range_end}
        ${attempt_count}=    Set Variable    ${index}
        ${status}=    Run Keyword And Return Status    Click Element    ${locator}
        Exit For Loop If    ${status}
        Run Keyword If    ${index} * ${retry_interval_seconds} > ${capped}    Fail    msg=Click failed after ${index} attempts within ${capped} seconds
        Sleep    ${RETRY_INTERVAL}
    END
    Log Element Readiness    ${locator}
    #Log To Console    Click succeeded after ${attempt_count} attempts

Wait Until Element Is Clickable
    [Documentation]    Polls via JS until the element is visible, enabled, and not
    ...    blocked by CSS - then attempts the click within a capped retry window.
    ...    The overall wait never exceeds 90 seconds.
    [Arguments]    ${locator}    ${timeout}=${MAX_CLICKABLE_TIMEOUT}
    Scroll Element Into View Safely    ${locator}
    # Wait until element is reported clickable (Element Should Be Clickable now handles its own retries)
    Element Should Be Clickable    ${locator}    ${timeout}
    ${seconds}=    Convert Time    ${timeout}    result_format=number
    ${max_seconds}=    Convert Time    ${MAX_CLICKABLE_TIMEOUT}    result_format=number
    ${capped}=    Set Variable If    ${seconds} < ${max_seconds}    ${seconds}    ${max_seconds}
    ${retry_interval_seconds}=    Convert Time    ${RETRY_INTERVAL}    result_format=number
    ${attempts}=    Evaluate    int(${capped}/${retry_interval_seconds}) + 1
    ${range_end}=    Evaluate    ${attempts} + 1
    ${attempt_count}=    Set Variable    0
    FOR    ${index}    IN RANGE    1    ${range_end}
        ${attempt_count}=    Set Variable    ${index}
        ${status}=    Run Keyword And Return Status    Click Element    ${locator}
        Exit For Loop If    ${status}
        Run Keyword If    ${index} * ${retry_interval_seconds} > ${capped}    Fail    msg=Click failed after ${index} attempts within ${capped} seconds
        Sleep    ${RETRY_INTERVAL}
    END
    #Log To Console    Click succeeded after ${attempt_count} attempts

Element Should Be Clickable
    [Documentation]    Helper used by "Wait Until Element Is Clickable". Waits until
    ...    visibility, enabled state, and CSS blockers via JS report the element as
    ...    clickable. Retries until timeout.
    [Arguments]    ${locator}    ${timeout}=${MAX_CLICKABLE_TIMEOUT}
    ${seconds}=    Convert Time    ${timeout}    result_format=number
    ${max_seconds}=    Convert Time    ${MAX_CLICKABLE_TIMEOUT}    result_format=number
    ${capped}=    Set Variable If    ${seconds} < ${max_seconds}    ${seconds}    ${max_seconds}
    ${retry_interval_seconds}=    Convert Time    ${RETRY_INTERVAL}    result_format=number
    ${attempts}=    Evaluate    int(${capped}/${retry_interval_seconds}) + 1
    ${range_end}=    Evaluate    ${attempts} + 1
    FOR    ${index}    IN RANGE    1    ${range_end}
        ${status_click}    ${is_clickable}=    Run Keyword And Ignore Error    Get Element Clickable Status    ${locator}
        Run Keyword If    '${status_click}' == 'PASS' and ${is_clickable}    Return From Keyword
        Sleep    ${RETRY_INTERVAL}
    END
    Fail    msg=Element '${locator}' not clickable after ${capped} seconds

Get Element Clickable Status
    [Documentation]    Returns true if the locator points to an element that is
    ...    visible, enabled and not blocked by CSS overlay or pointer interception.
    [Arguments]    ${locator}
    ${element}=    Get WebElement    ${locator}
    ${is_clickable}=    Execute Javascript
    ...    var el = arguments[0];
    ...    try {
    ...      var r = el.getBoundingClientRect();
    ...      var s = window.getComputedStyle(el);
    ...      var visible = (r.width > 0 && r.height > 0 && s.visibility !== 'hidden' && s.display !== 'none' && parseFloat(s.opacity||1) > 0);
    ...      var enabled = (typeof el.disabled === 'undefined' ? true : !el.disabled) && s.pointerEvents !== 'none';
    ...      if (!visible || !enabled) return false;
    ...      var x = r.left + r.width/2;
    ...      var y = r.top + r.height/2;
    ...      var top = document.elementFromPoint(x, y);
    ...      if (!top) return false;
    ...      while (top && top.shadowRoot) { top = top.shadowRoot.elementFromPoint(x, y); }
    ...      return (el === top || el.contains(top));
    ...    } catch (e) { return false; }
    ...    ARGUMENTS    ${element}
    Return From Keyword    ${is_clickable}

Scroll To Element And Click
    [Documentation]    Scrolls the element into view - useful when it's below the fold
    ...    or a fixed header would otherwise intercept the click - then waits and clicks.
    [Arguments]    ${locator}    ${timeout}=${DEFAULT_TIMEOUT}
    Scroll Element Into View    ${locator}
    Wait And Click Element    ${locator}    ${timeout}

Try Click Element
    [Documentation]    Attempts to click and returns boolean instead of failing the test. Captures a screenshot on failure.
    [Arguments]    ${locator}    ${timeout}=${DEFAULT_TIMEOUT}
    ${status}=    Run Keyword And Return Status    Wait And Click Element    ${locator}    ${timeout}
    Run Keyword If    not ${status}    Capture Page Screenshot
    Return From Keyword    ${status}

Launch Application
    [Documentation]    Verifies the URL can be reached, opens it in the browser with Chrome-safe options, maximizes the window, and waits for the page to load.
    [Arguments]    ${url}    ${browser}=chrome    ${timeout}=${DEFAULT_TIMEOUT}
    ${can_access}=    Check Url Accessibility    ${url}    timeout=10
    Run Keyword If    not ${can_access}    Fail    msg=Unable to access URL '${url}' before launching browser
    ${chrome_options}=    Build Chrome Options
    Open Browser    ${url}    ${browser}    options=${chrome_options}
    Maximize Browser Window
    Wait Until Page Contains Element    css=body    timeout=${timeout}

Get Text From Element
    [Documentation]    Waits until the element is clickable, then attempts the text read within a capped retry window.
    [Arguments]    ${locator}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Until Element Is Visible    ${locator}    timeout=${timeout}
    Wait Until Element Is Enabled    ${locator}    timeout=${timeout}
    Scroll Element Into View Safely    ${locator}
    Element Should Be Clickable    ${locator}
    ${seconds}=    Convert Time    ${timeout}    result_format=number
    ${max_seconds}=    Convert Time    ${MAX_CLICKABLE_TIMEOUT}    result_format=number
    ${capped}=    Set Variable If    ${seconds} < ${max_seconds}    ${seconds}    ${max_seconds}
    ${retry_interval_seconds}=    Convert Time    ${RETRY_INTERVAL}    result_format=number
    ${attempts}=    Evaluate    int(${capped}/${retry_interval_seconds}) + 1
    ${range_end}=    Evaluate    ${attempts} + 1
    ${attempt_count}=    Set Variable    0
    FOR    ${index}    IN RANGE    1    ${range_end}
        ${attempt_count}=    Set Variable    ${index}
        ${status}=    Run Keyword And Return Status    Get Text    ${locator}
        Exit For Loop If    ${status}
        Run Keyword If    ${index} * ${retry_interval_seconds} > ${capped}    Fail    msg=Text read failed after ${index} attempts within ${capped} seconds
        Sleep    ${RETRY_INTERVAL}
    END
    ${text}=    Get Text    ${locator}
    Log Element Readiness    ${locator}
    [Return]    ${text}

Scroll Element Into View Safely
    [Documentation]    Scrolls the element into the center of the viewport, verifies it's in view, and focuses it for better reliability.
    [Arguments]    ${locator}
    Scroll Element Into View    ${locator}
    ${element}=    Get WebElement    ${locator}
    Execute Javascript
    ...    arguments[0].scrollIntoView({block: 'center', inline: 'nearest', behavior: 'instant'});
    ...    ARGUMENTS    ${element}
    Wait Until Keyword Succeeds    5s    0.2s    Element Should Be In Viewport    ${locator}
    ${element}=    Get WebElement    ${locator}
    Execute Javascript
    ...    arguments[0].focus();
    ...    ARGUMENTS    ${element}
    Mouse Over    ${locator}

Log Element Readiness
    [Documentation]    Logs whether the target element is visible and enabled.
    [Arguments]    ${locator}
    ${visible_status}=    Run Keyword And Return Status    Element Should Be Visible    ${locator}
    ${enabled_status}=    Run Keyword And Return Status    Element Should Be Enabled    ${locator}
    Log    Element '${locator}' visible=${visible_status}, enabled=${enabled_status}

Element Should Be In Viewport
    [Documentation]    Checks whether the element is fully visible inside the current browser viewport.
    [Arguments]    ${locator}
    ${element}=    Get WebElement    ${locator}
    ${is_in_viewport}=    Execute Javascript
    ...    var el = arguments[0];
    ...    try {
    ...      var rect = el.getBoundingClientRect();
    ...      var viewHeight = window.innerHeight || document.documentElement.clientHeight;
    ...      var viewWidth = window.innerWidth || document.documentElement.clientWidth;
    ...      return rect.top >= 0 && rect.left >= 0 && rect.bottom <= viewHeight && rect.right <= viewWidth;
    ...    } catch (e) { return false; }
    ...    ARGUMENTS    ${element}
    Should Be True    ${is_in_viewport}    msg=Element '${locator}' is not in viewport


Prepare Element
    [Documentation]    Common preparation performed before interacting with an element.
    [Arguments]    ${locator}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Until Element Is Visible    ${locator}    timeout=${timeout}
    Wait Until Element Is Enabled    ${locator}    timeout=${timeout}
    Scroll Element Into View Safely    ${locator}
    Log Element Readiness    ${locator}

Wait And Input Text
    [Documentation]    Waits until the field is visible and enabled, then types into it.
    ...    Uses SeleniumLibrary's Input Text, which clears any existing value first.
    [Arguments]    ${locator}    ${text}    ${timeout}=${DEFAULT_TIMEOUT}
    Prepare Element    ${locator}    ${timeout}
    Input Text    ${locator}    ${text}

Wait And Select From List By Label
    [Documentation]    Waits until the dropdown is visible and enabled, then selects
    ...    an option by its visible label.
    [Arguments]    ${locator}    ${label}    ${timeout}=${DEFAULT_TIMEOUT}
    Prepare Element    ${locator}    ${timeout}
    Select From List By Label    ${locator}    ${label}

Wait And Clear Text
    [Documentation]    Waits until an input is ready, clears it, and confirms the value is empty.
    [Arguments]    ${locator}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Until Element Is Visible    ${locator}    timeout=${timeout}
    Wait Until Element Is Enabled    ${locator}    timeout=${timeout}
    Scroll Element Into View Safely    ${locator}
    Clear Element Text    ${locator}

Wait And Press Keys
    [Documentation]    Waits until an element is ready and sends key presses to it.
    [Arguments]    ${locator}    ${keys}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Until Element Is Visible    ${locator}    timeout=${timeout}
    Wait Until Element Is Enabled    ${locator}    timeout=${timeout}
    Scroll Element Into View Safely    ${locator}
    Press Keys    ${locator}    ${keys}

Wait And Check
    [Documentation]    Waits until a checkbox or radio is ready, then selects it.
    [Arguments]    ${locator}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Until Element Is Visible    ${locator}    timeout=${timeout}
    Wait Until Element Is Enabled    ${locator}    timeout=${timeout}
    Scroll Element Into View Safely    ${locator}
    Select Checkbox    ${locator}

Wait And Uncheck
    [Documentation]    Waits until a checkbox is ready, then clears it.
    [Arguments]    ${locator}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Until Element Is Visible    ${locator}    timeout=${timeout}
    Wait Until Element Is Enabled    ${locator}    timeout=${timeout}
    Scroll Element Into View Safely    ${locator}
    Unselect Checkbox    ${locator}

Wait And Get Attribute
    [Documentation]    Waits until an element is ready and returns one of its attributes.
    [Arguments]    ${locator}    ${attribute}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Until Element Is Visible    ${locator}    timeout=${timeout}
    Wait Until Element Is Enabled    ${locator}    timeout=${timeout}
    Scroll Element Into View Safely    ${locator}
    ${value}=    Get Element Attribute    ${locator}    ${attribute}
    RETURN    ${value}

Wait And Verify Text
    [Documentation]    Waits until the expected text appears in the page or element.
    [Arguments]    ${locator}    ${expected}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Until Element Is Visible    ${locator}    timeout=${timeout}
    ${text}=    Get Text    ${locator}
    Should Contain    ${text}    ${expected}

Wait Until Element Is Gone
    [Documentation]    Waits until the element (e.g. a loading spinner or overlay) is
    ...    no longer visible before continuing. Opposite direction of the keywords above.
    [Arguments]    ${locator}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Until Element Is Not Visible    ${locator}    timeout=${timeout}

Logout From Application
    [Documentation]    Logs out of the application if a logout control is present.
    [Arguments]    ${logout_locator}=xpath=//a[contains(., 'Logout') or contains(., 'Log out') or contains(@id, 'logout') or contains(@class, 'logout')]    ${timeout}=${DEFAULT_TIMEOUT}
    ${status}=    Run Keyword And Return Status    Wait And Click Element    ${logout_locator}    ${timeout}
    Run Keyword If    not ${status}    Log    Logout control was not found or could not be clicked

Close Browser Session
    [Documentation]    Closes the current browser session safely.
    Close Browser

Cleanup After Run
    [Documentation]    Logs out if possible and closes the browser session.
    [Arguments]    ${logout_locator}=xpath=//a[contains(., 'Logout') or contains(., 'Log out') or contains(@id, 'logout') or contains(@class, 'logout')]    ${timeout}=${DEFAULT_TIMEOUT}
    Run Keyword And Ignore Error    Logout From Application    ${logout_locator}    ${timeout}
    Run Keyword And Ignore Error    Close Browser Session
