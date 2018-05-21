<!--
.. title: 0x01 github + nikola
.. slug: github-+-nikola
.. date: 2018-05-21 07:00:30 UTC
.. tags: git github nikola
.. category: configure
.. link: 
.. description: Configure GitHub-Pages with Nikola
.. type: text
-->

How to start GitHub repo for hosting pages with Nikola. I want a branch (let us name it `source`) where I will keep my project. I plan to generate static files to some folder and push it to the `master` branch. In other words `master` branch will have my site and `source` branch will have whole Nikola engine with my post source files.

I need to create new repo: *username.github.io* on GitHub page. Next clone it to local folder make my branch and push it.

```sh
git clone git@github.com:death-of-rats/death-of-rats.github.io.git
cd death-of-rats.github.io.git
git commit --allow-empty -am "start using repo"
git branch source
git checkout source
git push --set-upstream origin source
```

And here I have empty repo with 2 branches.

Now I init Nikola project in repo root folder (on branch `source`). Nikola will produce html files in `output` folder so I need after first test run split subtree for that foledr and push it to `master`:

```sh
git push origin `git subtree split --prefix output/ master`:master --force
```

Since now deploy command may look like:
```sh
git checkout source
git add -A
git commit -m "deploy" -S
git push origin source
git subtree push --prefix output/ origin master
```

What I've missed? I didn't add `.gitignore`...

...**PIP**!
