# Contributing to the TOTP App

First off, thank you for considering contributing to the TOTP App! It's people like you that make the open source community such a great place.

## Where do I go from here?

If you've noticed a bug or have a feature request, [make one](https://github.com/fossindia/totp/issues/new)! It's generally best if you get confirmation of your bug or approval for your feature request this way before starting to code.

### Fork & create a branch

If this is something you think you can fix, then [fork the repository](https://github.com/fossindia/totp/fork) and create a branch with a descriptive name.

A good branch name would be (where issue #325 is the ticket you're working on):

```sh
git checkout -b 325-add-japanese-translations
```

### Get the code

```sh
git clone https://github.com/your-username/totp.git
cd totp
git checkout -b your-branch-name
```

### Implement your fix or feature

At this point, you're ready to make your changes! Feel free to ask for help; everyone is a beginner at first :smile_cat:

### Make a Pull Request

At this point, you should switch back to your master branch and make sure it's up to date with the latest upstream version of the code.

```sh
git remote add upstream git@github.com:fossindia/totp.git
git checkout master
git pull upstream master
```

Then update your feature branch from your local copy of master, and push it!

```sh
git checkout 325-add-japanese-translations
git rebase master
git push --force-with-lease origin 325-add-japanese-translations
```

Finally, go to GitHub and [make a Pull Request](https://github.com/fossindia/totp/compare) :D

## How to report a bug

When you file an issue, make sure to answer these five questions:

1. What version of the TOTP App are you using?
2. What operating system and processor architecture are you using?
3. What did you do?
4. What did you expect to see?
5. What did you see instead?

## How to suggest a feature or enhancement

If you find yourself wishing for a feature that doesn't exist in the TOTP App, you are probably not alone. There are bound to be others out there with similar needs. Open an issue on our issues list on GitHub which describes the feature you would like to see, why you need it, and how it should work.
