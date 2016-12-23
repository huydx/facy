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
// casperjs --ssl-protocol=tlsv1 --cookies-file=fb-cookies.txt --web-security=no --num-result-pages=3  facebook-news-feed.js
// casperjs --ssl-protocol=tlsv1 --cookies-file=fb-cookies.txt --web-security=no --email="myemail" --password="mypassword"  --num-result-pages=3  facebook-news-feed.js
// this fetches the facebook news feed and outputs an array of items in json format
//
//args:
//  --user-agent="Mozilla/5.0 (X11; Linux i686 on x86_64; rv:45.0) Gecko/20100101 Firefox/45.0)" //optional
//  --num-result-pages=n  //number of results to render per page.  the default is 1
//  --show-latest //shows latest stories
//  --web-security=no    //required for ajax to work properly for facebook videos
//  --newer-than=id  //page no futher than and send results newer than id.   this is the id not the unix_timestamp but data-timestamp, or just id
//  --prefs-folder="~" //sets the preference folder to store settings and cookies the default is ~ or the home directory
//
//returns as stdout: JSON array of objects of type item
// also produced: 
// facebook-ns-cookies.txt file containing web browser cookies in netscape format for purpose of an external app (e.g. mplayer, mpv)
//
//broken: comments, live video support, animated gifs from giphy
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
gprefs_folder = casper.cli.has("prefs-folder") ? casper.cli.get("prefs-folder") : "~";

casper.start(casper.cli.has("show-latest") ? 'https://www.facebook.com/?sk=h_chr' : 'https://www.facebook.com/?sk=h_nor',
    function() {;
    });

