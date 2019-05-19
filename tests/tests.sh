#!/bin/bash

function dashboard_admin_login {
    # This function is used to login into django-admin
    # It creates the cookie.txt file that containes CSRF
    # token and session ID.
    touch $COOKIES
    $CURL_BIN $LOGIN_URL > /dev/null
    DJANGO_TOKEN="csrfmiddlewaretoken=$(grep csrftoken $COOKIES | \
                  sed 's/^.*csrftoken[[:blank:]]*//')"
    $CURL_BIN -d "$DJANGO_TOKEN;username=$USERNAME;password=$PASSWORD" \
              -X POST --dump-header - $LOGIN_URL | grep -q "302 Found" && \
              { echo "SUCCESS: Login request acknowledgement received!"; } || \
              { echo "ERROR: Login request acknowledgement not received!"; FAILURE=1; }
}

function run_dashboard_tests {
    # This tests the login was successful; being able to 
    # access this page also means redis is running.
    $CURL_BIN --head http://dashboard.openwisp.org/admin/ | grep -q "200 OK" && \
              { echo "SUCCESS: Admin login successful!"; } || \
              { echo "ERROR: Admin login failed!"; FAILURE=1; }
}

function init_dashoard_tests {
    LOGIN_URL=http://dashboard.openwisp.org/admin/login/
    USERNAME='admin'
    PASSWORD='admin'
    COOKIES=cookies.txt
    CURL_BIN="curl -s -c $COOKIES -b $COOKIES -e $LOGIN_URL"
    FAILURE=0
    # Check if openwisp-dashboard is reachable
    curl -s --head $LOGIN_URL  | grep -q "200 OK" && \
         { echo "SUCCESS: openwisp-dashboard login page reachable!"; } || \
         { echo "ERROR: openwisp-dashboard login page not reachable!"; FAILURE=1; }
    dashboard_admin_login # Login to django-admin
    run_dashboard_tests # Run CI tests
    rm $COOKIES # Delete cookies file created during testing
    exit $FAILURE
}
