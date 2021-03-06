<!--
.. title: 0x02 travis + nikola
.. slug: travis-nikola
.. date: 2018-05-25 00:00:00 UTC
.. tags: travis,travis-ci,nikola
.. category: configure
.. link: 
.. description: How to use travis-ci to build Nikola static pages and deploy them on GitHub Pages.
.. type: text
-->

One has running Nikola. One stores all ones work on GitHub and hosts it on the GitHub Pages. Nice. But 
do I really need to push my changes to the repo, and when I'm ready, build static pages and push them 
to the `master`. And what if I'm not at my computer, what if I must change some typo. It would be 
nice if something could do this build and deploy the stuff for me.

That is why I invite...

<!-- TEASER_END -->

## Travis CI

What one needs to have to proceed? Travis account connected to the GitHub account. Choose repository 
with your site and change some settings. I checked *Build only if .travis.yml is present*, *Build 
pushed branches* and *Build pushed pull requests*. 

As the 'checkbox' says Travis will build only if *.travis.yml* is present. So add it to the repo! 
Travis should do 2 things: build static files and deploy them to master. The first part should look like:

```yml
language: python
cache: apt
sudo: false
addons:
  apt:
    packages:
    - language-pack-en-base
python:
- 3.6.5
branches:
  except:
  - master
install:
- pip install 'Nikola[extras]'==8.0.0.b2
script:
- nikola build 
```

First 9 lines: Nikola is written in python, it is why we need it in, at least, version 3. 
Travis should ignore any changes on master branch (he will do them himself after all), that's the 
reason for excepting branch master. First, we have to install Nikola using pip. I forced 
version 8.0.0.b2 for its built-in theme. By default, **pip** installs version 7 of Nikola. After all 
this 'work' there is time for build script: `nikola build`.

Ok, so now we have our site build. How deploy it on GitHub Pages? One could play with `nikola deploy` 
or a few `git` commands, but Travis has a deploy provider for that:

```yml
deploy:
    provider: pages
    skip-cleanup: true
    keep-history: true
    github-token: $GITHUB_TOKEN
    local-dir: output
    target-branch: master
    verbose: true
    repo: death-of-rats/death-of-rats.github.io
    on:
		branch: source
```

More information could be found at [TCI01](https://docs.travis-ci.com/user/deployment/pages/). 
I added `local-dir` to set what should be deployed and where (`repo` and `target-branch: master`). 
This operation should take place on *source* branch.

In GitHub *Settings > Developer settings > Personal access tokens* `Generate new token` for Travis. 
At [GH01](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) 
you can read what to do. This token insert in Travis settings Environment Variables and use it by 
*$VariableName*. 

Ok, now is the time to push changes and watch how Travis is building and deploying **Your** site.

Easy, I almost forget about that 4 hours of tries...

...**SQUEAK**!