function getNewsFeed(newer_than) {
    var list = "";
    var items = [];
    $('div[id*="hyperfeed_story_id_"]').each(function(index) {
        var item = { //element of JSON array
            id: 0,
            info: ":feed",
            data: {
                type: "",
                user: "",
                user_next: "",
                user_location: "",
                food: "",
                content: "",
                comment: "",
                comment_sticker: "",
                comment_youtube: "",
                picture: "",
                video: "",
                app_name: "",
                link: "",
                link_post: "",
                like_count: 0,
                live_video_page: "",
                live_video_viewers: 0,
                likes: [],
                traveling_to: "",
                traveling_from: "",
                comments_count: 0,
                event_name: "",
                event_date: "",
                react_scores: "",
                react_url: "",
                reaction: "",
                view_count: "",
                share_count: ""
            },
            time_unix: 0,
            date_full: "",
            date: 0 //in facebook time ISO 8601 2013-01-25T00:11:02+0000
        };

        var id = "";
        var name = "";
        var content = "";
        var comment = "";
        var comment_sticker = "";
        var comment_youtube = "";
        var user = "";
        var date_full = "";
        var picture = "";
        var live_video_page = "";
        var live_video_viewers = 0;
        var video = "";
        var traveling_to = "";
        var traveling_from = "";
        var like_count = 0;
        var likes = [];
        var comments_count = 0;
        var event_name = "";
        var event_date = "";
        var food = "";
        var user_location = "";
        var user_next = "";
        var view_count = 0;
        var share_count = 0;
        var react_scores = "";
        var react_url = "";
        var reaction = "";
        var app_name = "";
        var link_post = "";
        var time_unix = 0;
        var type = "";
        var event_name = "";
        var event_date = "";
        var link = "";

        id = $(this).attr("data-timestamp");
        name = $("h5", this).text();
        content = $(".userContent", this).text() || "";
        user = $(".fwb a", this).first().text();
        date_full = $(".timestamp", this).text();

        t = $('.mtm .img', this);
        if (t.length > 0) {
            picture = t.attr("src") || "";
        }

        comments_count = parseInt($('.ipm', this).text()) || 0;

        t = $('._4arz', this);
        if (t.length > 0) {
            t = $('._4arz', this).text().trim();

            if (t.indexOf(' others') != 1)
                likes = t.replace(/ and [0-9A-Z.]+ others/g, "");
            else
                likes = t;

            if (!likes.match(/[a-zA-Z]+/i))
                likes = [];
            else {
                likes = likes.replace(/ and /g, ",");
                likes = likes.replace(/[ ]*,[ ]*/, ",")
                likes = likes.split(',');
            }
        }

        $('._ipm', this).each(function() {
            t = $(this).text();
            if (t.indexOf('Views') != -1)
                view_count = parseInt(t);
            else if (t.indexOf('Shares') != -1)
                share_count = parseInt(t);
            else if (t.indexOf('Comments') != -1)
                comments_count = parseInt(t);
        });

        //english supported only... wrap in array to support other languages
        var t = $("h5", this).text();
        if (t.indexOf("interested in an event") != -1) {
            type = "interested_in_event";
            event_name = $("._fwx", this).text();
            event_date = $(".eventTime", this).text();
        } else if (t.indexOf("liked") != -1) {
            type = "liked"; //post
        } else if (t.indexOf("likes") != -1) {
            type = "likes"; //interest or fanpage
            t = $('.uiStreamSponsoredLink', this);
            if (t.length > 0) {
                type = "commercial_ad_endorsed"
            }
            user_next = $('.fwb', this).next().text();
        } else if (t.indexOf("shared") != -1 && t.indexOf("event") != -1) {
					  if (t.indexOf("to the group") != -1) {
                type = "shared_group_event";
                user_next = $(".fwb", this).next().next().next().text();
            } else {
                type = "shared_event"
                user_next = $(".fwb", this).next().text();
            }
            event_name = $("._fwx", this).text();
            event_date = $(".eventTime", this).text();
        } else if (t.indexOf("shared") != -1 && t.indexOf("video") != -1) {
            type = "video";
            if (t.indexOf("live video") != -1) {
                type = "shared_live_video";
            }
        } else if (t.indexOf("is live now") != -1) {
            type = "video_live_now";
        } else if (t.indexOf("was live") != -1) {
            type = "video_was_live";
        } else if (t.indexOf("shared") != -1 && t.indexOf("link") != -1) {
            type = "link";
        } else if (t.indexOf("commented") != -1 || t.indexOf("replied") != -1) {
					  if (t.indexOf("commented") != -1)
               type = "commented";
            else if (t.indexOf("replied") != -1)
               type = "replied";
            t = $('.UFICommentActorName :contains("' + user + '")', this);
            if (t.length > 0) {
                if (t.text().indexOf(user) != -1) {
                    content = $(".mtm", this).text();
                    //we need an casperjs-ajax wait for resource check.  it currently broken but it should work.
                    //the debug picture shows that it is not being displayed which could be caused by timeout bug or premature evaluation.
                    comment = t.parent().next().text();
                    t = t.parent().siblings("[aria-label*='sticker']");
                    if (t.length > 0) {
                        comment_sticker = t.css("background-image");
                        comment_sticker = comment_sticker.replace('url(').replace(')');
                        type = "commented_with_image"
                    }
                    t = t.parent().siblings(".mbs a[href*='://youtu.be']");
                    if (t.length > 0) {
                        comment_youtube = t.attr('href');
                        type = "commented_with_video"
                    }
                }
            }
        } else if (t.indexOf("added") != -1 && t.indexOf("photo") != -1) {
            type = "photo"; //photos
        } else if (t.indexOf("updated their cover photo") != -1) {
            type = "cover_photo"; //photos
        } else if (t.indexOf("updated") != -1 && t.indexOf("profile picture") != -1) {
            type = "profile_pic"; //photos
        } else if (t.indexOf("shared") != -1 && t.indexOf("post") != -1) {
            type = "shared_textual_post";
            user_next = $('.fwb', this).next().text();
        } else if (t.indexOf(" with ") != -1) {
            type = "dating";
            user_next = $('.fwb', this).next().text();
            if (t.indexOf(" at ")) { //name1 with name2 at place
                type = "dating_at";
                user_location = $('.fwb', this).next().next().text();
            }
        } else if (t.indexOf(" at ") != -1 || t.indexOf(" checked in ") != -1) {
            type = "checkin";
            user_location = $("._51mq", this).next().text();
        } else if (t.indexOf(" payment ") != -1) {
            type = "payment";
            user_next = $(".fwb a", this).next().text();
        } else if (t.indexOf(" mentioned ") != -1) {
            type = "mentioned";
        } else if (t.indexOf(" reacted ") != -1) {
            type = "reacted"; //emoji
            react_url = "https://www.facebook.com" + $("._3emk:first", this).attr("href");
        } else if (t.indexOf(" tagged ") != -1) {
            type = "tagged";
        } else if (t.indexOf(" Birthday") != -1) {
            type = "birthday";
        } else if (t.indexOf("shared a memory") != -1) {
            type = "memory";
        } else if (t.indexOf(" watching ") != -1) {
            type = "watching_movie";
            user_next = $('.fwb', this).next().next().text();
            try {
                user_location = $('.fwb', this).next().next().next().next().text();
            } catch (e) {;
            }
        } else if (t.indexOf(" traveling ") != -1) {
            type = "traveling";
            traveling_to = $('.fwb', this).next().next().text();
            traveling_from = $('.fwb', this).next().next().next().next().text();
        } else if (t.indexOf(" eating ") != -1) {
            type = "eating";
            food = $("._51mq", this).next().text();
            user_location = $("._51mq", this).next().next().text(); //test
        } else if (t.indexOf("now_friends") != -1) {
            type = "now_friends";
            user_next = $(".fwb a", this).next().text();
        } else {
            type = "status"
        }

        if ($(this).text().indexOf("Suggested Post") != -1) {
            type = "commercial_ad";
        }

        if (type == "video_live_now" || type == "shared_live_video") {
            if ($('._5pf0', this).length > 0) {
                t = $('._5pf0', this).text();
                if (t.indexOf('LIVE')) {
                    //Still live
                }
            }
            live_video_viewers = parseInt($('._5jnq', this).attr('data-store'));
        }

        t = $('a[onclick*="LinkshimAsyncLink"]', this);
        if (t.length > 0) {
            link = $(t).attr('href');
        } else {
            link = "";
        }

        t = $('._5pcq', this);
        if (t.length > 0) {
            t = t.attr('href');
            link_post = t;
            if (type == "video_live_now") {
                live_video_page = t;
            }
        }
        t = $('.uiStreamSponsoredLink', this);
        if (t.length > 0) {
            if (type == "status") {
                type = "commercial_ad"
            }
            //link_post = t.attr('href');
            link_post = $('.mtm a', this).attr('href');
            link = link_post;
        }
        if (link_post.length > 0) {
            if (link_post.charAt(0) == '/') {
                link_post = "https://www.facebook.com" + link_post;
            } else if (link_post.charAt(0) == 'h') {;
            } else if (link_post.charAt(0) == '#') {
                link_post = "";
            } else {
                link_post = "";
            }
        }

        t = $('.mtm a', this);
        if (t.length > 0) {
            url = t.attr('href');
            if (url.indexOf("youtube.com") != -1) {
                if (type.indexOf("status") != -1)
                    type = "video";
                if (type == "commercial_ad")
                    type = "commercial_ad_video";
                video = url;
            }
        }

        t = $('._20y0', this);
        if (t.length > 0) {
            t = t.attr('data-appname') || "";
            app_name = t;
        } else {
            app_name = "";
        }

        //phantomjs doesn't handle Facebook's BigPipe properly for some reason fetch the mobile site
        //the problem is in qtwebkit
        //we still can get the mobile version
        //it was possible in the past to obtain the higher quality video and images though elinks.  just sayin.
        t = $('video', this);
        if (t.length > 0 || type.indexOf("video_was_live") != -1) {

            turl = link_post;
            turl = turl.replace("www.facebook", "m.facebook");
            if (turl.indexOf("ads/about") != -1) {
                turl = "";
            }
            video = turl;
            if (type == "status") {
                type = "video";
            }
            if (type == "commercial_ad") {
                type = "commercial_ad_video";
            }
            //video=$('video',this).attr('src') || "";
            //if (video.indexOf('mediasource:') != -1) {
            //	video=video.split('mediasource:')[1];
            //}
            //video=video || "";

            t = $('.mtm ._3chq', this);
            if (t.length > 0) {
                picture = t.attr("src") || "";
            }
        }

        //doesn't work for media.giphy.com in phantomjs because bigpipe or phantomjs is not working properly.
        t = $('._30h', this); //html label 
        if (t.length > 0) {
            //animated gif
            if (t.indexOf("media.giphy.com") != -1) {
                video = link_post;
            }
        }


        time_unix = $(".timestamp", this);
        if (time_unix.length > 0) {
            time_unix = time_unix.attr("data-utime");
        } else {
            time_unix = 0;
        }

        t = $(".img + a.profileLink", this);
        if (t.length > 0)
            user_location = t.text();

        $('._3emk', this).each(function() {
            t = $(this).attr('aria-label');
            if (t.indexOf("Like") != -1)
                like_count = parseInt(t);
            react_scores = react_scores + t + "; ";
        });

        if (app_name == "Spotify") {
            link = $('.mtm a', this).attr('href');
        }


        var t = $("h5", this).text();
        if (t.indexOf("shared") != -1 && t.indexOf("link") != -1) {
            t = $(".mbs a[href*='youtu.be']", this);
            if (t.length > 0) {
                link = t.attr('href');
                video = link;
            }
            t = $(".mbs a[href*='youtu.be']", this);
            if (t.length > 0) {
                link = t.attr('href');
                video = link;
            }
        }

        //data structure
        //derived from observation
        item.id = id;
        item.info = ":feed";
        item.data.type = type;
        item.data.user = user;
        item.data.user_next = user_next;
        item.data.user_location = user_location;
        item.data.food = food;
        item.data.content = content;
        item.data.comment = comment;
        item.data.comment_sticker = comment_sticker;
        item.data.comment_youtube = comment_youtube;
        item.data.picture = picture;
        item.data.video = video;
        item.data.app_name = app_name;
        item.data.live_video_page = live_video_page;
        item.data.live_video_viewers = live_video_viewers;
        item.data.link = link;
        item.data.link_post = link_post;
        item.data.like_count = like_count;
        item.data.likes = likes;
        item.data.traveling_to = traveling_to;
        item.data.traveling_from = traveling_from;
        item.data.react_scores = react_scores;
        item.data.react_url = react_url;
        item.data.reaction = reaction;
        item.data.view_count = view_count;
        item.data.share_count = share_count;
        item.data.comments_count = comments_count;
        item.data.event_name = event_name;
        item.data.event_date = event_date;
        item.time_unix = time_unix; //unix timestamp
        item.date_full = date_full; //in english
        item.date = new Date(time_unix * 1000).toISOString(); //in facebook time ISO 8601
        if (item.data.user.length > 0 && id > newer_than)
            items.push(item);
    });
    return items;
}

