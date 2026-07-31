*** Settings ***
Library     SeleniumLibrary
Resource    ./popup_keywords.resource

*** Variables ***
${URL}      https://example.com
${BROWSER}  chrome

*** Test Cases ***
Example Flow With Popup Handling
    Open Browser    ${URL}    ${BROWSER}
    Handle Known Popups                        # mop up anything that appears on load

    Click Element    id:some-button
    Handle Known Popups                        # mop up anything that appeared after the click

    # If something's still blocking the page, hand it to the AI fallback:
    # it captures a screenshot, asks the AI for a category+xpath, CLICKS it
    # to dismiss the popup now, and only saves the xpath to popups.json if
    # that click actually worked.
    ${is_blocked}=    Run Keyword And Return Status
    ...    Element Should Be Visible    xpath://div[contains(@class,'modal')]
    IF    ${is_blocked}
        ${dismissed}=    Handle Unknown Popup With AI Fallback
        ...    notes=Blocked checkout flow after clicking some-button
        IF    not ${dismissed}
            Log    Could not auto-dismiss popup — check popup_screenshots/ for manual review.    WARN
        END
    END

    Close Browser

*** Keywords ***
Discover And Register New Popup Xpath
    [Documentation]    Manual/offline helper: once you've looked at a captured
    ...    screenshot (yourself or via an AI) and know the right xpath, call
    ...    this so it's picked up by future runs automatically. Passing the
    ...    same ${capture_id} from Handle Unknown Popup links the "resolved"
    ...    log entry back to the original screenshot/DOM capture.
    [Arguments]    ${category}    ${xpath}    ${capture_id}=${NONE}
    Add Popup Xpath    ${category}    ${xpath}
    ...    capture_id=${capture_id}    source=manual
