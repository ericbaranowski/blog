* * *

# Introducing Architect 4.0: faster, lighter, simpler serverless

[![Go to the profile of Ryan Block](https://cdn-images-1.medium.com/fit/c/100/100/0*onar9_4tbfLLtG9i.png)](https://blog.begin.com/@ryan?source=post_header_lockup)[Ryan Block](https://blog.begin.com/@ryan)<span class="followState js-followState" data-user-id="9a4924f9f7c1"><button class="button button--smallest u-noUserSelect button--withChrome u-baseColor--buttonNormal button--withHover button--unblock js-unblockButton u-marginLeft10 u-xs-hide" data-action="sign-up-prompt" data-sign-in-action="toggle-block-user" data-requires-token="true" data-redirect="https://blog.begin.com/introducing-architect-4-0-faster-lighter-simpler-serverless-59f6dc156bf2" data-action-source="post_header_lockup"><span class="button-label  button-defaultState">Blocked</span><span class="button-label button-hoverState">Unblock</span></button><button class="button button--primary button--smallest button--dark u-noUserSelect button--withChrome u-accentColor--buttonDark button--follow js-followButton u-marginLeft10 u-xs-hide" data-action="sign-up-prompt" data-sign-in-action="toggle-subscribe-user" data-requires-token="true" data-redirect="https://medium.com/_/subscribe/user/9a4924f9f7c1" data-action-source="post_header_lockup-9a4924f9f7c1-------------------------follow_byline"><span class="button-label  button-defaultState js-buttonLabel">Follow</span><span class="button-label button-activeState">Following</span></button></span><time datetime="2018-10-23T11:01:02.918Z">Oct 23, 2018</time><span class="middotDivider u-fontSize12"></span><span class="readingTime" title="5 min read"></span>

> Less, but better.

![](https://cdn-images-1.medium.com/max/1600/0*L0F6Agk2DALLKaYF)“white rods illustration” by [Pierre Châtel-Innocenti](https://unsplash.com/@chatelp?utm_source=medium&utm_medium=referral)

We’ve been listening to your feedback and today we’re extremely excited to introduce [Architect 4.0 (Yeti)](#90ef), the **fastest, simplest, most powerful way to build serverless applications**.

[✨ Skip to the part where you create a serverless app with Architect in 30s](#90ef)

#### About Architect

Architect is a fast, lightweight, open source, zero-config serverless framework for AWS focused on a **frictionless developer experience**.

Architect apps are composed of **many small, individual, fully isolated cloud functions**, which confers some pretty nice characteristics: better security, separation of concerns, fast and surgical deployments of **single functions_,_**and parallelized, globally available deployment of your entire application in just seconds. As a result, development time, deploying, runtime, and latency are all incredibly fast.

Architect has been downloaded over 45,000 times since joining the JS Foundation last year. (Architect is also the open core of [our serverless application hosting platform, Begin](https://begin.com).)

#### **4.0 is the best Architect yet.** Let’s see what’s new! 🎉

*   [**[new]** Generic HTTP (](#0520)`[@http](#0520)`[) functions](#0520)
*   [**[new]** Frontend-friendly](#3f84) `[public](#3f84)` [folder for static assets+ S3 sync](#3f84)
*   [**[new]** JSON + YAML Architect manifest support](#ee88)
*   [**[new]** Add memory, CPU, & processing time with per-function configurations](#8874)
*   [**[new]** Even better security with per-function IAM roles](#6107)
*   [**[improved]** Simpler package name (](#6de0)`[npm i @architect/architect](#6de0)`[)](#6de0)
*   **[improved]** New GitHub 🌟 [https://github.com/arc-repos/architect](https://github.com/arc-repos/architect)
*   **[improved]** Smarter rate-limiting for deployments of large projects
*   **[improved]** Complete docs revamp with new sample projects at [arc.codes](https://arc.codes)

* * *

### What’s new in 4.0 (Yeti)

#### HTTP Functions

With Architect 4.0 `@[http](https://arc.codes/guides/http)` functions you can now respond to web requests with **any** HTTP _method_,`Content-Type`, or`Status Code`.

Even better, `@[http](https://arc.codes/guides/http)` functions have no dependencies by default, so they’re even lighter and faster than ever before.

Web servers aren’t standards — but HTTP is, and these tiny functions are a very pure and easy to work with abstraction of HTTP.

**Examples** Let’s look at an example function defined in the following `.arc` file under the `@http` pragma:

<pre name="57b7" id="57b7" class="graf graf--pre graf-after--p">@app
superfun</pre>

<pre name="c68b" id="c68b" class="graf graf--pre graf-after--pre">@http
get /</pre>

The generated code for `get /` is terse, easy to reason about, and has no dependencies:

![](https://cdn-images-1.medium.com/max/1600/1*sxDfRUaswgO-LwC3jQHMkA.png)

> HTTP functions support responding with: `status`,`type`, `body`, `cors`, `location` , and `cookie` 🍪

We think this is a pretty big deal for how using cloud functions will be used to develop sites, web apps, APIs, and a whole lot more.

> 🔬Read more in the [Architect HTTP Functions Guide](https://arc.codes/guides/http)

* * *

#### Frontend-friendly `public` folder for static assets workflows + S3 sync

Front-end workflows like bundling and transpiling are super important to modern application developers, so we went back to the drawing board and re-thought how we could better enable folks to manage and ship assets within their Architect projects.

With Architect 4.0, common workflows — from Webpack, to Babel, to Typescript–are now possible with minimal configuration. Just point your scripts at the new `public` folder, and Architect will automatically syncs its contents to the S3 buckets you’ve specified in your project’s`@[static](https://arc.codes/reference/static)` pragma.

Add any (compiled) JS and CSS, images, gifs, binary dists, or other files you want to publish, and they’ll deploy to the appropriate S3 bucket whenever you deploy your project with `npx deploy`.

> 🎨 Read more in the [Architect Static Assets Guide](https://arc.codes/guides/static-assets)

* * *

#### JSON + YAML Architect manifest support

Architect’s `.arc` project manifest format is terse, easy to learn, and expressive syntax. We also heard that folks coming on board wanted to author in classical configuration formats like [YAML and JSON](https://arc.codes/guides/yaml-and-json), too — so now you can in Architect 4.0!

* * *

#### Add memory, CPU, & processing time with per-function configurations

Architect provisions cloud functions with sensible and affordable defaults. But sometimes you need to crank up a Lambda’s processing time, or available memory (which is also a proxy configuration for CPU power).

Architect 4.0 supports this by dropping a `.arc-config` file into the directory of any function you wish to configure. An example configuration file looks like this:

<pre name="8857" id="8857" class="graf graf--pre graf-after--p"># src/http/get-index/.arc-config
@aws
timeout 30000   # timeout in seconds
memory  512     # 64MB increments from 128MB to 3008MB</pre>

Then, just run `npx config apply` to instantly update your Lambdas’ configurations.

* * *

#### Even better security with per-function IAM roles

A request we commonly heard from large enterprises and companies with strict compliance requirements was for Architect to support custom IAM roles, defined per-Lambda.

As applications grow in complexity, ensuring they conform to the principle of least privilege becomes increasingly important, so managing roles for your functions should fast and simple.

In the directory of any Lambda function, add a `role.json` file containing a `policies` array of IAM ARNs to attach. For example:

<pre name="12ff" id="12ff" class="graf graf--pre graf-after--p">// src/http/get-index/role.json
{
  "policies": [
    "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess", 
    "arn:aws:iam::aws:policy/AlexaForBusinessReadOnlyAccess"
  ]
}</pre>

Then, just run `npx audit apply` to instantly update your Lambdas’ IAM roles.

* * *

### Try out Architect in 30 seconds

Ready to give Architect a swing? **No AWS account required**, Architect runs locally and offline!

1\. Create a vanilla Node project:

<pre name="b74f" id="b74f" class="graf graf--pre graf-after--p">mkdir testapp && cd testapp && npm init --yes</pre>

2\. Install Architect:

<pre name="e877" id="e877" class="graf graf--pre graf-after--p">npm i @architect/architect</pre>

3\. Create a basic `.arc` file:

<pre name="072b" id="072b" class="graf graf--pre graf-after--p">@app
testapp</pre>

<pre name="9400" id="9400" class="graf graf--pre graf-after--pre">@http
get /</pre>

4\. Generate your project locally:

<pre name="d657" id="d657" class="graf graf--pre graf-after--p">ARC_LOCAL=1 npx create</pre>

5\. Fire up the Architect sandbox to preview your work:

<pre name="1bbf" id="1bbf" class="graf graf--pre graf-after--p">npx sandbox</pre>

Alternately, if using Windows, use these instructions:

<pre name="903c" id="903c" class="graf graf--pre graf-after--p graf--trailing">mkdir testapp
cd testapp
npm init --yes
npm i @architect/architect
  [follow step 3 above]
`$env:ARC_LOCAL = 1`
npx create
npx sandbox</pre>

* * *

#### Thanks + love 🌈

With this release, as always, we’d like to give a shout out to all the members of the community who’ve helped guide our development, file bugs, and provide feedback. We see you!

Of course, if you’re not too busy, we’d certainly [appreciate a ⭐️ on GitHub](https://github.com/arc-repos/architect).

![](https://cdn-images-1.medium.com/max/1600/1*vJjiJ0NPnmsAF5vg4dFPVw.png)