function getNextNews(newer_than) {
    if ($('._38my').length > 0)
        return;

    t = $('div[id*="hyperfeed_story_id_"]:last');
    if (t.length > 0) {
        t = t.attr("data-timestamp");
        if (t > newer_than) {
            $(':contains("More Stories")').click();
        }
    }
}

function getVideoUrl(fbPage) {
    if (fbPage.charAt(0) == 'h') {
        if (fbPage.indexOf("youtube.com") != -1)
            return fbPage;
        xmlhttp = new XMLHttpRequest();
        xmlhttp.open("GET", fbPage, false);
        xmlhttp.send();
        var data = xmlhttp.responseText;
        t = $(data).find("a[href*='video_redirect']").attr('href');
        if (t != undefined) {
            url = "https://www.facebook.com" + t;
            url = url.replace("https://www.facebook.com/video_redirect/?src=", "");
            url = decodeURIComponent(url);
        } else {
            url = "";
        }
        return url;
    }
}

function getReaction(name, fbPage) {
    if (fbPage.charAt(0) == 'h') {
        xmlhttp = new XMLHttpRequest();
        xmlhttp.open("GET", fbPage, false);
        xmlhttp.send();
        var data = xmlhttp.responseText;
        reaction = "";
        t = $(data).find(":contains('" + name + "')");
        if (t.length > 0) {
            alert("reaction found");
            reaction = t.closest("._5i_p").siblings("._3p56").text();
        } else {
            reaction = "";
        }
        return reaction;
    }
}

