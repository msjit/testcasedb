# TestCaseDB

TestCaseDB is a test case management application built on Ruby on Rails.

More details can be found at http://www.testcasedb.com/ and in the manual.

## Development Install

TestCaseDB supports Ruby 1.9.3 and 2.0.0.

To get your system up and running run the install script 'script/setup'.

You can now start the server with 'rails s' and login with the user admin/ChangeMe.

To add demo data to your system run 'rake install:demo'.

To add a larger data set run 'rake install:largedemo'.

## Production Install

Detailed install instructions are available in the documentation and in the doc folder. Download the latest guide at http://www.testcasedb.com/download.php.

## Enable Google OAuth

To utilize Google's OAuth you need to follow a few steps.

1. Create a new app in Google's Developer Console
  * Visit https://console.developers.google.com/
  * Create a new project to use for your application
  
2. Open the new project

3. Under credentials, click Create new Client ID
  * Fill in the required fields.
  * For the Redirect URI set it to <yourhost>/auth/google_oauth2/callback
  * Set javascript origins to <yourhost>
  * Copy the Client ID and secret

4. On APIs tab, enable the following APIs
  * Contacts API
  * Google+ API
  
5. Login to TCDB as an admin and open the settings page
  * Enable Google OAuth
  * Set the Google client id and secrets
  
6. Restart your server
  * If you're using Passenger, simply add the file restart.txt to <application_location>/tmp/
  * Otherwise, you can restart your webserver

** Notes **
- New users will not be automatically created. You must create them in TCDB first.
- The first time a user logs in with Google, if their google email matches the email address on their TCDB account, they will be linked automatically.