*** Settings ***
Documentation       Template robot main suite.

Library             RPA.JSON
Library             RPA.Dialogs
Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.Desktop
Library             String
Library             RPA.Excel.Files
Library             RPA.FileSystem
Library             Collections


*** Tasks ***
Minimal task
    ${dict}=    Load config file
    TRY
        Open QAD website    ${dict}
        Log in to the home page    ${dict}
        Navigate to quality orders
        Get orders data to a text file
        ${status}=    Get user input
        Get the count of orders according to the user input    ${status}
    EXCEPT    message
        Log    ERROR
    END


*** Keywords ***
Load config file
    ${Config}=    Load JSON from file    config.json
    ${url}=    Set Variable    ${Config}[url]
    ${username}=    Set Variable    ${Config}[username]
    ${password}=    set Variable    ${Config}[password]
    IF    ("${url}" != "None" and "${username}" != "None" and "${password}" != "None")
        ${dict}=    Create Dictionary
        ...    username=${username}
        ...    Password=${password}
        ...    url=${url}
        RETURN    ${dict}
        Log    ${dict}
    ELSE
        Add text    Config data is missing please update the config
        Run dialog    title=Failure
    END

Open QAD website
    [Arguments]    ${dict}
    Log    ${dict}[url]
    Open Available Browser    ${dict}[url]    browser_selection=chrome

Log in to the home page
    [Arguments]    ${dict}
    Input Text    username    ${dict}[username]
    Input Text    password    ${dict}[Password]
    Click Button    logInBtn

Navigate to quality orders
    Click Button When Visible    webshellMenu_menuSearchButton
    Sleep    2sec
    Input Text    webshellMenu_kAutoCompleteMenuSearch    Quality Orders
    Click Element When Visible    //*[@id="webshellMenu_kAutoCompleteMenuSearch_listbox"]/li[1]/a/div/div/span[1]
    Sleep    2s
    ${grid}=    Page Should Not Contain Element    //*[@id="qGridContent"]
    IF    ${grid}== True
        Log    navigated sucessfully
    ELSE
        Click Button When Visible    webshellMenu_menuSearchButton
        Sleep    2sec
        Input Text    webshellMenu_kAutoCompleteMenuSearch    Quality Orders
        Click Element When Visible    //*[@id="webshellMenu_kAutoCompleteMenuSearch_listbox"]/li[2]/a/div/div/span[1]
        Sleep    2s
    END

Get orders data to a text file
    ${iddt}=    Get Text    //*[@id="qGridContent"]
    Create File    orders.txt    overwrite=True
    Sleep    2s
    Append To File    orders.txt    ${iddt}
    RPA.Desktop.Press Keys    1
    RPA.Browser.Selenium.press keys    //*[@id="BrowsePageNav_recordsPerPage"]/span    ENTER
    ${range}=    Get Text    //*[@id="BrowsePageNav_recordsPerPage"]/span/span[1]
    Log    ${range}
    WHILE    "${range}" != "10"
        Click Element When Visible    //*[@id="BrowsePageNav_recordsPerPage"]/span
        RPA.Desktop.Press Keys    1
        RPA.Browser.Selenium.press keys    //*[@id="BrowsePageNav_recordsPerPage"]/span    ENTER
        ${range}=    Get Text    //*[@id="BrowsePageNav_recordsPerPage"]/span/span[1]
        Log    ${range}
    END
    Click Element    //*[@id="BrowsePageNav_next"]/span
    Sleep    3s
    ${iddt}=    Get Text    //*[@id="qGridContent"]
    Append To File    orders.txt    ${\n}${iddt}
    ${navigationpage}=    Get Text    //*[@id="BrowsePageNav_viewing"]
    ${navigationpage}=    Split String    ${navigationpage}    of
    ${firstnum}=    Split String    ${navigationpage}[0]1
    ${firstnum}=    Set Variable    ${firstnum}[1]
    ${secondnum}=    Set Variable    ${navigationpage}[1]
    TRY
        WHILE    "${firstnum}" != "${secondnum}"
            Click Element    //*[@id="BrowsePageNav_next"]/span
            Sleep    3s
            ${iddt}=    Get Text    //*[@id="qGridContent"]
            Append To File    orders.txt    ${\n}${iddt}
            ${navigationpage}=    Get Text    //*[@id="BrowsePageNav_viewing"]
            ${navigationpage}=    Split String    ${navigationpage}    of
            ${firstnum}=    Split String    ${navigationpage}[0]1
            ${firstnum}=    Set Variable    ${firstnum}[1]
            ${secondnum}=    Set Variable    ${navigationpage}[1]
            Log    ${firstnum}
            Log    ${secondnum}
        END
    EXCEPT
        Log    You have reached last orders
    END
    Close Browser

Get user input
    Add heading    please select required status
    Add drop-down    status    Closed,Canceled,Open
    ${status}=    Run dialog

    log    ${status}
    ${status}=    Set Variable    ${status}[status]
    Log    ${status}
    RETURN    ${status}

Get the count of orders according to the user input
    [Arguments]    ${status}
    ${inputdt}=    Read File    orders.txt
    ${inputdt}=    Split To Lines    ${inputdt}
    ${result}=    Set Variable    0
    FOR    ${element}    IN    @{inputdt}
        IF    "${status}" in "${element}"
            ${result}=    Evaluate    ${result}+1
        ELSE
            Log    message
        END
    END
    Log    ${result}
    Add text    Total number of ${status} orders are ${result}
    Run dialog
