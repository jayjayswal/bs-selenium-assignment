#!/bin/bash

SELENIUM_SERVER_PATH="http://localhost:4444"

CheckLastCommandStatus() {
    retVal=$?
    if [ $retVal -ne 0 ]; then
        echo $1
        exit $retVal
    fi
    if [ -n "$2" ]; then
        status=$(echo $2 | jq -r '.status')
        if [ $status -ne 0 ]; then
            echo $2
            exit 1
        fi
    fi
}

CheckPrerequisites() {
    which jq &>/dev/null
    CheckLastCommandStatus "'jq' is not installed, Please install and try again"
}

# checking prerequisites
CheckPrerequisites
# starting a session
RES=$(curl -sS --location --request POST $SELENIUM_SERVER_PATH'/wd/hub/session' \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "desiredCapabilities": {
            "browserName" : "chrome"
        }
    }')
CheckLastCommandStatus "Selenium failed to start session"
SELENIUM_SESSION_ID=$(echo $RES | jq -r '.sessionId')
# SELENIUM_SESSION_ID="c26992c29c2e81580e6d72f59ab84bb1"
CheckLastCommandStatus "Selenium session id not found"
echo "Selenium session ID:" $SELENIUM_SESSION_ID

#opning google in
RES=$(curl -sS --location --request POST $SELENIUM_SERVER_PATH'/wd/hub/session/'$SELENIUM_SESSION_ID'/url' \
--header 'Content-Type: application/json' \
--data-raw '{
    "url" : "https://www.google.com/"
}')
CheckLastCommandStatus "Cannot open google.com in session" "$RES"

#fetch input element
RES=$(curl -sS --location --request POST $SELENIUM_SERVER_PATH'/wd/hub/session/'$SELENIUM_SESSION_ID'/element' \
--header 'Content-Type: application/json' \
--data-raw '{
    "using" : "xpath",
    "value": "/html/body/div[1]/div[3]/form/div[1]/div[1]/div[1]/div/div[2]/input"
}')
CheckLastCommandStatus "Error in finding input element"
GOOGLE_TEXT_INPUT_ID=$(echo $RES | jq -r '.value | .["element-6066-11e4-a52e-4f735466cecf"]')
CheckLastCommandStatus "Error in finding input element id"
echo "google text input ID:" $GOOGLE_TEXT_INPUT_ID

#fetch submit button element
RES=$(curl -sS --location --request POST $SELENIUM_SERVER_PATH'/wd/hub/session/'$SELENIUM_SESSION_ID'/element' \
--header 'Content-Type: application/json' \
--data-raw '{
    "using" : "xpath",
    "value": "/html/body/div[1]/div[3]/form/div[1]/div[1]/div[3]/center/input[1]"
}')
CheckLastCommandStatus "Error in finding submit button element"
GOOGLE_SUBMIT_BUTTON_ID=$(echo $RES | jq -r '.value | .["element-6066-11e4-a52e-4f735466cecf"]')
CheckLastCommandStatus "Error in finding submit button element id"
echo "google submit button ID:" $GOOGLE_SUBMIT_BUTTON_ID

#enter name in input text
RES=$(curl -sS --location --request POST $SELENIUM_SERVER_PATH'/wd/hub/session/'$SELENIUM_SESSION_ID'/element/'$GOOGLE_TEXT_INPUT_ID'/value' \
--header 'Content-Type: application/json' \
--data-raw '{
    "value" : ["Jay Jayswal"]
}')
CheckLastCommandStatus "Error in entring name in input box"


#click submit button
RES=$(curl -sS --location --request POST $SELENIUM_SERVER_PATH'/wd/hub/session/'$SELENIUM_SESSION_ID'/element/'$GOOGLE_SUBMIT_BUTTON_ID'/click')
CheckLastCommandStatus "Error clicking submit button"

#fetch title of new page
RES=$(curl -sS --location --request GET $SELENIUM_SERVER_PATH'/wd/hub/session/'$SELENIUM_SESSION_ID'/title')
CheckLastCommandStatus "Error while fetching title"
PAGE_TITLE=$(echo $RES | jq -r '.value')
CheckLastCommandStatus "Error while fetching title from response"
echo "The title of page is:" $PAGE_TITLE

#delete session
RES=$(curl -sS --location --request DELETE $SELENIUM_SERVER_PATH'/wd/hub/session/'$SELENIUM_SESSION_ID'')
CheckLastCommandStatus "Error while deleting session"

