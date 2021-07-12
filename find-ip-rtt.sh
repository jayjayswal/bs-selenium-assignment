#!/bin/bash

AUTOMATE_USERNAME="jayjayswal_D9npvR"
AUTOMATE_ACCESS_KEY="s9UoshQgmUN79dshsrLJ"

TEST_NAME="Default test name"
IP_CHECK=false

if [ -n "$1" ]; then
    TEST_NAME=$1
fi

if [ -n "$2" ] && [ $2 == '--browserstack' ]; then
    SELENIUM_SERVER_PATH="https://${AUTOMATE_USERNAME}:${AUTOMATE_ACCESS_KEY}@hub-cloud.browserstack.com"
    SELENIUM_CAPABILITIES="{
        \"desiredCapabilities\": {
            \"browserName\" : \"chrome\",
            \"os_version\" : \"Sierra\",
            \"resolution\" : \"1920x1080\",
            \"browser_version\" : \"65.0\",
            \"os\" : \"OS X\",
            \"name\" : \"$TEST_NAME\",
            \"build\" : \"Bstack Selenium assignment build 1\"
        }
    }"
    ELEMENT_ID_KEY="ELEMENT"
else
    SELENIUM_SERVER_PATH="http://localhost:4444"
    SELENIUM_CAPABILITIES="{
        \"desiredCapabilities\": {
            \"browserName\" : \"chrome\"
        }
    }"
    ELEMENT_ID_KEY="element-6066-11e4-a52e-4f735466cecf"
fi

if [ -n "$3" ] && [ $3 == '--ip-check' ]; then
    IP_CHECK=true
fi

IP_XPATH="/html/body/div[2]/div[2]/div/div/div/main/article/div[1]/div[1]/div[1]/div/div/ul/li[1]/a"

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
    --data-raw "$SELENIUM_CAPABILITIES"
    )
CheckLastCommandStatus "Selenium failed to start session"
SELENIUM_SESSION_ID=$(echo $RES | jq -r '.sessionId')
# SELENIUM_SESSION_ID="c26992c29c2e81580e6d72f59ab84bb1"
CheckLastCommandStatus "Selenium session id not found"
echo "Selenium session ID:" $SELENIUM_SESSION_ID

if [ "$IP_CHECK" = true ] ; then
    #opning whatismyip.com
    RES=$(curl -sS --location --request POST $SELENIUM_SERVER_PATH'/wd/hub/session/'$SELENIUM_SESSION_ID'/url' \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "url" : "https://www.whatismyip.com/"
    }')
    CheckLastCommandStatus "Cannot open whatismyipaddress.com in session" "$RES"

    #fetch ip text element
    RES=$(curl -sS --location --request POST $SELENIUM_SERVER_PATH'/wd/hub/session/'$SELENIUM_SESSION_ID'/element' \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "using" : "xpath",
        "value": "'$IP_XPATH'"
    }')
    CheckLastCommandStatus "Error in finding input element"
    IP_TEXT_ID=$(echo $RES | jq -r '.value | .["'$ELEMENT_ID_KEY'"]')
    CheckLastCommandStatus "Error in finding input element id"
    echo "ip text element ID:" $IP_TEXT_ID

    #fetch IP from site
    RES=$(curl -sS --location --request GET $SELENIUM_SERVER_PATH'/wd/hub/session/'$SELENIUM_SESSION_ID'/element/'$IP_TEXT_ID'/text')
    IP=$(echo $RES | jq -r '.value')
    CheckLastCommandStatus "Error in fetching IP"
    echo "IP address:" $IP

fi
echo "RTT:" 
RES=$(time $(curl -sS -o /dev/null --location --request GET $SELENIUM_SERVER_PATH'/wd/hub/session/'$SELENIUM_SESSION_ID'/url'))

#delete session
RES=$(curl -sS --location --request DELETE $SELENIUM_SERVER_PATH'/wd/hub/session/'$SELENIUM_SESSION_ID'')
CheckLastCommandStatus "Error while deleting session"