casper.waitForSelector("form#login_form", function() {
    this.fill('form#login_form', {
        email: casper.cli.get("email"),
        pass: casper.cli.get("password")
    }, true);
}, function() {
    //may already be logged on or failed attempt
});

gi = 0;
gn = 1;

function isDone() {
    return gi == gn /*|| !casper.exists('.async_saving')*/ ;
}

casper.waitForSelector('.fbxWelcomeBoxSmallRow', function() {
    var n = 1;
    if (casper.cli.has("num-result-pages")) {
        n = parseInt(casper.cli.get("num-result-pages"));
    } else {
        n = 1;
    }
    gn = n;
    delay = 100;
    newer_than = casper.cli.has("newer-than") ? parseInt(casper.cli.get("newer-than")) : 0;
    for (i = 0; i < n; i++) {
        this.waitForSelector(".async_saving", function then() { //incomplete panel
            ;
        }, function onTimeout() {;
        }, delay);
        this.waitWhileSelector(".async_saving", function() { //fully rendered
            this.evaluate(getNextNews, newer_than);
            gi = gi + 1;
        });
    }
    this.waitFor(isDone, function then() {
            this.waitForSelector(".async_saving", function then() { //incomplete panel
                ;
            }, function onTimeout() {;
            }, 3000);
            this.evaluate(getNextNews);
            var out = this.evaluate(getNewsFeed, newer_than);

            //convert mobile video urls to the actual video
            for (i = 0; i < out.length; i++) {
                var newUrl = this.evaluate(getVideoUrl, out[i].data['video']) || "";
                out[i].data['video'] = newUrl;
            }

            //find the specific reaction
            for (i = 0; i < out.length; i++) {
                var reaction = this.evaluate(getReaction, out[i].data['user'], out[i].data['react_url']) || "";
                out[i].data['reaction'] = reaction;
            }

            this.echo(JSON.stringify(out));
            //casper.capture("Debug.png");
        }, function onTimeout() {;
        },
        3 * 1000 * n);

    cookieFilename = gprefs_folder+"/facebook-ns-cookies.txt";
    var fs = require('fs');
    var cookies = phantom.cookies;
    cookiejar = "";
    for (i = 0; i < phantom.cookies.length; i++) {
        cookie = cookies[i];
        var local = "FALSE";
        if (cookie.domain.charAt(0) == '.') {
            local = "TRUE";
        } else {
            local = "FALSE";
        }
        var expires = 0;
        if (cookie.expiry == undefined) {
            expires = 0;
        } else {
            expires = cookie.expiry;
        }
        cookiejar += cookie.domain + "\t" + local + "\t" + cookie.path + "\t" + String(cookie.httponly).toUpperCase() + "\t" + expires + "\t" + cookie.name + "\t" + cookie.value + "\r\n";
    }
    fs.write(cookieFilename, cookiejar, 644);
});

casper.run();
