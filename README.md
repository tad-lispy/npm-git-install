NPM Git Install
===============

Clones and (re)installs packages from remote git repos. It is meant as a temporary solution until [npm/npm#3055][3055] is resolved.

Install
-------

```sh
npm install --save npm-git-install
```

Use
---

In your `pacakge.json` add:

```javascript
{
  "scripts": {
    "install": "npm-git install"
  }
  "gitDependencies": {
    "private-package-name": "git@private.git.server:user/repo.git#revision",
    "public-package-name": "https://github.com/user/repo.git#revision"
  }
}
```

Obviously replace `*-package-name` and git URLs with values relevant to your project. URLs has to be in canonical form (i.e. one that you would provide to `git clone` on command line) - no fancy NPM shortcuts like "user/repo" or "bitbucket:user/repo". If you want this, I'm open for PR.

Why
---

IMO there is a serious defect in current versions of NPM regarding installation process of dependencies from git repositories. It basically prevents us from installing anything that needs a build step directly from git repos. Because of that some authors are keeping build artifacts in the repos, which I would consider a hurdle at best. Here is [relevant issue with ongoing discussion][3055].

### TL/DR:

If you `npm install ../some-local-directory/my-package` then npm will run `prepublish` script of the `my-package` and then install it in current project. This is fine.

One would expect that running `npm install git@remote-git-server:me/my-package.git` would also run `prepublish` before installing. Unfortunately it won't. Further more, it will apply `.npmignore`, which will most likely remove all your source files and make it hard to recover. Boo...

How
---

### From command line

```sh
npm-git install
```

This simple script will do the following for every `<url>` of `gitDependencies` section of `package.json`:

1.  Clone the repo it into temporary directory

    using `git clone <url>`.

1.  Run `npm install` in this directory

    which will trigger `prepublish` hook of the package being installed.

1.  then run `npm install <temporary directory>` in your project path.

In effect you will get your dependency properly installed.

Otionally it will use `git-shrinkwrap.json` file to lock your dependencies to a certain revision (i.e. a commit).

You can optionally specify different paths for `package.json` and `git-shrinkwrap.json`, e.g.:

```sh
npm-git install -c git-dependencies.json -w git-depencencies-shrinkwrap.json
```

You may want to do this if you find it offensive to put non-standard section in your `package.json`.

Also try `--help` for more options.

### API

You can also use it programmatically. Just require `npm-git-install`. It exposes four methods:

  * `discover (path)`

    Reads list of packages from file at given path (e.g. a package.json) and returns array of `{url, revision}` objects. You can supply this to `reinstall_all` method.

  * `reinstall_all (options, packages)`

    Executes `reinstall` in series for each package in `packages`. Options are also passed to each `reinstall` call.

    This function is curried, so if you provide just `options` argument you will get a new function that takes only one argument - `packages` array.

    Options are the same as for `reinstall`.

    Returns a `Promise`.

  * `reinstall (options, package)`

    Most of the heavy lifting happens here:

    1.  Clones the repo at `package.url`,

    1.  Checks out `package.revision`

    1.  runs `npm install` at cloned repos directory

    1.  installs the package from there.

    Options are:

    * `silent`: Suppress child processes standard output. Boolean. Default is `false`.
    * `verbose`: Print debug messages. Boolean. Default is `false`.

    Returns a `Promise`.

    You probably don't want to use it directly. Just call `reinstall_all` with relevant options.

  * `shrinkwrap (options, packages)`

    The shrinkwrap file will lock each git dependency to the sha specified in the file.

    `shrinkwrap` creates a shrinkwrap file (default: `git-shrinkwrap.json`) in series containing a sha for each package in `packages`, which will be the latest sha in the specified branch from `packages`.

    Options are the same as for `reinstall`.

    Returns nothing.

If you are a [Gulp][] user, then it should be easy enough to integrate it with your gulpfile.

### Why not use `dependencies` and `devDependencies`

I tried and it's hard, because NPM supports [fancy things as Git URLs][URLs]. See `messy-auto-discovery` branch. You are welcome to take it from where I left.

There is also another reason. User may not want to reinstall all Git dependencies this way. For example I use gulp version 4, which is only available from GitHub and it is perfectly fine to install it with standard NPM. I don't want to rebuild it on my machine every time I install it. Now I can leave it in `devDependencies` and only use `npm-git-install` for stuff that needs it.

[URLs]: https://docs.npmjs.com/files/package.json#git-urls-as-dependencies
[3055]: https://github.com/npm/npm/issues/3055
[Gulp]: http://gulpjs.com/
