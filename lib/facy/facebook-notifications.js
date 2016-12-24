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
// casperjs --ssl-protocol=tlsv1 --cookies-file=fb-cookies.txt --num-result-pages=3  facebook-notifications.js
// casperjs --ssl-protocol=tlsv1 --cookies-file=fb-cookies.txt --num-result-pages=3 --email="myemail" --password="mypassword"   facebook-notifications.js
// this fetches the facebook news feed and outputs an array of items in json format
//
//args:
//  --user-agent="Mozilla/5.0 (X11; Linux i686 on x86_64; rv:45.0) Gecko/20100101 Firefox/45.0)" //optional
//  --num-result-pages=n number of results to render per page.  the default is 1.
//  --unread-only show unread results  it will show seen notifications if you omit this.
//  --newer-than=unix_timestamp  #page no futher than and send results newer than
//
//returns as stdout: JSON array of objects of item.
//
var casper = require('casper').create({
    //verbose: true,
    //logLevel: 'debug',
    viewportSize: {
        width: 1440,
        height: 900
    },
    clientScripts: ["jquery-3.1.1.min.js"],
});

casper.userAgent(casper.cli.has("user-agent") ? casper.cli.get("user-agent") : 'Mozilla/5.0 (X11; Linux i686 on x86_64; rv:45.0) Gecko/20100101 Firefox/45.0)');

casper.start('https://www.facebook.com/login.php', function() {;
});

function getAllNotifications(new_only, newer_than) {
    var items = [];
    $("._33c").each(function(index) {
        var item = { //element of JSON array
            id: 0,
            info: ":notification",
            data: {
                user: "",
                content: "",
                emoji: "",
                link: ""
            },
            is_new: 0,
            time_unix: 0,
            date_full: "",
            date: "" //in facebook time ISO 8601 2013-01-25T00:11:02+0000
        }

        var id = $(this).attr('data-alert-id');

        var user = $(".fwb", this).text() || "Facebook (System Message)";
        var content = $(".fwb", this).next().text();

        if (content.length == 0) {
            content = $('._4l_v', this).first().text();
        }

        var notification = $(this).text();

        var is_new = $(this).hasClass('jewelItemNew');

        var date_full = $(".livetimestamp", this).attr('title');
        var time_unix = $(".livetimestamp", this).attr('data-utime');
        var link = $('._1_0e', this).attr('href');

        var emoji = "unknown";
        t = $('._33f .img', this).attr('src');
        if (t.indexOf('RvGKklgAefT.png') != -1) { // love
            emoji = "love";
        } else if (t.indexOf('6WffvhOaXGY.png') != -1) { // like
            emoji = "like";
        } else if (t.indexOf('McJA2ZjdJmf.png') != -1) { // haha
            emoji = "haha";
        } else if (t.indexOf('IfsimazVjj4.png') != -1) { // wow
            emoji = "wow";
        } else if (t.indexOf('jOeSrGlcPLG.png') != -1) { // sad
            emoji = "sad";
        } else if (t.indexOf('IfsimazVjj4.png') != -1) { // angry
            emoji = "angry";
        } else if (t.indexOf('nD_HSnRPA76.png') != -1) { // wrench
            emoji = "wrench";
        } else if (t.indexOf('B0Z3i_lBjP9.png') != -1) { // calendar
            emoji = "calendar";
        } else if (t.indexOf('KgMjNNPJc5W.png') != -1) { // commented
            emoji = "commented";
        } else if (t.indexOf('LZiIcH_lPU4.png') != -1 // facebook small
            ||
            t.indexOf('15016652_335963966759984_6731790688729432064_n.png') != -1) { // facebook a little bigger
            emoji = "facebook";
        } else if (t.indexOf('C8K1hbkDbLf.png') != -1) { // page new message
            emoji = "page_new_message";
        } else if (t.indexOf('tGcqnFvIJx5.png') != -1) { // bug
            emoji = "bug";
        } else if (t.indexOf('bMvB85s1gHp.png') != -1) { // bookedmarked
            emoji = "bookmarked";
        } else if (t.indexOf('HzXvwXTq5yZ.png') != -1) { // added photo
            emoji = "photo";
        } else if (t.indexOf('iq29lNS3VHY.png') != -1) { //star friend didn't post for a while
            emoji = "star"
        } else {
            emoji = "unknown"; //not discovered yet
        }

        //data structure
        //derived from observation
        item.id = id; //id
        item.info = ":notification"; //info
        item.data.user = user; //user
        item.data.content = content; //content
        //data
        item.data.link = link; //link
        item.data.emoji = emoji; //emoji
        item.date = new Date(time_unix * 1000).toISOString(); //date in facebook time ISO 8601
        item.date_full = date_full;
        item.time_unix = time_unix;
        item.is_new = is_new;
        if (new_only) {
            if (time_unix > newer_than && is_new)
                items.push(item);
        } else {
            if (time_unix > newer_than)
                items.push(item);
        }
    });
    return items;
}

casper.waitForSelector("form#login_form", function() {
    this.fill('form#login_form', {
        email: casper.cli.get("email"),
        pass: casper.cli.get("password")
    }, true);
}, function() {; //may already be logged on or failed attempt
});


function isDone() { //1 means stop waiting
    t = this.getElementsInfo("._33c .livetimestamp");
    time_unix = 0;
    if (t.length > 0) {
        t = t[t.length - 1]
        time_unix = t['attributes']['data-utime'];
    } else {
        return 1;
    }
    return time_unix <= (casper.cli.has("newer-than") ? casper.cli.get("newer-than") : 0);
}

function checkNotificationPageLoaded() {
    return this.evaluate(function() {
        return document.getElementsByClassName('uiHeaderTitle')[0].textContent.indexOf('Your Notifications');
    });
}

casper.waitForSelector('.fbxWelcomeBoxSmallRow', function() {
    casper.open('https://www.facebook.com/notifications').then(function() {
        casper.waitFor(checkNotificationPageLoaded, function then() {
            var n = 1;
            if (casper.cli.has("num-result-pages")) {
                n = parseInt(casper.cli.get("num-result-pages"));
            } else {
                n = 1;
            }

            this.viewport(1440, 900 * n).then(function() {;
            });

            this.waitForSelector("._44_t", function then() {;
            }, function onTimeout() {;
            }, 3 * 1000 * n);

            //no event driven way to determine if list is done. it shows same indicator.
            newer_than = casper.cli.has("newer-than") ? parseInt(casper.cli.get("newer-than")) : 0;
            unread_only = casper.cli.has("unread-only");
            this.waitFor(isDone, function then() {
                this.scrollToBottom();
                var out = this.evaluate(getAllNotifications, unread_only, newer_than);
                this.echo(JSON.stringify(out));
            }, function onTimeout() {
                var out = this.evaluate(getAllNotifications, unread_only, newer_than);
                this.echo(JSON.stringify(out));
            });
        }, function onTimeout() {;
        });
    });
});

casper.run();
