//
// The MIT License (MIT)
//
// Copyright (c) 2016 Orson Teodoro <orsonteodoro@yahoo.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
// TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
// OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//
// you need to fill out facebook-login.js for login information
// casperjs --ssl-protocol=tlsv1 --cookies-file=fb-cookies.txt --email="myemail" --password="mypassword" facebook-login.js
//
// args: --user-agent="Mozilla/5.0 (X11; Linux i686 on x86_64; rv:45.0) Gecko/20100101 Firefox/45.0)" //optional
//
// returns: true on login
//          false if not logged in
//
var casper = require('casper').create({
    viewportSize: {
        width: 1440,
        height: 900
    },
});

casper.userAgent(casper.cli.has("user-agent") ? casper.cli.get("user-agent") : 'Mozilla/5.0 (X11; Linux i686 on x86_64; rv:45.0) Gecko/20100101 Firefox/45.0)');

casper.start('https://www.facebook.com/login.php', function() {;
});

casper.waitForSelector("form#login_form", function() {
    this.fill('form#login_form', {
        email: casper.cli.get("email"),
        pass: casper.cli.get("password")
    }, true);
}, function() {
    //may already be logged on or failed attempt
});

casper.waitForSelector('.fbxWelcomeBoxSmallRow', function() {
    this.echo(JSON.stringify(true));
}, function() {
    this.echo(JSON.stringify(false));
});

casper.run();
